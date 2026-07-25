import UIKit
import MapKit
import SwiftUI

/// Renders a Day Detail map region to a static UIImage — needed because ImageRenderer
/// (used for the Day Detail "Save" snapshot) reads its view tree synchronously, but a live
/// MapKit Map view hasn't finished loading tiles/annotations by the time that read happens,
/// so it captures blank/fallback content instead of the map. MKMapSnapshotter is Apple's
/// dedicated async API for turning a map region into a plain image ahead of time — the
/// same fix pattern already used for photos via PhotoAssetLoader.
///
/// MKMapSnapshotter renders only the base map; pins are not part of its output and must be
/// drawn onto the resulting image afterward.
enum DayMapSnapshotRenderer {
    struct Pin {
        let coordinate: CLLocationCoordinate2D
        let symbolName: String
    }

    static func renderSnapshot(region: MKCoordinateRegion, pins: [Pin], size: CGSize) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.scale = await UIScreen.main.scale

        let snapshotter = MKMapSnapshotter(options: options)

        guard let snapshot = try? await snapshotter.start() else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            snapshot.image.draw(at: .zero)

            for pin in pins {
                let point = snapshot.point(for: pin.coordinate)
                drawPin(pin, at: point)
            }
        }
    }

    private static func drawPin(_ pin: Pin, at point: CGPoint) {
        let diameter: CGFloat = 28
        let rect = CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter)

        UIColor(Color.accentColor).setFill()
        UIBezierPath(ovalIn: rect).fill()

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        guard let symbolImage = UIImage(systemName: pin.symbolName, withConfiguration: symbolConfig)?
            .withTintColor(.white, renderingMode: .alwaysOriginal) else { return }

        let symbolSize = symbolImage.size
        let symbolOrigin = CGPoint(x: point.x - symbolSize.width / 2, y: point.y - symbolSize.height / 2)
        symbolImage.draw(at: symbolOrigin)
    }
}
