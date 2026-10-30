// Waypoint additions, 2026-10-28. AGPL-3.0.
import SwiftUI

@MainActor
struct WaypointCellularView: View {
    @StateObject private var flow: WaypointCellularFlow
    @Environment(\.dismiss) private var dismiss
    private let target: WaypointCoordinate

    init(session: WaypointSession, target: WaypointCoordinate) {
        self.target = target
        _flow = StateObject(wrappedValue: WaypointCellularFlow(session: session, target: target,
            prepare: { try await WaypointCellularPreparation.prepare() }))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Start without Wi-Fi", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.headline)
                    Text(target.label).font(.subheadline.monospacedDigit())
                    Text("Experimental on iOS 27.0.1. This establishes a local session while data is briefly off, then checks it again after data returns. Your Mac stays off.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Before you turn data off") {
                    Text("Import your pairing file and prepare developer support during initial setup, while internet is available. Complete a baseline start/restore before trying this mode. Select your destination while map search has internet.")
                    Text("Turn on LocalDevVPN and leave it connected. Disconnect from Wi-Fi for this test.")
                }
                Section("1 · Briefly disable Cellular Data") {
                    Text("Open Control Center, switch Cellular Data OFF, wait about 2 seconds, then return here. Keep LocalDevVPN enabled.")
                    Button("Data is off · connect and apply") { flow.beginAfterUserDisabledData() }
                        .disabled(flow.busy)
                    Text("Waypoint cannot switch Cellular Data itself. If you cancel or see an error, turn your data back on.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("2 · Restore data and check") {
                    if flow.busy { ProgressView(progressLabel) }
                    if let message = flow.message {
                        Text(message).foregroundStyle(flow.phase == .failed ? Color.orange : Color.primary)
                    }
                    Button("Data is back on · verify connection") { flow.verifyAfterUserRestoredData() }
                        .disabled(flow.busy || flow.phase == .instructions)
                    Text("Wait for the location to be accepted before switching data back on. Then keep Wi-Fi OFF, restore Cellular Data, and tap the check above.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if flow.phase == .failed {
                    Section("If the first attempt fails") {
                        Text("Restore Cellular Data first. Check LocalDevVPN and the pairing file, then retry. Some devices may need a brief Airplane Mode toggle instead; if you try that, keep the local VPN enabled and turn Airplane Mode OFF afterward.")
                        Text("A successful check confirms a fresh command, not indefinite background operation. Verify in the target app and test a second location while data stays on.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Cellular start")
            .toolbar {
                Button(flow.busy ? "Cancel" : "Done") { flow.cancel(); dismiss() }
            }
            .interactiveDismissDisabled(flow.busy)
            .onDisappear { flow.cancel() }
        }
    }

    private var progressLabel: String {
        switch flow.phase {
        case .connecting: return "Connecting and preparing developer support…"
        case .applying: return "Waiting for location acknowledgement…"
        case .verifying: return "Sending a fresh location command…"
        default: return "Working…"
        }
    }
}
