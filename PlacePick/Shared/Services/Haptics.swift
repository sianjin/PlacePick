import UIKit

/// Imperative haptics for actions that dismiss their view immediately after (e.g. delete
/// then dismiss) — SwiftUI's `.sensoryFeedback(_:trigger:)` needs the view to stay alive
/// long enough to observe the trigger change, which delete-then-dismiss doesn't guarantee.
/// Prefer `.sensoryFeedback` directly wherever the view sticks around (e.g. a Toggle).
///
/// @MainActor because the underlying UIFeedbackGenerator classes are main-actor-isolated;
/// every call site is already a SwiftUI button/gesture action (main actor), so this makes
/// that existing guarantee explicit to the compiler instead of leaving it unstated.
@MainActor
enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func delete() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
