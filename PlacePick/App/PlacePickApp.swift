import SwiftUI
import SwiftData

private enum AppTab: String {
    case map
    case calendar
}

@main
struct PlacePickApp: App {
    @StateObject private var pendingImportCoordinator = PendingImportCoordinator()
    /// Persisted so relaunching the app returns to the tab the user was last on rather
    /// than always resetting to Map — "opening the app should feel like continuing a
    /// conversation."
    @AppStorage("com.sianjin.PlacePick.selectedTab") private var selectedTab = AppTab.map

    /// CloudKit-backed so Places/Memories survive reinstalls and sync across the user's
    /// devices — see DATA_MODEL.md §23 "automatic cloud synchronization when available."
    /// Every model's relationships are Optional and every attribute has a default
    /// specifically to satisfy CloudKit's schema requirements (see each model's comments).
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.sianjin.PlacePick")
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                MapScreen()
                    .tabItem { Label("Map", systemImage: "map") }
                    .tag(AppTab.map)

                CalendarScreen()
                    .tabItem { Label("Calendar", systemImage: "calendar") }
                    .tag(AppTab.calendar)
            }
            .environmentObject(pendingImportCoordinator)
            .onOpenURL { url in
                pendingImportCoordinator.handleOpenURL(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
