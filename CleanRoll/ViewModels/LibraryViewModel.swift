import Foundation
import Photos
import Observation

// MARK: - Sort Option

enum SortOption: String, CaseIterable, Identifiable {
    case largestFirst = "Largest First"
    case smallestFirst = "Smallest First"
    case newest = "Newest"
    case oldest = "Oldest"
    case longestVideo = "Longest Video"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .largestFirst: "arrow.down.circle"
        case .smallestFirst: "arrow.up.circle"
        case .newest: "calendar.badge.clock"
        case .oldest: "calendar"
        case .longestVideo: "timer"
        }
    }
}

// MARK: - Filter Option

enum FilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case photosOnly = "Photos"
    case videosOnly = "Videos"
    case screenshots = "Screenshots"
    case screenRecordings = "Recordings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all: "square.grid.2x2"
        case .photosOnly: "photo"
        case .videosOnly: "video"
        case .screenshots: "camera.viewfinder"
        case .screenRecordings: "record.circle"
        }
    }
}

// MARK: - Scan State

enum ScanState: Equatable {
    case idle
    case scanning(completed: Int, total: Int)
    case completed(count: Int)
    case error(String)

    var isScanning: Bool {
        if case .scanning = self { return true }
        return false
    }

    var progress: Double {
        if case .scanning(let completed, let total) = self, total > 0 {
            return Double(completed) / Double(total)
        }
        return 0
    }
}

// MARK: - Permission State

enum PermissionState {
    case unknown
    case authorized
    case limited
    case denied
    case restricted
}

// MARK: - LibraryViewModel

@Observable
@MainActor
final class LibraryViewModel {

    // MARK: - Published State

    /// All scanned items (unsorted, unfiltered source of truth).
    private(set) var allItems: [MediaItem] = []

    /// Displayed items after applying current sort + filter.
    private(set) var displayedItems: [MediaItem] = []

    /// Current scan state.
    private(set) var scanState: ScanState = .idle

    /// Photo library permission state.
    private(set) var permissionState: PermissionState = .unknown

    /// Current sort selection.
    var sortOption: SortOption = .largestFirst {
        didSet { applyFiltersAndSort() }
    }

    /// Current filter selection.
    var filterOption: FilterOption = .all {
        didSet { applyFiltersAndSort() }
    }

    /// Set of selected item identifiers.
    var selectedIdentifiers: Set<String> = []

    /// Whether multi-select mode is active.
    var isSelecting: Bool = false {
        didSet {
            if !isSelecting { selectedIdentifiers.removeAll() }
        }
    }

    /// Controls the delete confirmation alert.
    var showDeleteConfirmation: Bool = false

    /// Error message to display in alert.
    var errorMessage: String?

    /// Item selected for detail view navigation.
    var selectedDetailItem: MediaItem?

    // MARK: - PHAsset Lookup Cache
    /// Cached PHFetchResult for quick PHAsset lookups (thumbnails, deletion).
    private var fetchResult: PHFetchResult<PHAsset>?

    // MARK: - Computed Properties

    /// Total file size of selected items.
    var selectedTotalSize: Int64 {
        allItems
            .filter { selectedIdentifiers.contains($0.localIdentifier) }
            .reduce(0) { $0 + $1.fileSize }
    }

    /// Number of selected items.
    var selectedCount: Int { selectedIdentifiers.count }

    /// Total file size of all scanned items.
    var totalLibrarySize: Int64 {
        allItems.reduce(0) { $0 + $1.fileSize }
    }

    /// Total count summary.
    var librarySummary: String {
        let photos = allItems.filter { $0.mediaType == .image }.count
        let videos = allItems.filter { $0.mediaType == .video }.count
        return "\(photos) photos · \(videos) videos"
    }

    // MARK: - Initialization

    init() {
        checkPermission()
    }

    // MARK: - Permission

    func checkPermission() {
        let status = PhotoLibraryService.currentAuthorizationStatus
        permissionState = mapStatus(status)
    }

    func requestPermission() async {
        let status = await PhotoLibraryService.requestAuthorization()
        permissionState = mapStatus(status)
    }

    private func mapStatus(_ status: PHAuthorizationStatus) -> PermissionState {
        switch status {
        case .authorized: .authorized
        case .limited: .limited
        case .denied: .denied
        case .restricted: .restricted
        case .notDetermined: .unknown
        @unknown default: .unknown
        }
    }

    // MARK: - Scanning

    func startScan() async {
        guard !scanState.isScanning else { return }
        scanState = .scanning(completed: 0, total: 0)

        let items = await PhotoLibraryService.scanLibrary { [weak self] completed, total in
            Task { @MainActor in
                self?.scanState = .scanning(completed: completed, total: total)
            }
        }

        allItems = items
        fetchResult = PhotoLibraryService.fetchAllAssets()
        applyFiltersAndSort()
        scanState = .completed(count: items.count)
    }

    // MARK: - Sorting & Filtering

    func applyFiltersAndSort() {
        var items = allItems

        // --- Filter ---
        switch filterOption {
        case .all:
            break
        case .photosOnly:
            items = items.filter { $0.mediaType == .image }
        case .videosOnly:
            items = items.filter { $0.mediaType == .video }
        case .screenshots:
            items = items.filter { $0.isScreenshot }
        case .screenRecordings:
            items = items.filter { $0.isScreenRecording }
        }

        // --- Sort ---
        switch sortOption {
        case .largestFirst:
            items.sort { $0.fileSize > $1.fileSize }
        case .smallestFirst:
            items.sort { $0.fileSize < $1.fileSize }
        case .newest:
            items.sort { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        case .oldest:
            items.sort { ($0.creationDate ?? .distantFuture) < ($1.creationDate ?? .distantFuture) }
        case .longestVideo:
            items.sort { $0.duration > $1.duration }
        }

        displayedItems = items
    }

    // MARK: - Selection

    func toggleSelection(for identifier: String) {
        if selectedIdentifiers.contains(identifier) {
            selectedIdentifiers.remove(identifier)
        } else {
            selectedIdentifiers.insert(identifier)
        }
    }

    func selectAll() {
        selectedIdentifiers = Set(displayedItems.map(\.localIdentifier))
    }

    func deselectAll() {
        selectedIdentifiers.removeAll()
    }

    // MARK: - Deletion

    func deleteSelectedItems() async {
        let idsToDelete = Array(selectedIdentifiers)
        guard !idsToDelete.isEmpty else { return }

        do {
            try await PhotoLibraryService.deleteAssets(identifiers: idsToDelete)

            // Remove from local state
            allItems.removeAll { idsToDelete.contains($0.localIdentifier) }
            selectedIdentifiers.removeAll()
            isSelecting = false
            applyFiltersAndSort()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }

    // MARK: - PHAsset Access

    /// Returns the PHAsset for a given localIdentifier (for thumbnail loading).
    func phAsset(for identifier: String) -> PHAsset? {
        // Fast path: use the cached fetch result
        if let fetchResult {
            var found: PHAsset?
            fetchResult.enumerateObjects { asset, _, stop in
                if asset.localIdentifier == identifier {
                    found = asset
                    stop.pointee = true
                }
            }
            if let found { return found }
        }
        // Fallback: direct fetch
        return PhotoLibraryService.fetchAsset(identifier: identifier)
    }

    /// Returns a dictionary mapping localIdentifier → PHAsset for a batch.
    /// More efficient than individual lookups.
    func phAssets(for identifiers: [String]) -> [String: PHAsset] {
        let result = PHAsset.fetchAssets(
            withLocalIdentifiers: identifiers,
            options: nil
        )
        var map: [String: PHAsset] = [:]
        result.enumerateObjects { asset, _, _ in
            map[asset.localIdentifier] = asset
        }
        return map
    }
}
