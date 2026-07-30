import Foundation

/// Resolves Yelp business links into a search candidate, per IMPORT_PIPELINE.md
/// "URL Resolution". Yelp's share sheet produces a yelp.to short link that carries no
/// place data itself — the name only exists in yelp.com/biz/<slug>, discovered by
/// following the redirect. Unlike Maps, yelp.com itself blocks automated requests
/// (DataDome bot protection returns 403 for any page fetch), and on iOS the short link's
/// *first* redirect hop lands on an app.adjust.com deferred-deep-link page that returns
/// HTTP 200 rather than redirecting further — so URLSession's automatic redirect-following
/// stops there instead of reaching yelp.com. The real yelp.com/biz/<slug> URL is still
/// recoverable without fetching it: it's embedded verbatim in that adjust.com URL's own
/// `deep_link` query parameter. This never scrapes page content, matching the same
/// restraint IMPORT_PIPELINE.md "Social Media URLs" already requires.
enum YelpLinkResolver {
    private static let timeout: TimeInterval = 5

    /// Reused across calls for the same cold-start reason as MapsLinkResolver's session.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        return URLSession(configuration: configuration)
    }()

    /// Resolves `url` into a search candidate. Returns nil if `url` isn't a recognized Yelp
    /// host, or resolution fails/times out — callers should fall back to existing weak
    /// text/title extraction, never to raw domain text.
    static func resolve(_ url: URL) async -> MapsLinkCandidate? {
        guard isYelpHost(url) else { return nil }

        if let candidate = parseBizURL(url) {
            return candidate
        }

        guard let resolvedURL = await followRedirect(url) else { return nil }
        if let candidate = parseBizURL(resolvedURL) {
            return candidate
        }
        guard let deepLinked = extractDeepLink(from: resolvedURL) else { return nil }
        return parseBizURL(deepLinked)
    }

    /// Lets callers route directly to the matching resolver instead of trying MapsLinkResolver
    /// first and falling through on failure — that sequential try-then-fallback pattern doubles
    /// network latency for every Yelp link (Maps' own HEAD request has to fail/time out before
    /// Yelp's even starts), which is what caused the "empty on a cold-started process" repro.
    static func isYelpHost(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "yelp.to" || host == "www.yelp.com" || host == "yelp.com"
    }

    /// A short link's redirect chain can pass through app.adjust.com before (never) reaching
    /// yelp.com — this only reads the `Location`/final `response.url`, never a response body.
    private static func followRedirect(_ url: URL) async -> URL? {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout

        do {
            let (_, response) = try await session.data(for: request)
            return response.url
        } catch {
            return nil
        }
    }

    /// app.adjust.com's deferred-deep-link landing page carries the real yelp.com/biz/<slug>
    /// URL in its own `deep_link` (or `redirect`) query parameter, still percent-encoded.
    private static func extractDeepLink(from url: URL) -> URL? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else { return nil }

        let raw = queryItems.first(where: { $0.name == "deep_link" || $0.name == "redirect" })?.value
        guard let raw, let decoded = URL(string: raw) else { return nil }
        return decoded
    }

    /// yelp.com/biz/<slug> is the only reliable source of a name — Yelp blocks fetching the
    /// page itself, so the slug (typically "<name>-<city>" or "<name>-<city>-<n>" for
    /// disambiguation) is all that's available. There's no delimiter marking where the name
    /// ends and the city begins, so this only strips a trailing numeric disambiguator and
    /// turns dashes into spaces — a deliberately imperfect search seed the user can edit,
    /// same tradeoff IMPORT_PIPELINE.md already accepts for Google's comma-truncation.
    private static func parseBizURL(_ url: URL) -> MapsLinkCandidate? {
        guard let host = url.host?.lowercased(), host.hasSuffix("yelp.com") else { return nil }

        let segments = url.path.split(separator: "/").map(String.init)
        guard let bizIndex = segments.firstIndex(of: "biz"), bizIndex + 1 < segments.count else {
            return nil
        }

        var slug = segments[bizIndex + 1]
        slug = slug.replacingOccurrences(of: #"-\d+$"#, with: "", options: .regularExpression)

        let name = slug.replacingOccurrences(of: "-", with: " ")
        guard !name.isEmpty else { return nil }
        return MapsLinkCandidate(name: name, latitude: nil, longitude: nil)
    }
}
