import Foundation

/// Temporary transport data bridging the Share Extension and the main app.
/// Not a Place. Never synced, never shown as saved content. See IMPORT_PIPELINE.md
/// "PendingImport Model" and "Pending Import Cleanup".
struct PendingImport: Codable, Identifiable, Equatable {
    let id: UUID
    var sourceURL: URL?
    var sharedTitle: String?
    var sharedText: String?
    var suggestedSearchText: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        sourceURL: URL? = nil,
        sharedTitle: String? = nil,
        sharedText: String? = nil,
        suggestedSearchText: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sharedTitle = sharedTitle
        self.sharedText = sharedText
        self.suggestedSearchText = suggestedSearchText
        self.createdAt = createdAt
    }
}

/// Stores the single in-flight PendingImport in the App Group container so both the
/// Share Extension and main app can access it. Only one pending import is supported at a
/// time: the extension hands off to the main app immediately after saving one.
enum PendingImportStore {
    private static let appGroupID = "group.com.sianjin.PlacePick"
    private static let key = "com.sianjin.PlacePick.pendingImport"

    /// PendingImports older than this are treated as abandoned and discarded on read,
    /// per IMPORT_PIPELINE.md "Pending Import Cleanup" (expire automatically).
    private static let expiration: TimeInterval = 10 * 60

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ pendingImport: PendingImport) {
        guard let data = try? JSONEncoder().encode(pendingImport) else { return }
        defaults?.set(data, forKey: key)
    }

    static func load() -> PendingImport? {
        guard let data = defaults?.data(forKey: key),
              let pendingImport = try? JSONDecoder().decode(PendingImport.self, from: data)
        else { return nil }

        guard Date.now.timeIntervalSince(pendingImport.createdAt) <= expiration else {
            clear()
            return nil
        }
        return pendingImport
    }

    static func clear() {
        defaults?.removeObject(forKey: key)
    }
}
