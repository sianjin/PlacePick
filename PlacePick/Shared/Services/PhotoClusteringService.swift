import Foundation
import CoreLocation

/// Groups Photos into proposed Visits using time gaps as the primary signal, per
/// MEMORY_CREATION.md Stage 2 and DATA_MODEL.md §12.2. Grouping is only a proposal — the
/// user may merge, split, move, or remove before anything is saved (§12.3).
enum PhotoClusteringService {
    /// Photos more than this far apart in time start a new group by default.
    private static let timeGapThreshold: TimeInterval = 90 * 60 // 90 minutes

    /// Within the time-gap window, photos more than this far apart also split into a new
    /// group — handles same-afternoon photos taken at two different, distant Places.
    private static let distanceThresholdMeters: CLLocationDistance = 500

    static func proposeGroups(from photos: [PhotoImportCandidate]) -> [PhotoImportGroup] {
        guard !photos.isEmpty else { return [] }

        let sorted = photos.sorted { $0.capturedAt < $1.capturedAt }
        var groups: [[PhotoImportCandidate]] = []
        var currentGroup: [PhotoImportCandidate] = [sorted[0]]

        for photo in sorted.dropFirst() {
            let previous = currentGroup.last!
            let timeGap = photo.capturedAt.timeIntervalSince(previous.capturedAt)
            let distance = distanceMeters(previous, photo)

            let startsNewGroup = timeGap > timeGapThreshold
                || (distance.map { $0 > distanceThresholdMeters } ?? false)

            if startsNewGroup {
                groups.append(currentGroup)
                currentGroup = [photo]
            } else {
                currentGroup.append(photo)
            }
        }
        groups.append(currentGroup)

        return groups.map { PhotoImportGroup(photos: $0) }
    }

    private static func distanceMeters(_ a: PhotoImportCandidate, _ b: PhotoImportCandidate) -> CLLocationDistance? {
        guard let aLat = a.latitude, let aLon = a.longitude,
              let bLat = b.latitude, let bLon = b.longitude
        else { return nil }
        let locationA = CLLocation(latitude: aLat, longitude: aLon)
        let locationB = CLLocation(latitude: bLat, longitude: bLon)
        return locationA.distance(from: locationB)
    }
}
