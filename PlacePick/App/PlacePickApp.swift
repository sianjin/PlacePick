import SwiftUI
import SwiftData

@main
struct PlacePickApp: App {
    @StateObject private var pendingImportCoordinator = PendingImportCoordinator()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
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
