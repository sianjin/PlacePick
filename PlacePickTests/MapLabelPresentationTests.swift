import Testing
import MapKit
@testable import PlacePick

struct MapLabelPresentationTests {
    @Test func neighborhoodZoomAlwaysShowsLabelRegardlessOfImportance() {
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

        #expect(MapLabelPresentation.shouldShowLabel(importance: ImportanceScore(value: 0.0), span: span))
        #expect(MapLabelPresentation.shouldShowLabel(importance: ImportanceScore(value: 1.0), span: span))
    }

    @Test func wideZoomHidesLowImportanceLabels() {
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)

        #expect(!MapLabelPresentation.shouldShowLabel(importance: ImportanceScore(value: 0.1), span: span))
    }

    @Test func wideZoomShowsHighImportanceLabels() {
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)

        #expect(MapLabelPresentation.shouldShowLabel(importance: ImportanceScore(value: 0.9), span: span))
    }

    @Test func decisionIsDeterministicForSameInputs() {
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let importance = ImportanceScore(value: 0.5)

        let first = MapLabelPresentation.shouldShowLabel(importance: importance, span: span)
        let second = MapLabelPresentation.shouldShowLabel(importance: importance, span: span)

        #expect(first == second)
    }

    @Test func zoomingOutNeverMakesALabelMoreLikelyToShow() {
        let closeSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let wideSpan = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let importance = ImportanceScore(value: 0.4)

        let closeResult = MapLabelPresentation.shouldShowLabel(importance: importance, span: closeSpan)
        let wideResult = MapLabelPresentation.shouldShowLabel(importance: importance, span: wideSpan)

        // If a label shows at wide zoom, it must also show when zoomed in closer.
        if wideResult {
            #expect(closeResult)
        }
    }

    @Test func neighborhoodAndCityZoomAlwaysShowMarkerRegardlessOfImportance() {
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)

        #expect(MapLabelPresentation.shouldShowMarker(importance: ImportanceScore(value: 0.0), span: span))
        #expect(MapLabelPresentation.shouldShowMarker(importance: ImportanceScore(value: 1.0), span: span))
    }

    @Test func veryWideZoomHidesLowImportanceMarkers() {
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)

        #expect(!MapLabelPresentation.shouldShowMarker(importance: ImportanceScore(value: 0.1), span: span))
    }

    @Test func veryWideZoomShowsHighImportanceMarkers() {
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)

        #expect(MapLabelPresentation.shouldShowMarker(importance: ImportanceScore(value: 0.9), span: span))
    }

    @Test func zoomingOutNeverMakesAMarkerMoreLikelyToShow() {
        let closeSpan = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let wideSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let importance = ImportanceScore(value: 0.4)

        let closeResult = MapLabelPresentation.shouldShowMarker(importance: importance, span: closeSpan)
        let wideResult = MapLabelPresentation.shouldShowMarker(importance: importance, span: wideSpan)

        if wideResult {
            #expect(closeResult)
        }
    }
}
