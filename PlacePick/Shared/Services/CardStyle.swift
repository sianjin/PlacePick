import SwiftUI

/// Shared corner-radius/shadow constants for card-like surfaces (MemoryCard, MemoryRow) —
/// not a full design system, just enough to keep the two in visual agreement rather than
/// each hand-typing its own cornerRadius.
enum CardStyle {
    /// The card container itself.
    static let outerCornerRadius: CGFloat = 16
    /// Content inset within the card (e.g. a cover photo), smaller than outerCornerRadius
    /// so its corners read as nested rather than concentric with the card's own.
    static let innerCornerRadius: CGFloat = 10

    static let shadowColor = Color.black.opacity(0.12)
    static let shadowRadius: CGFloat = 6
    static let shadowYOffset: CGFloat = 2
}
