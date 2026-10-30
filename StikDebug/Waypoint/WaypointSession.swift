// Waypoint additions, 2026-10-28. Licensed under AGPL-3.0.
import Foundation
import Combine
import CoreLocation

struct WaypointCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    var isValid: Bool {
        latitude.isFinite && longitude.isFinite &&
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    var label: String { String(format: "%.6f, %.6f", latitude, longitude) }

    static func parse(_ text: String) -> Self? {
        let parts = text.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        let result = Self(latitude: lat, longitude: lon)
        return result.isValid ? result : nil
    }
}

@MainActor
protocol WaypointBackend {
    // Enqueue synchronously; deliver completion on the main actor.
    func set(_ coordinate: WaypointCoordinate, completion: @escaping @MainActor (Int32) -> Void)
    func clear(completion: @escaping @MainActor (Int32) -> Void)
}

@MainActor
final class WaypointDeviceBackend: WaypointBackend {
    func set(_ coordinate: WaypointCoordinate, completion: @escaping @MainActor (Int32) -> Void) {
        let ip = DeviceConnectionContext.targetIPAddress
        let path = PairingFileStore.prepareURL().path
        LocationSimulationCommandQueue.shared.async {
            let code = simulate_location(ip, coordinate.latitude, coordinate.longitude, path)
            DispatchQueue.main.async { completion(code) }
        }
    }

    func clear(completion: @escaping @MainActor (Int32) -> Void) {
        let ip = DeviceConnectionContext.targetIPAddress
        let path = PairingFileStore.prepareURL().path
        LocationSimulationCommandQueue.shared.async {
            let code = waypoint_clear_location(ip, path)
            DispatchQueue.main.async { completion(code) }
        }
    }
}

@MainActor
final class WaypointSession: ObservableObject {
    enum Status: String {
        case idle = "Ready to choose a location"
        case starting = "Applying location…"
        case active = "Simulation running"
        case stopping = "Restoring location…"
        case uncertain = "Location needs checking"
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var coordinate: WaypointCoordinate?
    @Published private(set) var error: String?
    @Published private(set) var lastConfirmedAt: Date?
    private let backend: WaypointBackend
    private let defaults: UserDefaults
    private let keepAlive: (WaypointCoordinate?) -> Void
    private var timer: Timer?
    private var commandPending = false
    private var generation = 0
    private let schedulesRefresh: Bool

    var canStart: Bool { !commandPending && status != .stopping }
    var canStop: Bool { status != .idle && status != .stopping }

    init(backend: WaypointBackend, defaults: UserDefaults = .standard,
         schedulesRefresh: Bool = true,
         keepAlive: @escaping (WaypointCoordinate?) -> Void = { coordinate in
             if let coordinate { LocationSimulationSession.shared.start(at: coordinate.location) }
             else { LocationSimulationSession.shared.stop() }
         }) {
        self.backend = backend
        self.defaults = defaults
        self.schedulesRefresh = schedulesRefresh
        self.keepAlive = keepAlive
        if let data = defaults.data(forKey: "waypoint.lastCoordinate"),
           let saved = try? JSONDecoder().decode(WaypointCoordinate.self, from: data), saved.isValid {
            coordinate = saved
        }
        status = defaults.bool(forKey: "waypoint.mayBeActive") ? .uncertain : .idle
        if status == .uncertain {
            error = "The previous session ended without a confirmed stop. Reconnect, then tap Restore real location."
        }
    }

    func start(_ target: WaypointCoordinate, completion: ((Bool) -> Void)? = nil) {
        guard canStart else { completion?(false); return }
        guard target.isValid else { error = "Enter valid latitude and longitude."; completion?(false); return }
        timer?.invalidate()
        generation += 1
        let token = generation
        commandPending = true
        status = .starting
        error = nil
        coordinate = target
        defaults.set(try? JSONEncoder().encode(target), forKey: "waypoint.lastCoordinate")
        // A process termination during the request must never imply GPS was restored.
        defaults.set(true, forKey: "waypoint.mayBeActive")
        keepAlive(target)
        backend.set(target) { [weak self] code in
            guard let self, self.generation == token else { completion?(false); return }
            self.commandPending = false
            if code == 0 {
                self.status = .active
                self.lastConfirmedAt = Date()
                self.scheduleRefresh()
            } else { self.fail(code, operation: "Set location") }
            completion?(code == 0)
        }
    }

    func stop() {
        guard canStop else { return }
        timer?.invalidate()
        timer = nil
        generation += 1
        let token = generation
        status = .stopping
        error = nil
        commandPending = true
        // The backend's serial queue puts clear AFTER any in-flight set.
        backend.clear { [weak self] code in
            guard let self, self.generation == token else { return }
            self.commandPending = false
            if code == 0 {
                self.status = .idle
                self.lastConfirmedAt = nil
                self.defaults.set(false, forKey: "waypoint.mayBeActive")
                self.keepAlive(nil)
            } else { self.fail(code, operation: "Restore location") }
        }
    }

    func refresh() {
        _ = verifyConnection { _ in }
    }

    // Returns false when another command is in flight; no cached success is accepted.
    @discardableResult
    func verifyConnection(completion: @escaping (Bool) -> Void) -> Bool {
        guard status == .active, !commandPending, let coordinate else { return false }
        commandPending = true
        let token = generation
        backend.set(coordinate) { [weak self] code in
            guard let self, self.generation == token else { completion(false); return }
            self.commandPending = false
            if code == 0 { self.lastConfirmedAt = Date() }
            else { self.fail(code, operation: "Keep location active") }
            completion(code == 0)
        }
        return true
    }

    func checkAfterForeground() {
        guard status == .active else { return }
        // An old successful command is not proof that the phone stayed spoofed while suspended.
        if let lastConfirmedAt, Date().timeIntervalSince(lastConfirmedAt) > 15 {
            timer?.invalidate()
            generation += 1
            commandPending = false
            status = .uncertain
            error = "The app was suspended or its connection stalled. Check the target app, then reapply or restore the location."
        } else { refresh() }
    }

    private func scheduleRefresh() {
        guard schedulesRefresh else { return }
        timer?.invalidate()
        let timer = Timer(timeInterval: 4, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func fail(_ code: Int32, operation: String) {
        timer?.invalidate()
        timer = nil
        status = .uncertain
        keepAlive(nil)
        error = "\(operation) failed (\(code)). Keep LocalDevVPN on, reconnect in Setup, and retry. GPS restoration is not confirmed."
    }
}
