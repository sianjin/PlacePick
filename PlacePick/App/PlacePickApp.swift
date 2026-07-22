import SwiftUI
import SwiftData

@main
struct PlacePickApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Place.self, PlaceCollection.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MapScreen()
        }
        .modelContainer(sharedModelContainer)
    }
}
