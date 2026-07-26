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
}
