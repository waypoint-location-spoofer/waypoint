// Waypoint entry point; original StikDebug bootstrap retained (AGPL-3.0).
import SwiftUI

@main
struct StikDebugApp: App {
    init() { AppBootstrapper.configure() }
    var body: some Scene {
        WindowGroup { WaypointRootView() }
    }
}
