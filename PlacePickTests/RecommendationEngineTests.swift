import Testing
import Foundation
@testable import PlacePick

struct RecommendationEngineTests {
    let engine = DefaultRecommendationEngine()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let testCollection = PlaceCollection(name: "Test Collection", icon: "mappin", order: 0)

    private func makePlace(
        isFavorite: Bool = false,
        emotion: PlaceEmotion? = nil,
        createdAt: Date
    ) -> Place {
        Place(
            appleMapIdentifier: "test-id",
            name: "Test Place",
            latitude: 0,
            longitude: 0,
            collection: testCollection,
            isFavorite: isFavorite,
            emotion: emotion,
            createdAt: createdAt
        )
    }

    @Test func favoriteWithNoEmotionScoresHighest() {
        let place = makePlace(isFavorite: true, emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))
        let other = makePlace(isFavorite: false, emotion: .happy, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: place, now: now).value > engine.importance(for: other, now: now).value)
    }

    @Test func noEmotionScoresHigherThanRecordedEmotion() {
        let unresolved = makePlace(emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))
        let resolved = makePlace(emotion: .neutral, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: unresolved, now: now).value > engine.importance(for: resolved, now: now).value)
    }

    @Test func nilAndNeutralProduceDifferentScores() {
        let nilPlace = makePlace(emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))
        let neutralPlace = makePlace(emotion: .neutral, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: nilPlace, now: now).value != engine.importance(for: neutralPlace, now: now).value)
    }

    @Test func recentlySavedReceivesSmallBoost() {
        let recent = makePlace(emotion: .happy, createdAt: now.addingTimeInterval(-1 * 86400))
        let old = makePlace(emotion: .happy, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: recent, now: now).value > engine.importance(for: old, now: now).value)
    }

    @Test func scoreIsDeterministicForSameFacts() {
        let place = makePlace(isFavorite: true, emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))

        let first = engine.importance(for: place, now: now).value
        let second = engine.importance(for: place, now: now).value

        #expect(first == second)
    }

    @Test func scoreDoesNotDependOnOtherPlaces() {
        let place = makePlace(isFavorite: true, emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))

        let scoreAlone = engine.importance(for: place, now: now).value

        // Simulate other places existing by constructing them; the engine must never
        // take them as input, so the score for `place` must be unaffected.
        _ = (0..<50).map { _ in makePlace(isFavorite: true, emotion: nil, createdAt: now) }

        let scoreWithOthersPresent = engine.importance(for: place, now: now).value

        #expect(scoreAlone == scoreWithOthersPresent)
    }

    @Test func scoreStaysWithinNormalizedRange() {
        let mostImportant = makePlace(isFavorite: true, emotion: nil, createdAt: now)
        let leastImportant = makePlace(isFavorite: false, emotion: .amazed, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: mostImportant, now: now).value <= 1.0)
        #expect(engine.importance(for: leastImportant, now: now).value >= 0.0)
    }
}
