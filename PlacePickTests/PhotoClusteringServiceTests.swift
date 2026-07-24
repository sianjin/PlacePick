import Testing
import Foundation
@testable import PlacePick

struct PhotoClusteringServiceTests {
    private func photo(
        id: String = UUID().uuidString,
        minutesFromEpoch: Double,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> PhotoImportCandidate {
        PhotoImportCandidate(
            id: id,
            localAssetIdentifier: id,
            capturedAt: Date(timeIntervalSince1970: minutesFromEpoch * 60),
            latitude: latitude,
            longitude: longitude
        )
    }

    @Test func emptyInputProducesNoGroups() {
        #expect(PhotoClusteringService.proposeGroups(from: []).isEmpty)
    }

    @Test func singlePhotoProducesOneGroup() {
        let groups = PhotoClusteringService.proposeGroups(from: [photo(minutesFromEpoch: 0)])

        #expect(groups.count == 1)
        #expect(groups.first?.photos.count == 1)
    }

    @Test func photosWithinTimeWindowGroupTogether() {
        let photos = [
            photo(minutesFromEpoch: 0),
            photo(minutesFromEpoch: 10),
            photo(minutesFromEpoch: 25)
        ]

        let groups = PhotoClusteringService.proposeGroups(from: photos)

        #expect(groups.count == 1)
        #expect(groups.first?.photos.count == 3)
    }

    @Test func photosSeparatedByLargeTimeGapSplitIntoGroups() {
        let photos = [
            photo(minutesFromEpoch: 0),
            photo(minutesFromEpoch: 20),
            photo(minutesFromEpoch: 200), // > 90 min gap from previous
            photo(minutesFromEpoch: 210)
        ]

        let groups = PhotoClusteringService.proposeGroups(from: photos)

        #expect(groups.count == 2)
        #expect(groups[0].photos.count == 2)
        #expect(groups[1].photos.count == 2)
    }

    @Test func matchesExampleFromMemoryCreationSpec() {
        // MEMORY_CREATION.md Stage 2 example: two groups, 9:12–9:40 and 11:20–11:45.
        let photos = [
            photo(minutesFromEpoch: 9 * 60 + 12),
            photo(minutesFromEpoch: 9 * 60 + 25),
            photo(minutesFromEpoch: 9 * 60 + 40),
            photo(minutesFromEpoch: 11 * 60 + 20),
            photo(minutesFromEpoch: 11 * 60 + 45)
        ]

        let groups = PhotoClusteringService.proposeGroups(from: photos)

        #expect(groups.count == 2)
        #expect(groups[0].photos.count == 3)
        #expect(groups[1].photos.count == 2)
    }

    @Test func photosCloseInTimeButFarApartSplitByDistance() {
        // Same afternoon, but 50km apart — should not be treated as one continuous visit.
        let photos = [
            photo(minutesFromEpoch: 0, latitude: 37.7749, longitude: -122.4194),
            photo(minutesFromEpoch: 20, latitude: 37.3382, longitude: -121.8863)
        ]

        let groups = PhotoClusteringService.proposeGroups(from: photos)

        #expect(groups.count == 2)
    }

    @Test func groupsAreOrderedChronologicallyRegardlessOfInputOrder() {
        let photos = [
            photo(minutesFromEpoch: 200),
            photo(minutesFromEpoch: 0),
            photo(minutesFromEpoch: 210),
            photo(minutesFromEpoch: 10)
        ]

        let groups = PhotoClusteringService.proposeGroups(from: photos)

        #expect(groups.count == 2)
        #expect(groups[0].proposedStartTime == Date(timeIntervalSince1970: 0))
        #expect(groups[1].proposedStartTime == Date(timeIntervalSince1970: 200 * 60))
    }

    @Test func proposedStartAndEndTimeMatchExtremesOfGroup() {
        let photos = [photo(minutesFromEpoch: 5), photo(minutesFromEpoch: 0), photo(minutesFromEpoch: 15)]

        let groups = PhotoClusteringService.proposeGroups(from: photos)

        #expect(groups.first?.proposedStartTime == Date(timeIntervalSince1970: 0))
        #expect(groups.first?.proposedEndTime == Date(timeIntervalSince1970: 15 * 60))
    }

    @Test func singlePhotoGroupHasEqualStartAndEndTime() {
        let groups = PhotoClusteringService.proposeGroups(from: [photo(minutesFromEpoch: 42)])

        #expect(groups.first?.proposedStartTime == groups.first?.proposedEndTime)
    }

    @Test func approximateCoordinateAveragesAvailablePhotoLocations() {
        let group = PhotoImportGroup(photos: [
            photo(minutesFromEpoch: 0, latitude: 10, longitude: 20),
            photo(minutesFromEpoch: 5, latitude: 20, longitude: 40)
        ])

        #expect(group.approximateCoordinate?.latitude == 15)
        #expect(group.approximateCoordinate?.longitude == 30)
    }

    @Test func approximateCoordinateIsNilWhenNoPhotosHaveLocation() {
        let group = PhotoImportGroup(photos: [photo(minutesFromEpoch: 0)])

        #expect(group.approximateCoordinate == nil)
    }
}
