import Foundation
import SwiftData

@MainActor
final class PlaceRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllActive() -> [Place] {
        let descriptor = FetchDescriptor<Place>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func findByAppleMapIdentifier(_ identifier: String) -> Place? {
        let descriptor = FetchDescriptor<Place>(
            predicate: #Predicate { $0.appleMapIdentifier == identifier && $0.deletedAt == nil }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }

    func insert(_ place: Place) {
        modelContext.insert(place)
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
    }

    func softDelete(_ place: Place) {
        place.deletedAt = .now
        place.modifiedAt = .now
        try? modelContext.save()
    }

    func undoDelete(_ place: Place) {
        place.deletedAt = nil
        place.modifiedAt = .now
        try? modelContext.save()
    }
}
