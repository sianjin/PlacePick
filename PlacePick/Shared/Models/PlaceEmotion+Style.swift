import SwiftUI

/// Shared visual language for Emotion across the app — the Calendar's day-cell tint ring
/// and EmotionPicker's selected-state ring use the same color per Emotion, so a day's
/// feeling reads consistently wherever it appears.
extension PlaceEmotion {
    var tintColor: Color {
        switch self {
        case .neutral: return .gray
        case .happy: return .yellow
        case .amazed: return .orange
        }
    }
}
