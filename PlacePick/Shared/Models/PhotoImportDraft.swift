import Foundation
import MapKit

/// A candidate Photo pulled from the system library during Memory Creation, before any
/// Visit exists. See DATA_MODEL.md §24.8 "Import Is Not Persistence" — this is not a
/// VisitPhoto; nothing here is saved as a Visit until the user confirms Stage 5.
/// PlacePick never copies the user's photo library — only the Photos-library asset
/// identifier is kept; images are always looked up from Photos on demand.
struct PhotoImportCandidate: Identifiable, Equatable {
    let id: String
    let localAssetIdentifier: String
    let capturedAt: Date
    let latitude: Double?
    let longitude: Double?
}

/// One suggested group of Photos likely belonging to the same visit. Temporary — never
/// persisted as-is. See DATA_MODEL.md §15.2 "PhotoImportGroup".
struct PhotoImportGroup: Identifiable {
    enum Status {
        /// No Place chosen yet.
        case unresolved
        /// User confirmed a real Apple Maps result — see MEMORY_CREATION.md Stage 3.
        case resolved(MKMapItem)
        /// User chose not to create a Memory from this group.
        case skipped
    }

    let id: UUID
    var photos: [PhotoImportCandidate]
    var status: Status

    init(id: UUID = UUID(), photos: [PhotoImportCandidate], status: Status = .unresolved) {
        self.id = id
        self.photos = photos
        self.status = status
    }

    var proposedStartTime: Date? { photos.map(\.capturedAt).min() }
    var proposedEndTime: Date? { photos.map(\.capturedAt).max() }

    /// Simple average of available photo coordinates — a rough centroid used only to seed
    /// Apple Maps nearby search. Never becomes canonical Place identity on its own.
    var approximateCoordinate: CLLocationCoordinate2D? {
        let coordinates = photos.compactMap { photo -> CLLocationCoordinate2D? in
            guard let lat = photo.latitude, let lon = photo.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        guard !coordinates.isEmpty else { return nil }
        let avgLat = coordinates.map(\.latitude).reduce(0, +) / Double(coordinates.count)
        let avgLon = coordinates.map(\.longitude).reduce(0, +) / Double(coordinates.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
}

/// The in-memory working state for one Memory Creation session. Never written to
/// persistent storage — see DATA_MODEL.md §15.1 "PhotoImportDraft".
struct PhotoImportDraft {
    var selectedPhotos: [PhotoImportCandidate]
    var proposedGroups: [PhotoImportGroup]
    let createdAt: Date

    init(selectedPhotos: [PhotoImportCandidate] = [], proposedGroups: [PhotoImportGroup] = [], createdAt: Date = .now) {
        self.selectedPhotos = selectedPhotos
        self.proposedGroups = proposedGroups
        self.createdAt = createdAt
    }
}
