import Foundation

/// Deterministic, lightweight extraction of a search candidate from shared content.
/// No AI, no scraping — see IMPORT_PIPELINE.md "Candidate Extraction" and "Candidate Priority".
/// A slightly imperfect search phrase is preferred over an invented location.
enum CandidateExtractor {
    /// Priority order: explicit title, selected/shared text, then a weak URL-derived fallback.
    /// Returns nil when nothing usable exists — an empty search field is always preferable
    /// to inventing a Place.
    static func extractSearchText(
        title: String?,
        text: String?,
        url: URL?
    ) -> String? {
        if let title, let cleaned = clean(title), !cleaned.isEmpty {
            return cleaned
        }
        if let text, let cleaned = clean(text), !cleaned.isEmpty {
            return cleaned
        }
        if let url, let hostFragment = weakFallback(from: url) {
            return hostFragment
        }
        return nil
    }

    /// Trims whitespace, collapses repeated spaces, strips hashtags and trailing tracking
    /// punctuation, and caps length. Deliberately conservative — it must not rewrite meaning.
    private static func clean(_ raw: String) -> String? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        text = text.replacingOccurrences(of: #"#\S+"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let separatorRange = text.range(of: #"\s[|—]\s"#, options: .regularExpression) {
            let before = String(text[text.startIndex..<separatorRange.lowerBound])
            if !before.isEmpty {
                text = before
            }
        }

        guard !text.isEmpty else { return nil }
        return String(text.prefix(120))
    }

    /// A weak, last-resort fallback: the URL's host, minus common prefixes like "www.".
    /// Never treated as a reliable place name — just enough to seed a manual search.
    private static func weakFallback(from url: URL) -> String? {
        guard let host = url.host else { return nil }
        let stripped = host.replacingOccurrences(of: #"^www\."#, with: "", options: .regularExpression)
        return stripped.isEmpty ? nil : stripped
    }
}
