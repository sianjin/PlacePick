import Foundation
import MapKit

struct PlaceRelationshipDraft {
    var collection: PlaceCollection
    var isFavorite: Bool = false
    var emotion: PlaceEmotion? = nil
    var note: String = ""
    var memoryPhotoID: String? = nil
}

enum PlaceCreationResult {
    case created(Place)
    case existing(Place)
}

enum PlaceReplacementResult {
    case replaced(Place)
    case existingTarget(Place)
}

enum PlaceCreationError: Error {
    case unresolvedIdentity
}

@MainActor
final class PlaceCreationService {
    private let repository: PlaceRepository

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func createPlace(
        from mapItem: MKMapItem,
        relationship: PlaceRelationshipDraft
    ) throws -> PlaceCreationResult {
        let identifier = try canonicalIdentifier(for: mapItem)

        if let existing = repository.findByAppleMapIdentifier(identifier) {
            return .existing(existing)
        }

        let place = Place(
            appleMapIdentifier: identifier,
            name: mapItem.name ?? "Unnamed Place",
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude,
            collection: relationship.collection,
            isFavorite: relationship.isFavorite,
            emotion: relationship.emotion,
            note: relationship.note,
            memoryPhotoID: relationship.memoryPhotoID
        )
        repository.insert(place)
        return .created(place)
    }

    /// Received Places already carry a verified Apple Maps identity from the sender —
    /// no MapKit re-resolution needed. See MVP.md §10.1/§10.2: dedup by identifier first,
    /// falling back to name+coordinate proximity per §10.3. The new local relationship
    /// always starts blank; the sender's personal memory is never copied.
    func createPlace(
        from identity: SharedPlaceIdentity,
        collection: PlaceCollection
    ) -> PlaceCreationResult {
        if let existing = findExisting(matching: identity) {
            return .existing(existing)
        }

        let place = Place(
            appleMapIdentifier: identity.appleMapIdentifier,
            name: identity.name,
            latitude: identity.latitude,
            longitude: identity.longitude,
            collection: collection
        )
        repository.insert(place)
        return .created(place)
    }

    /// §10.3 Duplicate Identity: Apple Maps identifier first, falling back to a very close
    /// coordinate with a matching normalized name.
    func findExisting(matching identity: SharedPlaceIdentity) -> Place? {
        if let identifier = identity.appleMapIdentifier,
           let existing = repository.findByAppleMapIdentifier(identifier) {
            return existing
        }
        return repository.findNearbyMatch(name: identity.name, latitude: identity.latitude, longitude: identity.longitude)
    }

    func replaceIdentity(
        for place: Place,
        with mapItem: MKMapItem
    ) throws -> PlaceReplacementResult {
        let identifier = try canonicalIdentifier(for: mapItem)

        if let existing = repository.findByAppleMapIdentifier(identifier), existing.id != place.id {
            return .existingTarget(existing)
        }

        place.appleMapIdentifier = identifier
        place.name = mapItem.name ?? place.name
        place.latitude = mapItem.placemark.coordinate.latitude
        place.longitude = mapItem.placemark.coordinate.longitude
        place.modifiedAt = .now
        repository.save()

        return .replaced(place)
    }

    /// Prefers MKMapItem's stable identifier (iOS 18+). Older OS versions do not expose one,
    /// so this falls back to a deterministic composite of name + rounded coordinate. This must
    /// never be invented from free text — only from a resolved MKMapItem.
    private func canonicalIdentifier(for mapItem: MKMapItem) throws -> String {
        guard let name = mapItem.name, !name.isEmpty else {
            throw PlaceCreationError.unresolvedIdentity
        }
        let coordinate = mapItem.placemark.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            throw PlaceCreationError.unresolvedIdentity
        }

        if #available(iOS 18.0, *), let identifier = mapItem.identifier {
            return identifier.rawValue
        }

        let lat = (coordinate.latitude * 1e5).rounded() / 1e5
        let lon = (coordinate.longitude * 1e5).rounded() / 1e5
        return "\(name)|\(lat)|\(lon)"
    }
}
