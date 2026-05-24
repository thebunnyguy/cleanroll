import Foundation
import Photos
import UIKit

/// Wraps all PhotoKit interactions: permissions, fetching, metadata extraction, deletion.
/// All heavy work runs on background queues to keep the UI responsive.
final class PhotoLibraryService {

    // MARK: - Authorization

    /// Requests read-write photo library access. Returns the resulting status.
    static func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Returns the current authorization status without prompting.
    static var currentAuthorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - Fetch All Assets

    /// Fetches every PHAsset in the library, ordered by creation date (newest first).
    static func fetchAllAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeHiddenAssets = false
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
        return PHAsset.fetchAssets(with: options)
    }

    // MARK: - Metadata Extraction

    /// Extracts all relevant metadata from a single PHAsset and builds a MediaItem.
    /// This should be called from a background queue for bulk scanning.
    static func extractMetadata(from asset: PHAsset) -> MediaItem {
        // --- File size via PHAssetResource ---
        let resources = PHAssetResource.assetResources(for: asset)
        var totalSize: Int64 = 0
        for resource in resources {
            if let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
                totalSize += size
            } else if let size = resource.value(forKey: "fileSize") as? CLong {
                totalSize += Int64(size)
            }
        }

        // --- iCloud detection ---
        // An asset is "cloud-only" if its primary resource would require network access.
        let isCloudOnly: Bool = {
            // If there are no local resources at all, it's iCloud-only
            guard let primaryResource = resources.first else { return false }
            // Check if the resource is currently available locally
            // We use a simple heuristic: if fileSize is 0 and the asset exists, it may be iCloud
            // More reliable: check sourceType
            return asset.sourceType.contains(.typeCloudShared)
        }()

        // --- Classification ---
        let isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
        let isScreenRecording: Bool = {
            if #available(iOS 15.0, *) {
                return asset.mediaSubtypes.contains(.videoScreenRecording)
            }
            // Fallback: raw value 524288 matches .videoScreenRecording
            return asset.mediaSubtypes.rawValue & 524288 != 0
        }()

        return MediaItem(
            localIdentifier: asset.localIdentifier,
            mediaTypeRaw: asset.mediaType.rawValue,
            creationDate: asset.creationDate,
            duration: asset.duration,
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            fileSize: totalSize,
            isScreenshot: isScreenshot,
            isScreenRecording: isScreenRecording,
            isFavorite: asset.isFavorite,
            isCloudOnly: isCloudOnly
        )
    }

    // MARK: - Full Library Scan

    /// Scans the entire photo library. Reports progress via callback.
    /// Returns an array of MediaItems with all metadata extracted.
    ///
    /// - Parameter progress: Called with (completed, total) on each batch.
    /// - Returns: Array of all scanned MediaItems.
    static func scanLibrary(
        progress: @escaping @Sendable (_ completed: Int, _ total: Int) -> Void
    ) async -> [MediaItem] {
        let fetchResult = fetchAllAssets()
        let total = fetchResult.count

        guard total > 0 else { return [] }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var items: [MediaItem] = []
                items.reserveCapacity(total)

                let batchSize = 100
                var completed = 0

                fetchResult.enumerateObjects { asset, index, _ in
                    let item = extractMetadata(from: asset)
                    items.append(item)

                    completed += 1
                    if completed % batchSize == 0 || completed == total {
                        let c = completed
                        progress(c, total)
                    }
                }

                continuation.resume(returning: items)
            }
        }
    }

    // MARK: - Deletion

    /// Requests deletion of assets with the given local identifiers.
    /// iOS will show the system confirmation dialog.
    /// - Returns: `true` if the deletion was performed successfully.
    @discardableResult
    static func deleteAssets(identifiers: [String]) async throws -> Bool {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: identifiers,
            options: nil
        )

        guard fetchResult.count > 0 else { return false }

        try await PHPhotoLibrary.shared().performChanges {
            let assets = NSMutableArray()
            fetchResult.enumerateObjects { asset, _, _ in
                assets.add(asset)
            }
            PHAssetChangeRequest.deleteAssets(assets)
        }

        return true
    }

    // MARK: - Fetch Single Asset

    /// Fetches a single PHAsset by its localIdentifier.
    static func fetchAsset(identifier: String) -> PHAsset? {
        let result = PHAsset.fetchAssets(
            withLocalIdentifiers: [identifier],
            options: nil
        )
        return result.firstObject
    }
}
