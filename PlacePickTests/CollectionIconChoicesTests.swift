import Testing
import UIKit
@testable import PlacePick

struct CollectionIconChoicesTests {
    @Test func everyIconChoiceResolvesToARealSFSymbol() {
        for name in CollectionIconChoices.all {
            #expect(UIImage(systemName: name) != nil, "Missing SF Symbol: \(name)")
        }
    }
}
