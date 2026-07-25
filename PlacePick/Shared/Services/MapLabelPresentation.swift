import Foundation
import MapKit

/// Presentation-layer decision only — never recomputes or reinterprets Importance.
/// See RECOMMENDATION_MODEL.md "Presentation Boundary" and "Zoom Adaptation": labels may
/// be suppressed at wide zoom to reduce clutter, but Importance itself never changes.
enum MapLabelPresentation {
    /// Wider span = more zoomed out. Below this span, every Place gets a label regardless
    /// of importance — there's enough room and "neighborhood zoom" per the spec calls for
    /// full detail.
    private static let fullDetailLatitudeDelta: Double = 0.03

    /// Above this span (city/region view), only the most important Places are labeled to
    /// avoid clutter — the exact threshold is a presentation tuning parameter, not a
    /// recommendation weight.
    private static let wideZoomLatitudeDelta: Double = 0.15

    /// At wide zoom, only Places at or above this Importance receive a label.
    private static let wideZoomImportanceThreshold: Double = 0.6

    static func shouldShowLabel(importance: ImportanceScore, span: MKCoordinateSpan) -> Bool {
        if span.latitudeDelta <= fullDetailLatitudeDelta {
            return true
        }
        if span.latitudeDelta >= wideZoomLatitudeDelta {
            return importance.value >= wideZoomImportanceThreshold
        }

        // Between the two thresholds, linearly raise the bar as the map zooms out —
        // avoids labels popping in/out abruptly at a single hard cutoff.
        let progress = (span.latitudeDelta - fullDetailLatitudeDelta) / (wideZoomLatitudeDelta - fullDetailLatitudeDelta)
        let threshold = progress * wideZoomImportanceThreshold
        return importance.value >= threshold
    }

    /// Above this span (region/state view), pins themselves start thinning out — see
    /// RECOMMENDATION_MODEL.md "Zoom Adaptation": "at broad zoom levels: clustering is
    /// preferred." Wider than fullDetailLatitudeDelta because hiding a pin is a much
    /// stronger move than just hiding its label — every Place still has a visible pin at
    /// neighborhood/city zoom, only very wide (multi-city/region) views start dropping
    /// low-importance ones so the map doesn't become a wall of overlapping icons.
    private static let markerThinningLatitudeDelta: Double = 0.3

    /// Above this span, only the most important Places keep a pin at all.
    private static let wideZoomMarkerImportanceThreshold: Double = 0.6

    static func shouldShowMarker(importance: ImportanceScore, span: MKCoordinateSpan) -> Bool {
        guard span.latitudeDelta > markerThinningLatitudeDelta else { return true }
        return importance.value >= wideZoomMarkerImportanceThreshold
    }
}
