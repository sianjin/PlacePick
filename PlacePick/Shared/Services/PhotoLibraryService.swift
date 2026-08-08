import SwiftUI
import Photos
import PhotosUI

/// Resolves PhotosPicker selections into PhotoImportCandidates. MomentMap is a personal
/// memory layer, not a photo library — image bytes are never copied into app storage.
/// Only the Photos-library asset identifier is kept; PhotoAssetThumbnailView looks up the
/// actual image from Photos on demand, through a small bounded cache for scroll
/// performance (see PhotoThumbnailCache).
///
/// PHAsset lookup provides capture time/GPS, and is the only source when EXIF is
/// unavailable (e.g. limited-library edge cases) — it never substitutes for the asset
/// identifier itself. See DATA_MODEL.md §8.2 "capturedAt": MomentMap must not substitute
/// import or current time when reliable capture time is unavailable — items with no
/// resolvable date from either source are dropped, not defaulted.
///
/// PHAsset.creationDate is NOT always trustworthy for photos with GPS: iOS Photos can
/// compute it by interpreting the image's naive EXIF local-time string using the
/// device's CURRENT time zone rather than the time zone the photo was actually taken in
/// — e.g. a 9:19 PM EXIF timestamp from a NYC photo, viewed on a Pacific-time device,
/// can surface as "9:19 PM" misinterpreted as PST, shifting the true instant by 3 hours.
/// Since GPS lets us resolve the correct time zone ourselves, EXIF-derived time is
/// preferred over PHAsset.creationDate whenever EXIF GPS + a raw local-time string are
/// both present; PHAsset.creationDate is used only when EXIF can't provide a corrected time.
enum PhotoLibraryService {
    static func requestReadAccessIfNeeded() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard current == .notDetermined else { return current }
        return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    static func loadCandidates(for items: [PhotosPickerItem]) async -> [PhotoImportCandidate] {
        let assetsByIdentifier = fetchAssets(for: items)

        var candidates: [PhotoImportCandidate] = []
        for item in items {
            guard let identifier = item.itemIdentifier else { continue }
            let asset = assetsByIdentifier[identifier]

            var capturedAt = asset?.creationDate
            var latitude = asset?.location?.coordinate.latitude
            var longitude = asset?.location?.coordinate.longitude

            if let data = try? await item.loadTransferable(type: Data.self) {
                let exif = await PhotoMetadataExtractor.extractMetadata(from: data)
                // EXIF's GPS-corrected time wins over PHAsset.creationDate whenever it's
                // available — see the type doc comment on why creationDate alone isn't
                // trustworthy for photos taken outside the device's current time zone.
                capturedAt = exif.capturedAt ?? capturedAt
                latitude = latitude ?? exif.latitude
                longitude = longitude ?? exif.longitude
            }

            guard let capturedAt else { continue }

            candidates.append(
                PhotoImportCandidate(
                    id: identifier,
                    localAssetIdentifier: identifier,
                    capturedAt: capturedAt,
                    latitude: latitude,
                    longitude: longitude
                )
            )
        }
        return candidates
    }

    private static func fetchAssets(for items: [PhotosPickerItem]) -> [String: PHAsset] {
        let identifiers = items.compactMap(\.itemIdentifier)
        guard !identifiers.isEmpty else { return [:] }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var result: [String: PHAsset] = [:]
        assets.enumerateObjects { asset, _, _ in
            result[asset.localIdentifier] = asset
        }
        return result
    }
}
