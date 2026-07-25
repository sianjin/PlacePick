import Foundation

/// Decides *when* to ask SwiftUI's `.requestReview` environment action to show the
/// system review prompt — never decides whether it actually appears (Apple throttles
/// that itself). Per the checklist: ask only after a positive experience, never on
/// first launch. A successful save (Place or Memory) is the clearest positive signal
/// PlacePick has; this fires on the 3rd and every 10th one after, so it's not asked
/// once and then never again for a long-time user, but also isn't asked constantly.
enum ReviewRequestTrigger {
    private static let countKey = "com.sianjin.PlacePick.successfulSaveCount"

    static func recordSuccessfulSaveAndShouldRequestReview() -> Bool {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)

        return count == 3 || (count > 3 && count.isMultiple(of: 10))
    }
}
