import Testing
import Foundation
@testable import PlacePick

/// Covers the deterministic, offline parsing paths only — the yelp.to short-link redirect
/// itself requires a real network round-trip; see YelpLinkResolver's timeout/fallback
/// behavior, which callers rely on regardless of network conditions.
struct YelpLinkResolverTests {
    @Test func parsesYelpBizSlugDirectly() async {
        let url = URL(string: "https://www.yelp.com/biz/noodle-panda-sunnyvale?utm_source=ishare")!
        let result = await YelpLinkResolver.resolve(url)
        #expect(result?.name == "noodle panda sunnyvale")
    }

    /// Regression test for the real repro: yelp.com/biz/<slug> sometimes carries a trailing
    /// numeric disambiguator (e.g. "-2") for duplicate business names in the same city.
    @Test func stripsTrailingNumericDisambiguatorFromSlug() async {
        let url = URL(string: "https://www.yelp.com/biz/philz-coffee-san-francisco-11")!
        let result = await YelpLinkResolver.resolve(url)
        #expect(result?.name == "philz coffee san francisco")
    }

    @Test func returnsNilForNonYelpHost() async {
        let url = URL(string: "https://www.google.com/maps/place/Somewhere/@37.5,-121.9,17z")!
        let result = await YelpLinkResolver.resolve(url)
        #expect(result == nil)
    }

    @Test func returnsNilForYelpHomepageWithoutBizPath() async {
        let url = URL(string: "https://www.yelp.com/")!
        let result = await YelpLinkResolver.resolve(url)
        #expect(result == nil)
    }
}
