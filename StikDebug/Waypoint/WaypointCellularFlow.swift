// Waypoint cellular bootstrap experiment, 2026-10-28. AGPL-3.0.
import Foundation
import Combine

enum WaypointCellularError: LocalizedError {
    case supportFilesMissing
    case mountTimeout
    var errorDescription: String? {
        switch self {
        case .supportFilesMissing:
            return "Download developer support in Setup while internet is available, then retry Cellular start."
        case .mountTimeout:
            return "Developer support did not become ready. Turn Cellular Data back on and check Setup before retrying."
        }
    }
}

@MainActor
enum WaypointCellularPreparation {
    static func prepare() async throws {
        // Never start a download after asking the user to take data offline.
        guard DeveloperDiskImageService.filesAreReady else { throw WaypointCellularError.supportFilesMissing }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            TunnelManager.shared.start(showErrorUI: false) { result in
                switch result {
                case .success: continuation.resume()
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
        // The connection manager starts the existing, synchronized mount operation.
        // A later set-location acknowledgement is the final success criterion.
        for _ in 0..<160 {
            try Task.checkCancellation()
            if MountingProgress.shared.coolisMounted { return }
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        throw WaypointCellularError.mountTimeout
    }
}

@MainActor
final class WaypointCellularFlow: ObservableObject {
    enum Phase: Equatable {
        case instructions, connecting, applying, restoreData, verifying, confirmed, failed
    }
    @Published private(set) var phase: Phase = .instructions
    @Published private(set) var message: String?
    private let session: WaypointSession
    private let target: WaypointCoordinate
    private let prepare: @MainActor () async throws -> Void
    private let defaults: UserDefaults
    private var task: Task<Void, Never>?
    private var generation = 0

    static let reminderKey = "waypoint.restoreCellularData"
    var busy: Bool { phase == .connecting || phase == .applying || phase == .verifying }

    init(session: WaypointSession, target: WaypointCoordinate, defaults: UserDefaults = .standard,
         prepare: @escaping @MainActor () async throws -> Void) {
        self.session = session
        self.target = target
        self.defaults = defaults
        self.prepare = prepare
    }

    func beginAfterUserDisabledData() {
        guard !busy, target.isValid else { return }
        defaults.set(true, forKey: Self.reminderKey)
        guard session.canStart else {
            phase = .failed
            message = "A location command is still pending. Turn Cellular Data back on, wait for it to finish, then retry."
            return
        }
        generation += 1
        let token = generation
        phase = .connecting
        message = nil
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.prepare()
                guard !Task.isCancelled, self.generation == token else { return }
                self.phase = .applying
                self.session.start(self.target) { [weak self] success in
                    guard let self, self.generation == token else { return }
                    self.phase = success ? .restoreData : .failed
                    self.message = success
                        ? "The iPhone accepted the location. Turn Cellular Data back ON, keep LocalDevVPN connected, and return here."
                        : "Location was not confirmed. Turn Cellular Data back ON. \(self.session.error ?? "Retry the connection when ready.")"
                }
            } catch {
                guard !Task.isCancelled, self.generation == token else { return }
                self.phase = .failed
                self.message = "Turn Cellular Data back ON. \(error.localizedDescription)"
            }
        }
    }

    func verifyAfterUserRestoredData() {
        guard !busy, phase == .restoreData || phase == .failed || phase == .confirmed else { return }
        // This records the user's explicit confirmation, not a guessed radio state.
        defaults.set(false, forKey: Self.reminderKey)
        generation += 1
        let token = generation
        phase = .verifying
        message = nil
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            // Let an already-running refresh finish, without building a command backlog.
            for _ in 0..<40 {
                guard !Task.isCancelled, self.generation == token else { return }
                if self.session.status != .active {
                    self.phase = .failed
                    self.message = "The session is no longer active. Repeat Cellular start; no location was confirmed after restoring data."
                    return
                }
                if self.session.verifyConnection(completion: { [weak self] success in
                    guard let self, self.generation == token else { return }
                    self.phase = success ? .confirmed : .failed
                    self.message = success
                        ? "A fresh location command succeeded after you restored data. Keep Wi-Fi off, check the location in Maps, then try another pin in Waypoint."
                        : "The location command failed after restoring data. Repeat the brief data-off connection step. Cellular operation on this phone is not confirmed."
                }) { return }
                do { try await Task.sleep(nanoseconds: 250_000_000) }
                catch { return }
            }
            self.phase = .failed
            self.message = "A previous location command is still pending. Wait for it to finish, then retry the check."
        }
    }

    func cancel() {
        generation += 1
        task?.cancel()
        task = nil
        if phase == .applying { session.stop() }
        // Do not close a successfully established session merely because the sheet is dismissed.
        if busy {
            phase = .failed
            message = "Cancelled. If you turned Cellular Data off, turn it back on. Check Location for the session's current status."
        }
    }
}
