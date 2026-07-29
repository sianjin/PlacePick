import Testing
import Foundation
@testable import PlacePick

struct CandidateExtractorTests {
    @Test func prefersExplicitTitleOverText() {
        let result = CandidateExtractor.extractSearchText(
            title: "Blue Bottle Coffee",
            text: "Check out this amazing spot!",
            url: URL(string: "https://instagram.com/p/abc123")
        )
        #expect(result == "Blue Bottle Coffee")
    }

    @Test func fallsBackToTextWhenTitleIsMissing() {
        let result = CandidateExtractor.extractSearchText(
            title: nil,
            text: "Blue Bottle Coffee in SF",
            url: nil
        )
        #expect(result == "Blue Bottle Coffee in SF")
    }

    @Test func fallsBackToURLHostWhenNoTitleOrText() {
        let result = CandidateExtractor.extractSearchText(
            title: nil,
            text: nil,
            url: URL(string: "https://www.yelp.com/biz/somewhere")
        )
        #expect(result == "yelp.com")
    }

    @Test func returnsNilWhenNothingUsableExists() {
        let result = CandidateExtractor.extractSearchText(title: nil, text: nil, url: nil)
        #expect(result == nil)
    }

    @Test func stripsHashtagsAndCollapsesWhitespace() {
        let result = CandidateExtractor.extractSearchText(
            title: "Blue   Bottle #coffee #sf   Coffee",
            text: nil,
            url: nil
        )
        #expect(result == "Blue Bottle Coffee")
    }

    @Test func takesTextBeforeASeparator() {
        let result = CandidateExtractor.extractSearchText(
            title: "Blue Bottle Coffee | Best coffee in the Mission",
            text: nil,
            url: nil
        )
        #expect(result == "Blue Bottle Coffee")
    }

    @Test func blankTitleFallsThroughToText() {
        let result = CandidateExtractor.extractSearchText(
            title: "   ",
            text: "Ramen Nagi",
            url: nil
        )
        #expect(result == "Ramen Nagi")
    }

    @Test func doesNotInventAPlaceFromAnEmptyPayload() {
        let result = CandidateExtractor.extractSearchText(title: "", text: "", url: nil)
        #expect(result == nil)
    }

    /// Maps hosts are excluded from the domain fallback because they're never a usable place
    /// name ("maps.apple.com" isn't a place) and MapsLinkResolver gives them a real shot at
    /// the actual name via redirect resolution instead — see MapScreen.handlePendingImport.
    @Test func returnsNilForAppleMapsHostInsteadOfDomainText() {
        let result = CandidateExtractor.extractSearchText(
            title: nil,
            text: nil,
            url: URL(string: "https://maps.apple.com/p/abc123")
        )
        #expect(result == nil)
    }

    @Test func returnsNilForGoogleMapsShortLinkInsteadOfDomainText() {
        let result = CandidateExtractor.extractSearchText(
            title: nil,
            text: nil,
            url: URL(string: "https://maps.app.goo.gl/xyz789")
        )
        #expect(result == nil)
    }
}
