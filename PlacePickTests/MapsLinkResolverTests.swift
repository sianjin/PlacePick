import Testing
import Foundation
@testable import PlacePick

/// Covers the deterministic, offline parsing paths only — long-form Apple/Google Maps URLs
/// that already carry name/coordinates and never need the redirect-follow network call.
/// The redirect-follow path (short links like maps.app.goo.gl) is intentionally untested here
/// since it requires a real network round-trip; see MapsLinkResolver's timeout/fallback
/// behavior, which callers rely on regardless of network conditions.
struct MapsLinkResolverTests {
    @Test func parsesAppleMapsQueryParameter() async {
        let url = URL(string: "https://maps.apple.com/?q=Golden+Gate+Bridge&ll=37.8199,-122.4783")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result?.name == "Golden Gate Bridge")
        #expect(result?.latitude == 37.8199)
        #expect(result?.longitude == -122.4783)
    }

    @Test func parsesAppleMapsCoordinateParameter() async {
        let url = URL(string: "https://maps.apple.com/place?q=Meenakshi%20Bhavan&coordinate=37.51,-121.9")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result?.name == "Meenakshi Bhavan")
        #expect(result?.latitude == 37.51)
        #expect(result?.longitude == -121.9)
    }

    @Test func parsesGoogleMapsPlacePath() async {
        let url = URL(string: "https://www.google.com/maps/place/Meenakshi+Bhavan/@37.5074,-121.9552,17z")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result?.name == "Meenakshi Bhavan")
        #expect(result?.latitude == 37.5074)
        #expect(result?.longitude == -121.9552)
    }

    /// Regression test: maps.google.com/?q=... (a real share-sheet output, no /maps path
    /// segment) was previously rejected by isMapsHost's overly strict path check, silently
    /// producing an empty search field for a very common real-world link shape.
    @Test func parsesGoogleMapsHostWithQueryParameterAndNoPathPrefix() async {
        let url = URL(string: "https://maps.google.com/?q=Meenakshi+Bhavan")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result?.name == "Meenakshi Bhavan")
    }

    @Test func parsesGoogleMapsHostWithPlacePath() async {
        let url = URL(string: "https://maps.google.com/maps/place/Meenakshi+Bhavan/@37.5074,-121.9552,17z")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result?.name == "Meenakshi Bhavan")
        #expect(result?.latitude == 37.5074)
        #expect(result?.longitude == -121.9552)
    }

    /// Regression test for the real repro: a resolved short link's q= often carries
    /// "Name, full street address" rather than just the name (Google appends the address after
    /// the redirect). Passing the whole string to Apple Maps Search returned "No results" in
    /// practice, so only the text before the first comma should be kept.
    @Test func stripsAddressAfterFirstCommaFromGoogleMapsQuery() async {
        let url = URL(string: "https://maps.google.com?q=Meenakshi+Bhavan,+4996+Stevens+Creek+Blvd,+San+Jose,+CA+95129&ftid=abc")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result?.name == "Meenakshi Bhavan")
    }

    /// Regression test for the real repro: maps.apple/p/... short links (Apple Maps' native
    /// Share button) resolve to .../place?name=...&coordinate=... — a different parameter
    /// naming convention than the `q`/`ll` used by directly-typed/shared search links.
    @Test func parsesAppleMapsRedirectResolvedNameParameter() async {
        let url = URL(string: "https://maps.apple.com/place?address=969%20Kiely%20Blvd&coordinate=37.342481,-121.974530&name=Central%20Park&place-id=abc")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result?.name == "Central Park")
        #expect(result?.latitude == 37.342481)
        #expect(result?.longitude == -121.974530)
    }

    @Test func returnsNilForBareGoogleComWithoutMapsPath() async {
        let url = URL(string: "https://www.google.com/search?q=Meenakshi+Bhavan")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result == nil)
    }

    @Test func returnsNilForNonMapsHost() async {
        let url = URL(string: "https://www.yelp.com/biz/somewhere")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result == nil)
    }

    @Test func returnsNilForInstagramURL() async {
        let url = URL(string: "https://instagram.com/p/abc123")!
        let result = await MapsLinkResolver.resolve(url)
        #expect(result == nil)
    }
}
