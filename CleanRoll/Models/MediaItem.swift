import Foundation
import Photos

// MARK: - Media Type Enum

enum MediaType: Int, CaseIterable, Identifiable, Sendable {
    case image = 1
    case video = 2
    case unknown = 0

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .image: "Photo"
        case .video: "Video"
        case .unknown: "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .image: "photo"
        case .video: "video"
        case .unknown: "questionmark"
        }
    }
}

// MARK: - MediaItem

/// Lightweight value type holding cached metadata for a single PHAsset.
/// Stored in-memory; future version can persist to SwiftData for instant re-launch.
struct MediaItem: Identifiable, Hashable, Sendable {
    // MARK: Identity
    let localIdentifier: String
    var id: String { localIdentifier }

    // MARK: Core Metadata
    /// Raw value of `PHAssetMediaType` — 1 = image, 2 = video.
    let mediaTypeRaw: Int

    let creationDate: Date?

    /// Duration in seconds. 0 for photos.
    let duration: Double

    let pixelWidth: Int
    let pixelHeight: Int

    /// Estimated file size in bytes. 0 means unknown / couldn't be read.
    let fileSize: Int64

    // MARK: Classification
    let isScreenshot: Bool
    let isScreenRecording: Bool
    let isFavorite: Bool

    /// True when the asset's full data is not available locally (iCloud-only).
    let isCloudOnly: Bool

    // MARK: Housekeeping
    /// Timestamp of the last scan that touched this item.
    let lastScannedAt: Date

    // MARK: Computed
    var mediaType: MediaType {
        MediaType(rawValue: mediaTypeRaw) ?? .unknown
    }

    var megapixels: Double {
        Double(pixelWidth * pixelHeight) / 1_000_000.0
    }

    var resolution: String {
        "\(pixelWidth) × \(pixelHeight)"
    }

    // MARK: Init
    init(
        localIdentifier: String,
        mediaTypeRaw: Int,
        creationDate: Date?,
        duration: Double,
        pixelWidth: Int,
        pixelHeight: Int,
        fileSize: Int64,
        isScreenshot: Bool,
        isScreenRecording: Bool,
        isFavorite: Bool,
        isCloudOnly: Bool,
        lastScannedAt: Date = .now
    ) {
        self.localIdentifier = localIdentifier
        self.mediaTypeRaw = mediaTypeRaw
        self.creationDate = creationDate
        self.duration = duration
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.fileSize = fileSize
        self.isScreenshot = isScreenshot
        self.isScreenRecording = isScreenRecording
        self.isFavorite = isFavorite
        self.isCloudOnly = isCloudOnly
        self.lastScannedAt = lastScannedAt
    }
}
