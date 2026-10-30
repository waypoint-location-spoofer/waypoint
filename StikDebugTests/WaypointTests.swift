// Waypoint behavioral tests. Run on a connected iPhone with Xcode.
import Foundation
import Testing
@testable import StikDebug

@MainActor
private final class WaypointFakeBackend: WaypointBackend {
    var commands: [String] = []
    var completions: [@MainActor (Int32) -> Void] = []
    func set(_ coordinate: WaypointCoordinate, completion: @escaping @MainActor (Int32) -> Void) {
        commands.append("set")
        completions.append(completion)
    }
    func clear(completion: @escaping @MainActor (Int32) -> Void) {
        commands.append("clear")
        completions.append(completion)
    }
    func finish(_ code: Int32) { completions.removeFirst()(code) }
}

@MainActor
struct WaypointTests {
    private let target = WaypointCoordinate(latitude: 37.3349, longitude: -122.0090)

    private func withSession(_ body: (WaypointSession, WaypointFakeBackend, UserDefaults) -> Void) {
        let suite = "WaypointTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let backend = WaypointFakeBackend()
        let session = WaypointSession(backend: backend, defaults: defaults,
                                      schedulesRefresh: false, keepAlive: { _ in })
        body(session, backend, defaults)
    }

    @Test func rejectsMalformedAndNonfiniteCoordinates() {
        for value in ["", "1", "1,2,3", "NaN,0", "inf,0", "91,0", "0,-181", "1,"] {
            #expect(WaypointCoordinate.parse(value) == nil)
        }
        #expect(WaypointCoordinate.parse(" -90, 180 ") == WaypointCoordinate(latitude: -90, longitude: 180))
        withSession { session, backend, _ in
            session.start(WaypointCoordinate(latitude: .nan, longitude: 0))
            #expect(backend.commands.isEmpty)
            #expect(session.status == .idle)
        }
    }

    @Test func becomesActiveOnlyAfterAcknowledgement() {
        withSession { session, backend, defaults in
            session.start(target)
            #expect(session.status == .starting)
            #expect(defaults.bool(forKey: "waypoint.mayBeActive"))
            backend.finish(0)
            #expect(session.status == .active)
            #expect(session.lastConfirmedAt != nil)
        }
    }

    @Test func stoppingAnInflightStartCannotReactivateTheSession() {
        withSession { session, backend, defaults in
            session.start(target)
            session.stop()
            #expect(backend.commands == ["set", "clear"])
            backend.finish(0)
            #expect(session.status == .stopping)
            backend.finish(0)
            #expect(session.status == .idle)
            #expect(!defaults.bool(forKey: "waypoint.mayBeActive"))
            session.refresh()
            #expect(backend.commands.count == 2)
        }
    }

    @Test func slowRefreshesDoNotAccumulateAndStopWins() {
        withSession { session, backend, _ in
            session.start(target)
            backend.finish(0)
            for _ in 0..<20 { session.refresh() }
            #expect(backend.commands == ["set", "set"])
            session.stop()
            backend.finish(0)
            #expect(session.status == .stopping)
            backend.finish(0)
            #expect(session.status == .idle)
        }
    }

    @Test func failedStopDoesNotClaimRealLocationWasRestored() {
        withSession { session, backend, defaults in
            session.start(target)
            backend.finish(0)
            session.stop()
            backend.finish(12)
            #expect(session.status == .uncertain)
            #expect(defaults.bool(forKey: "waypoint.mayBeActive"))
            #expect(session.canStop)
            session.stop()
            backend.finish(0)
            #expect(session.status == .idle)
        }
    }

    @Test func relaunchRequiresExplicitRecoveryAndDoesNotReapply() {
        withSession { session, backend, defaults in
            session.start(target)
            backend.finish(0)
            let recoveredBackend = WaypointFakeBackend()
            let recovered = WaypointSession(backend: recoveredBackend, defaults: defaults,
                                             schedulesRefresh: false, keepAlive: { _ in })
            #expect(recovered.status == .uncertain)
            #expect(recovered.coordinate == target)
            #expect(recoveredBackend.commands.isEmpty)
            recovered.stop()
            #expect(recoveredBackend.commands == ["clear"])
            recoveredBackend.finish(0)
            #expect(recovered.status == .idle)
        }
    }

    @Test func refreshFailureStopsRepeatingAndRemainsRecoverable() {
        withSession { session, backend, defaults in
            session.start(target)
            backend.finish(0)
            session.refresh()
            backend.finish(3)
            #expect(session.status == .uncertain)
            #expect(defaults.bool(forKey: "waypoint.mayBeActive"))
            session.refresh()
            #expect(backend.commands.count == 2)
        }
    }

    private func withCellularSession(_ body: (WaypointSession, WaypointFakeBackend, UserDefaults) async -> Void) async {
        let suite = "WaypointCellularTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let backend = WaypointFakeBackend()
        let session = WaypointSession(backend: backend, defaults: defaults,
                                      schedulesRefresh: false, keepAlive: { _ in })
        await body(session, backend, defaults)
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 {
            if condition() { return }
            await Task.yield()
        }
        #expect(condition())
    }

    @Test func cellularVerificationRequiresANewAcknowledgement() async {
        await withCellularSession { session, backend, defaults in
            let flow = WaypointCellularFlow(session: session, target: target, defaults: defaults, prepare: {})
            flow.beginAfterUserDisabledData()
            await waitUntil { backend.commands.count == 1 }
            #expect(flow.phase == .applying)
            #expect(defaults.bool(forKey: WaypointCellularFlow.reminderKey))
            backend.finish(0)
            #expect(flow.phase == .restoreData)
            flow.verifyAfterUserRestoredData()
            await waitUntil { backend.commands.count == 2 }
            #expect(flow.phase == .verifying)
            #expect(!defaults.bool(forKey: WaypointCellularFlow.reminderKey))
            backend.finish(0)
            #expect(flow.phase == .confirmed)
            flow.cancel()
            #expect(session.status == .active)
            #expect(backend.commands == ["set", "set"])
        }
    }

    @Test func cellularPreparationFailureNeverSendsCoordinates() async {
        await withCellularSession { session, backend, defaults in
            let flow = WaypointCellularFlow(session: session, target: target, defaults: defaults,
                                            prepare: { throw WaypointCellularError.supportFilesMissing })
            flow.beginAfterUserDisabledData()
            await waitUntil { flow.phase == .failed }
            #expect(backend.commands.isEmpty)
            #expect(defaults.bool(forKey: WaypointCellularFlow.reminderKey))
        }
    }

    @Test func cellularPostRestoreFailureIsNotReportedAsSuccess() async {
        await withCellularSession { session, backend, defaults in
            let flow = WaypointCellularFlow(session: session, target: target, defaults: defaults, prepare: {})
            flow.beginAfterUserDisabledData()
            await waitUntil { backend.commands.count == 1 }
            backend.finish(0)
            flow.verifyAfterUserRestoredData()
            await waitUntil { backend.commands.count == 2 }
            backend.finish(3)
            #expect(flow.phase == .failed)
            #expect(session.status == .uncertain)
        }
    }

    @Test func cancellingCellularApplyQueuesRestoreAndKeepsDataReminder() async {
        await withCellularSession { session, backend, defaults in
            let flow = WaypointCellularFlow(session: session, target: target, defaults: defaults, prepare: {})
            flow.beginAfterUserDisabledData()
            await waitUntil { backend.commands.count == 1 }
            flow.cancel()
            #expect(backend.commands == ["set", "clear"])
            backend.finish(0)
            #expect(flow.phase == .failed)
            backend.finish(0)
            #expect(session.status == .idle)
            #expect(defaults.bool(forKey: WaypointCellularFlow.reminderKey))
        }
    }

    @Test func cancellingCellularPreparationCannotApplyLater() async {
        await withCellularSession { session, backend, defaults in
            var waiting: CheckedContinuation<Void, Never>?
            let flow = WaypointCellularFlow(session: session, target: target, defaults: defaults, prepare: {
                await withCheckedContinuation { waiting = $0 }
            })
            flow.beginAfterUserDisabledData()
            await waitUntil { waiting != nil }
            flow.cancel()
            waiting?.resume()
            for _ in 0..<20 { await Task.yield() }
            #expect(backend.commands.isEmpty)
            #expect(flow.phase == .failed)
        }
    }
}
