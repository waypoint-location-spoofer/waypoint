// Waypoint additions, 2026-10-28. Licensed under AGPL-3.0.
import SwiftUI
import MapKit
import UniformTypeIdentifiers

private struct WaypointPlace: Codable, Identifiable {
    var id = UUID()
    let name: String
    let coordinate: WaypointCoordinate
}

@MainActor
struct WaypointRootView: View {
    @StateObject private var session = WaypointSession(backend: WaypointDeviceBackend())
    @State private var tab = 0
    @AppStorage(WaypointCellularFlow.reminderKey) private var restoreDataReminder = false
    @Environment(\.scenePhase) private var phase

    var body: some View {
        TabView(selection: $tab) {
            WaypointMapView(session: session, openSetup: { tab = 1 })
                .tabItem { Label("Location", systemImage: "map") }.tag(0)
            WaypointSetupView(session: session)
                .tabItem { Label("Setup", systemImage: "link") }.tag(1)
        }
        .tint(.teal)
        .safeAreaInset(edge: .top) {
            if restoreDataReminder {
                HStack {
                    Text("If you turned Cellular Data off, turn it back on after connecting or cancelling.").font(.caption)
                    Button("It's back on") { restoreDataReminder = false }.font(.caption.bold())
                }.padding(10).background(Color.orange.opacity(0.16))
            }
        }
        .onChange(of: phase) { _, value in
            if value == .active { session.checkAfterForeground() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPairingFilePicker"))) { _ in
            tab = 1
        }
    }
}

@MainActor
private struct WaypointMapView: View {
    @ObservedObject var session: WaypointSession
    @ObservedObject private var tunnel = TunnelManager.shared
    @ObservedObject private var mounting = MountingProgress.shared
    let openSetup: () -> Void
    @State private var camera: MapCameraPosition = .automatic
    @State private var selected: WaypointCoordinate?
    @State private var selectedName = "Selected location"
    @State private var search = ""
    @State private var results: [MKMapItem] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var showResults = false
    @State private var showCoordinates = false
    @State private var coordinateText = ""
    @State private var showSave = false
    @State private var placeName = ""
    @State private var showPlaces = false
    @State private var showCellular = false
    @AppStorage("waypoint.places") private var placesData = Data()

    private var places: [WaypointPlace] {
        (try? JSONDecoder().decode([WaypointPlace].self, from: placesData)) ?? []
    }
    private var ready: Bool { session.status == .active || (tunnel.isConnected && mounting.coolisMounted) }

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $camera) {
                    if let selected {
                        Marker(selectedName, coordinate: selected.location).tint(.teal)
                    }
                    if session.status == .active, let current = session.coordinate {
                        Annotation("Applied location", coordinate: current.location) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .padding(8).foregroundStyle(.white).background(.teal, in: Circle())
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .onTapGesture { point in
                    if let coordinate = proxy.convert(point, from: .local) {
                        selected = WaypointCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        selectedName = "Dropped pin"
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) { searchBar }
            .safeAreaInset(edge: .bottom, spacing: 0) { controls }
            .navigationTitle("Waypoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showPlaces = true } label: { Image(systemName: "bookmark") }
                        .accessibilityLabel("Saved places")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showCoordinates = true } label: { Image(systemName: "number") }
                        .accessibilityLabel("Enter coordinates")
                }
            }
            .sheet(isPresented: $showResults) { searchResults }
            .sheet(isPresented: $showPlaces) { savedPlaces }
            .sheet(isPresented: $showCellular) {
                if let selected { WaypointCellularView(session: session, target: selected) }
            }
            .alert("Enter coordinates", isPresented: $showCoordinates) {
                TextField("Latitude, longitude", text: $coordinateText)
                    .keyboardType(.numbersAndPunctuation)
                Button("Select") {
                    if let value = WaypointCoordinate.parse(coordinateText) { select(value, name: "Coordinates") }
                    else { searchError = "Use latitude, longitude; for example 37.3349, -122.0090." }
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("Latitude: −90 to 90. Longitude: −180 to 180.") }
            .alert("Save place", isPresented: $showSave) {
                TextField("Name", text: $placeName)
                Button("Save") {
                    guard let selected else { return }
                    let name = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
                    var updated = places
                    updated.append(WaypointPlace(name: name.isEmpty ? selectedName : name, coordinate: selected))
                    placesData = (try? JSONEncoder().encode(updated)) ?? placesData
                }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear {
                if selected == nil, let coordinate = session.coordinate { select(coordinate, name: "Last location") }
            }
            .onDisappear { searchTask?.cancel(); isSearching = false }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search a city, address, or place", text: $search)
                .submitLabel(.search).onSubmit { findPlaces() }
                .autocorrectionDisabled()
            if isSearching { ProgressView() }
            else { Button("Go") { findPlaces() }.disabled(search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }
        .padding(12).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal).padding(.vertical, 8)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: session.status == .active ? "location.fill" : "location.circle")
                    .foregroundStyle(session.status == .active ? Color.teal : Color.secondary)
                Text(session.status.rawValue).font(.headline)
                Spacer()
                if session.status == .starting || session.status == .stopping { ProgressView() }
            }
            if let selected {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedName).font(.subheadline).lineLimit(1)
                        Text(selected.label).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { placeName = selectedName; showSave = true } label: { Image(systemName: "bookmark.badge.plus") }
                        .accessibilityLabel("Save selected place")
                }
            } else { Text("Tap the map or search for a place.").font(.subheadline).foregroundStyle(.secondary) }

            if let error = session.error ?? searchError {
                Text(error).font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
            }
            if !ready {
                Button(action: openSetup) { Label("Connect your iPhone in Setup", systemImage: "link") }
                    .font(.subheadline)
            }
            HStack(spacing: 10) {
                Button {
                    if let selected { searchError = nil; session.start(selected) }
                } label: {
                    Text(session.status == .active ? "Apply new location" : "Start simulation")
                        .frame(maxWidth: .infinity).padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected == nil || !ready || !session.canStart)
            }
            if session.canStop {
                Button("Restore real location") { session.stop() }
                    .buttonStyle(.bordered).frame(maxWidth: .infinity)
            }
            Button { showCellular = true } label: {
                Label("Cellular start…", systemImage: "antenna.radiowaves.left.and.right")
            }
            .disabled(selected == nil || session.status == .starting || session.status == .stopping)
            Text("Keep LocalDevVPN on. No Wi-Fi? Try Cellular start.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 10).padding(.bottom, 8)
    }

    private var searchResults: some View {
        NavigationStack {
            List {
                if results.isEmpty { Text("No places found. Try a more specific search.") }
                ForEach(results.indices, id: \.self) { index in
                    let item = results[index]
                    Button {
                        select(WaypointCoordinate(latitude: item.placemark.coordinate.latitude,
                                                  longitude: item.placemark.coordinate.longitude),
                               name: item.name ?? "Search result")
                        showResults = false
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Place")
                            Text(item.placemark.title ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Search results")
            .toolbar { Button("Done") { showResults = false } }
        }
    }

    private var savedPlaces: some View {
        NavigationStack {
            List {
                if places.isEmpty { Text("Choose a pin, then tap the bookmark to save it.").foregroundStyle(.secondary) }
                ForEach(places) { place in
                    Button { select(place.coordinate, name: place.name); showPlaces = false } label: {
                        VStack(alignment: .leading) {
                            Text(place.name)
                            Text(place.coordinate.label).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indices in
                    var updated = places
                    updated.remove(atOffsets: indices)
                    placesData = (try? JSONEncoder().encode(updated)) ?? placesData
                }
            }
            .navigationTitle("Saved places")
            .toolbar { Button("Done") { showPlaces = false } }
        }
    }

    private func select(_ coordinate: WaypointCoordinate, name: String) {
        selected = coordinate
        selectedName = name
        searchError = nil
        camera = .region(MKCoordinateRegion(center: coordinate.location,
                                            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)))
    }

    private func findPlaces() {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        searchTask?.cancel()
        isSearching = true
        searchError = nil
        searchTask = Task { @MainActor in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            do {
                let response = try await MKLocalSearch(request: request).start()
                guard !Task.isCancelled else { return }
                results = response.mapItems
                isSearching = false
                showResults = true
            } catch {
                guard !Task.isCancelled else { return }
                isSearching = false
                searchError = "Search unavailable. Check your internet connection or enter coordinates."
            }
        }
    }
}

@MainActor
private struct WaypointSetupView: View {
    @ObservedObject var session: WaypointSession
    @ObservedObject private var tunnel = TunnelManager.shared
    @ObservedObject private var mounting = MountingProgress.shared
    @State private var hasPairing = false
    @State private var importFile = false
    @State private var preparing = false
    @State private var preparationMessage: String?
    @State private var showAdvanced = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Waypoint", systemImage: "location.circle.fill").font(.title2.bold())
                    Text("Choose your location from your iPhone. Use your Mac for installation, pairing, and manual signing renewal.")
                        .foregroundStyle(.secondary)
                }
                Section("1 · Pair this iPhone") {
                    Label(hasPairing ? "Pairing file imported" : "Pairing file needed",
                          systemImage: hasPairing ? "checkmark.circle.fill" : "doc.badge.plus")
                    Button("Import pairing file") { importFile = true }
                        .disabled(session.status == .active || session.status == .starting || session.status == .stopping)
                    Link("Create a remote pairing file on your Mac", destination: URL(string: "https://github.com/jkcoxson/idevice_pair#usage")!)
                    Text("In idevice_pair, select Remote pairing and Save to file. Send that file to this iPhone, then import it here.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Enable Developer Mode in Settings → Privacy & Security. Keep the pairing file private; it grants developer access to this phone.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("2 · Turn on the local connection") {
                    Link("Install / open LocalDevVPN", destination: URL(string: "https://apps.apple.com/us/app/localdevvpn/id6755608044")!)
                    Text("Enable LocalDevVPN, then return here. On Wi-Fi, use Connect and prepare. Without Wi-Fi, download support first, then use Cellular start from the map. Your Mac can be off.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button(preparing ? "Preparing…" : "Connect and prepare") { prepare() }
                        .disabled(!hasPairing || preparing || session.status == .starting || session.status == .stopping)
                    Button("Download support for cellular use") { prepare(connect: false) }
                        .disabled(preparing || session.status == .starting || session.status == .stopping)
                    Label(tunnel.isConnected ? "Developer connection ready" : "Developer connection not ready",
                          systemImage: tunnel.isConnected ? "checkmark.circle" : "circle")
                    Label(mounting.coolisMounted && tunnel.isConnected ? "Location service prepared" : "Location service not ready",
                          systemImage: mounting.coolisMounted && tunnel.isConnected ? "checkmark.circle" : "circle")
                    if preparing || mounting.mountingThread != nil { ProgressView() }
                    if let preparationMessage { Text(preparationMessage).font(.caption) }
                }
                Section("3 · Use and renew") {
                    Text("Go to Location, choose a pin, and tap Start simulation. You can disconnect and switch off your Mac once setup succeeds.")
                    Text("Before your seven-day signing expires, reconnect to Xcode and install again using the same bundle ID. Keep the app installed to preserve saved places.")
                    Text("iOS may suspend the app. Background support is included, but locked-screen behavior and compatibility with iOS 27.0.1 still need testing on your phone.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Troubleshooting and credits") {
                    Button("Connection and background settings") { showAdvanced = true }
                        .disabled(session.status == .active || session.status == .starting || session.status == .stopping)
                    Link("StikDebug · open-source foundation", destination: URL(string: "https://github.com/StikDebug/StikDebug")!)
                    Text("Waypoint 0.2 · AGPL-3.0. Includes StikDebug and idevice. No subscription or paid service is added by Waypoint.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Setup")
            .onAppear { hasPairing = FileManager.default.fileExists(atPath: PairingFileStore.prepareURL().path) }
            .sheet(isPresented: $showAdvanced) { SettingsView() }
            .fileImporter(isPresented: $importFile, allowedContentTypes: PairingFileStore.supportedContentTypes) { result in
                do {
                    let url = try result.get()
                    try PairingFileStore.importFromPicker(url)
                    hasPairing = true
                    preparationMessage = "Pairing imported. Enable LocalDevVPN, then connect."
                } catch { preparationMessage = "Import failed: \(error.localizedDescription)" }
            }
        }
    }

    private func prepare(connect: Bool = true) {
        preparing = true
        preparationMessage = "Downloading any missing developer support files. The first download can take several minutes."
        Task { @MainActor in
            do {
                if !DeveloperDiskImageService.filesAreReady {
                    try await DeveloperDiskImageService.shared.downloadMissingFiles()
                }
                if connect {
                    startTunnelInBackground()
                    preparationMessage = "Connecting. Wait for both indicators to become ready. If an error appears, check LocalDevVPN and your pairing file."
                } else {
                    preparationMessage = "Support files are saved. Choose a pin on the map, then open Cellular start. No Wi-Fi connection is required to download these files over mobile data."
                }
            } catch { preparationMessage = "Preparation failed: \(error.localizedDescription)" }
            preparing = false
        }
    }
}
