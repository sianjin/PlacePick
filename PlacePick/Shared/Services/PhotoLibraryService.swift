import SwiftUI
import Photos
import PhotosUI

/// Resolves PhotosPicker selections into PhotoImportCandidates. PlacePick is a personal
/// memory layer, not a photo library — image bytes are never copied into app storage.
/// Only the Photos-library asset identifier is kept; PhotoAssetThumbnailView looks up the
/// actual image from Photos on demand, through a small bounded cache for scroll
/// performance (see PhotoThumbnailCache).
///
/// PHAsset lookup provides capture time/GPS when available; EXIF read from the picked
/// image data is used only as a metadata fallback when PHAsset lacks a creationDate
/// (e.g. limited-library edge cases) — it never substitutes for the asset identifier
/// itself. See DATA_MODEL.md §8.2 "capturedAt": PlacePick must not substitute import or
/// current time when reliable capture time is unavailable — items with no resolvable
/// date from either source are dropped, not defaulted.
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

            if capturedAt == nil, let data = try? await item.loadTransferable(type: Data.self) {
                let exif = await PhotoMetadataExtractor.extractMetadata(from: data)
                capturedAt = capturedAt ?? exif.capturedAt
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
