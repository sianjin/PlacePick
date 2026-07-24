import Foundation
import SwiftData
import CoreLocation

@MainActor
final class PlaceRepository {
    private let modelContext: ModelContext

    /// §10.3 fallback duplicate signal: "very close coordinates" + "same normalized name
    /// within a small distance." 75m covers GPS/rounding drift between independently
    /// resolved Apple Maps results for the same real-world Place without over-matching.
    private static let nearbyMatchRadiusMeters: CLLocationDistance = 75

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

    /// Fallback duplicate signal when no Apple Maps identifier match exists — see
    /// §10.3 "Duplicate Identity". Matches on a normalized name plus close coordinates,
    /// never on coordinates alone, to avoid conflating unrelated nearby Places.
    func findNearbyMatch(name: String, latitude: Double, longitude: Double) -> Place? {
        let normalizedTarget = Self.normalize(name)
        let targetLocation = CLLocation(latitude: latitude, longitude: longitude)

        return fetchAllActive().first { candidate in
            guard Self.normalize(candidate.name) == normalizedTarget else { return false }
            let candidateLocation = CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)
            return candidateLocation.distance(from: targetLocation) <= Self.nearbyMatchRadiusMeters
        }
    }

    private static func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
