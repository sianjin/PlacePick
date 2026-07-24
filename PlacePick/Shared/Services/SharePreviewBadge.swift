import SwiftUI
import UIKit

/// SharePreview needs a rendered image, not a template SF Symbol — a bare
/// `Image(systemName:)` has no fill and shows blank in the share sheet.
@MainActor
func sharePreviewBadgeImage(icon: String) -> Image {
    let badge = Image(systemName: icon)
        .font(.system(size: 32))
        .foregroundStyle(.white)
        .padding(20)
        .background(Circle().fill(Color.accentColor))

    let renderer = ImageRenderer(content: badge)
    renderer.scale = UIScreen.main.scale
    guard let uiImage = renderer.uiImage else {
        return Image(systemName: icon)
    }
    return Image(uiImage: uiImage)
}
