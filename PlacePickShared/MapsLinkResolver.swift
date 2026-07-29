import Foundation

/// A place name and/or coordinates recovered from a Maps link. Purely a search hint — the
/// user still confirms the final Place via Apple Maps Search, per IMPORT_PIPELINE.md
/// "URL Resolution": "URLs should assist Candidate Resolution rather than bypass it."
struct MapsLinkCandidate: Equatable {
    var name: String?
    var latitude: Double?
    var longitude: Double?
}

/// Resolves Apple Maps and Google Maps links into a search candidate, per
/// IMPORT_PIPELINE.md "URL Resolution". Short links (maps.apple.com/p/..., maps.app.goo.gl/...)
/// carry no place data in the URL itself — the name only exists on the maps provider's
/// server, discovered by following the HTTP redirect. This never scrapes page content or
/// depends on private APIs (IMPORT_PIPELINE.md "Social Media URLs" applies the same
/// restraint here): it only reads the `Location` redirect header and parses the resolved
/// URL's own query/path, exactly like the already-supported long-form links.
enum MapsLinkResolver {
    private static let timeout: TimeInterval = 5

    /// Reused across calls rather than created per-request. A fresh URLSession pays DNS/TLS
    /// cold-start costs again each time — on a just-launched process (the common case here,
    /// since the Share Extension hands off to a freshly opened app) that cold start can exceed
    /// even a generous timeout, producing the exact "empty first time, works on retry" pattern
    /// this was built to avoid. One shared session lets later calls reuse warmed-up connections.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        return URLSession(configuration: configuration)
    }()

    /// Resolves `url` into a search candidate. Returns nil if `url` isn't a recognized Maps
    /// host, or resolution fails/times out — callers should fall back to existing weak
    /// text/title extraction, never to raw domain text.
    static func resolve(_ url: URL) async -> MapsLinkCandidate? {
        guard isMapsHost(url) else { return nil }

        if let candidate = parse(url), candidate.name != nil {
            return candidate
        }

        guard let resolvedURL = await followRedirect(url) else { return nil }
        return parse(resolvedURL)
    }

    /// Recognizes Apple/Google Maps hosts regardless of path shape. Real share links vary a
    /// lot: maps.google.com/?q=... has path "/", maps.google.com/maps/place/... has "/maps/...",
    /// www.google.com/maps/place/... has "/maps/...", and goo.gl/maps/... has "/maps/...".
    /// Gating on a path prefix (as an earlier version did) silently rejected the first shape.
    /// `maps.google.com` is matched by host alone; `google.com`/`www.google.com` additionally
    /// require a `/maps` path so unrelated Google links (Search, Drive, Mail, ...) aren't
    /// misidentified — those hosts serve far more than Maps.
    private static func isMapsHost(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        if host == "maps.apple.com" || host == "maps.apple" || host == "goo.gl" || host == "maps.app.goo.gl" {
            return true
        }
        if host == "maps.google.com" {
            return true
        }
        if host == "google.com" || host == "www.google.com" {
            return url.path.hasPrefix("/maps")
        }
        return false
    }

    /// Follows redirects without downloading a response body — this only needs the final
    /// `Location`, not page content. A short, fixed timeout keeps the caller's UI responsive
    /// even when the network is slow or absent.
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

    private static func parse(_ url: URL) -> MapsLinkCandidate? {
        guard let host = url.host?.lowercased() else { return nil }

        if host.contains("apple") {
            return parseAppleMaps(url)
        }
        if host.contains("google") {
            return parseGoogleMaps(url)
        }
        return nil
    }

    /// Apple Maps uses different query parameter names depending on link origin: a directly
    /// shared/typed search link carries `q`/`ll`, while a redirect-resolved short link
    /// (maps.apple/p/...) resolves to `name`/`coordinate` instead (confirmed by following a
    /// real maps.apple/p/... redirect — it lands on .../place?name=...&coordinate=...).
    /// Both are checked since either can appear.
    private static func parseAppleMaps(_ url: URL) -> MapsLinkCandidate? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else { return nil }

        // URLComponents percent-decodes automatically but leaves "+" as a literal character —
        // it's a form-encoding convention, not a URL standard, so a space-as-"+" query value
        // (as the `q` form produces) needs this converted explicitly, same as parseGoogleMaps.
        let name = queryItems.first(where: { $0.name == "q" || $0.name == "name" })?.value?
            .replacingOccurrences(of: "+", with: " ")
        let coordinateString = queryItems.first(where: { $0.name == "ll" || $0.name == "coordinate" })?.value
        let (latitude, longitude) = parseCoordinatePair(coordinateString)

        guard name != nil || latitude != nil else { return nil }
        return MapsLinkCandidate(name: name, latitude: latitude, longitude: longitude)
    }

    /// Google Maps encodes a Place two different ways depending on share source: the
    /// `/maps/place/<name>/@<lat>,<lng>,...` path form, or a plain `?q=<name>` query form
    /// (e.g. maps.google.com/?q=...). Path form is checked first since it also carries
    /// coordinates; query form is the fallback.
    private static func parseGoogleMaps(_ url: URL) -> MapsLinkCandidate? {
        if let fromPath = parseGoogleMapsPath(url) {
            return fromPath
        }
        return parseGoogleMapsQuery(url)
    }

    private static func parseGoogleMapsPath(_ url: URL) -> MapsLinkCandidate? {
        let segments = url.path.split(separator: "/").map(String.init)
        guard let placeIndex = segments.firstIndex(of: "place"), placeIndex + 1 < segments.count else {
            return nil
        }

        let name = segments[placeIndex + 1]
            .replacingOccurrences(of: "+", with: " ")
            .removingPercentEncoding

        var latitude: Double?
        var longitude: Double?
        if let coordinateSegment = segments.first(where: { $0.hasPrefix("@") }) {
            let stripped = String(coordinateSegment.dropFirst())
            let parts = stripped.split(separator: ",")
            if parts.count >= 2 {
                latitude = Double(parts[0])
                longitude = Double(parts[1])
            }
        }

        guard let name, !name.isEmpty else {
            guard latitude != nil else { return nil }
            return MapsLinkCandidate(name: nil, latitude: latitude, longitude: longitude)
        }
        return MapsLinkCandidate(name: name, latitude: latitude, longitude: longitude)
    }

    private static func parseGoogleMapsQuery(_ url: URL) -> MapsLinkCandidate? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else { return nil }

        // A redirect-resolved short link's q= often carries "Name, full street address" (e.g.
        // "Meenakshi Bhavan, 4996 Stevens Creek Blvd, San Jose, CA 95129") rather than just the
        // name. Passing the whole string to Apple Maps Search returns "No results" in practice —
        // it wants a plain name, and can already resolve the address itself. Taking only the
        // text before the first comma keeps this a hint (per IMPORT_PIPELINE.md "URL Resolution")
        // rather than an invented location: worst case a place whose real name contains a comma
        // gets truncated to its first clause, still a reasonable, editable starting search.
        let name = queryItems.first(where: { $0.name == "q" })?.value?
            .replacingOccurrences(of: "+", with: " ")
            .split(separator: ",", maxSplits: 1).first
            .map(String.init)

        guard let name, !name.isEmpty else { return nil }
        return MapsLinkCandidate(name: name, latitude: nil, longitude: nil)
    }

    private static func parseCoordinatePair(_ raw: String?) -> (Double?, Double?) {
        guard let raw else { return (nil, nil) }
        let parts = raw.split(separator: ",")
        guard parts.count >= 2, let lat = Double(parts[0]), let lon = Double(parts[1]) else {
            return (nil, nil)
        }
        return (lat, lon)
    }
}
