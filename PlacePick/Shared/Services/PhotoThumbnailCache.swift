import UIKit

/// Bounded in-memory cache for Photos-library thumbnails. PlacePick never stores a
/// permanent copy of the user's photo library — this exists purely to avoid re-fetching
/// from Photos on every scroll/re-render. NSCache evicts under memory pressure
/// automatically, so this can never grow unbounded or "explode" the app's memory.
/// NSCache is internally thread-safe; @unchecked Sendable reflects that guarantee since
/// the compiler cannot verify it automatically.
final class PhotoThumbnailCache: @unchecked Sendable {
    static let shared = PhotoThumbnailCache()

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200 // roughly bounds memory regardless of image size
        return cache
    }()

    private init() {}

    func image(for identifier: String) -> UIImage? {
        cache.object(forKey: identifier as NSString)
    }

    func store(_ image: UIImage, for identifier: String) {
        cache.setObject(image, forKey: identifier as NSString)
    }
}
