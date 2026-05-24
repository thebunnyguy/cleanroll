import Photos
import UIKit

/// Efficient thumbnail delivery using PHCachingImageManager.
/// Manages a sliding cache window for smooth grid scrolling.
final class ThumbnailService: @unchecked Sendable {

    // MARK: - Singleton
    @MainActor
    static let shared = ThumbnailService()

    // MARK: - Private
    private let cachingManager = PHCachingImageManager()
    private let requestOptions: PHImageRequestOptions = {
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .fastFormat
        opts.resizeMode = .fast
        opts.isNetworkAccessAllowed = false   // Don't download from iCloud for thumbnails
        opts.isSynchronous = false
        return opts
    }()

    private init() {
        cachingManager.allowsCachingHighQualityImages = false
    }

    // MARK: - Standard Thumbnail Size
    /// Grid cell thumbnail size (3 columns on a typical screen).
    static let thumbnailSize = CGSize(width: 240, height: 240)

    // MARK: - Request Single Thumbnail (Callback)

    /// Requests a thumbnail using a callback. Returns the request ID for cancellation.
    /// The completion handler may be called multiple times (degraded then full quality).
    func requestThumbnail(
        for asset: PHAsset,
        targetSize: CGSize = ThumbnailService.thumbnailSize,
        completion: @escaping @Sendable (UIImage?) -> Void
    ) -> PHImageRequestID {
        cachingManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        ) { image, _ in
            // Accept any image (even degraded) for grid display
            if let image {
                completion(image)
            }
        }
    }

    /// Cancels a pending thumbnail request.
    func cancelRequest(_ requestID: PHImageRequestID) {
        cachingManager.cancelImageRequest(requestID)
    }

    // MARK: - Full-Size Image

    /// Requests a full-resolution image for the detail view.
    func requestFullImage(
        for asset: PHAsset,
        targetSize: CGSize
    ) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true  // Allow iCloud download for detail view
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            var hasResumed = false
            cachingManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                // Only resume once, when we get the non-degraded result
                if !isDegraded && !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }

    // MARK: - Cache Management

    /// Pre-warms the cache for a batch of assets (call when new rows appear).
    func startCaching(
        assets: [PHAsset],
        targetSize: CGSize = ThumbnailService.thumbnailSize
    ) {
        cachingManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        )
    }

    /// Clears the cache for assets that scrolled off-screen.
    func stopCaching(
        assets: [PHAsset],
        targetSize: CGSize = ThumbnailService.thumbnailSize
    ) {
        cachingManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        )
    }

    /// Resets the entire cache. Call on memory warnings or significant library changes.
    func resetCache() {
        cachingManager.stopCachingImagesForAllAssets()
    }
}
