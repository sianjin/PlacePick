import SwiftUI
import SwiftData

@main
struct PlacePickApp: App {
    @StateObject private var pendingImportCoordinator = PendingImportCoordinator()

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
            TabView {
                MapScreen()
                    .tabItem { Label("Map", systemImage: "map") }

                CalendarScreen()
                    .tabItem { Label("Calendar", systemImage: "calendar") }
            }
            .environmentObject(pendingImportCoordinator)
            .onOpenURL { url in
                pendingImportCoordinator.handleOpenURL(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
