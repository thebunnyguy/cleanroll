# CleanRoll

> **Sort your iPhone photos and videos by file size. Reclaim storage in seconds.**

The native iOS Photos app has no way to sort media by file size. CleanRoll fixes that — scan your entire library, see exactly what's eating your storage, and delete the biggest offenders in bulk.

---

## Screenshots

| Permission | Scanning | Grid (Sorted by Size) | Detail View |
|---|---|---|---|
| *Grant access screen* | *Progress banner* | *3-column square grid* | *Full metadata card* |

---

## Features

- 📦 **Sort by file size** — largest first, smallest first
- 📅 **Sort by date** — newest or oldest
- 🎬 **Sort by video duration** — longest first
- 🔍 **Filter by type** — Photos, Videos, Screenshots, Screen Recordings
- 🗂 **Multi-select** — tap Select, pick items, see accumulated size
- 🗑 **Batch delete** — with native iOS confirmation sheet
- ☁️ **iCloud-aware** — shows cloud badge for off-device assets, no forced downloads
- 📐 **Rich metadata** — file size, resolution, megapixels, duration, date, category
- ⚡ **Fast scanning** — background queue with live progress bar
- 🖼 **Smooth grid** — lazy thumbnails with PHCachingImageManager, cancel on scroll

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Photo access | PhotoKit — `PHAsset`, `PHAssetResource` |
| Thumbnails | `PHCachingImageManager` |
| State management | `@Observable` (Swift Observation framework) |
| File size estimation | `PHAssetResource.value(forKey: "fileSize")` |
| Architecture | MVVM + Services |

---

## Architecture

```
CleanRoll/
├── CleanRollApp.swift              # App entry point
│
├── Models/
│   └── MediaItem.swift             # Value type holding scanned metadata
│
├── Services/
│   ├── PhotoLibraryService.swift   # PhotoKit: permissions, scan, delete
│   └── ThumbnailService.swift      # PHCachingImageManager wrapper
│
├── ViewModels/
│   └── LibraryViewModel.swift      # @Observable VM: sort, filter, select, delete
│
├── Views/
│   ├── ContentView.swift           # Root: permission gate + scan lifecycle
│   ├── MediaGridView.swift         # LazyVGrid (3-column, square tiles)
│   ├── MediaGridCell.swift         # Thumbnail + file size / duration badges
│   ├── FilterSortBar.swift         # Filter chips + sort dropdown
│   ├── StorageFooterView.swift     # Selection count + total size + delete
│   └── MediaDetailView.swift       # Full-res preview + metadata card
│
└── Utilities/
    ├── ByteFormatter.swift         # "24.3 MB" string formatting
    └── DurationFormatter.swift     # "1:32" / "5 min 4 sec" formatting
```

---

## How File Size Works

iOS does not expose a public `fileSize` property on `PHAsset`. CleanRoll uses the community-standard, App Store-safe approach:

```swift
let resources = PHAssetResource.assetResources(for: asset)
let size = resource.value(forKey: "fileSize") as? Int64 ?? 0
```

This uses KVC on `PHAssetResource` — it does not access private frameworks and has shipped in production apps for years without App Store rejection. For **Live Photos**, all resources (JPEG + MOV) are summed for the total size.

---

## Requirements

- **iOS 17.0+**
- **Xcode 15+**
- A physical iPhone or iPad (or Simulator with a populated Photos library)
- An Apple Developer account (free Personal Team works for device testing)

---

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/yourusername/cleanroll.git
cd cleanroll
```

### 2. Open in Xcode

```bash
open CleanRoll.xcodeproj
```

### 3. Configure signing

1. Select the **CleanRoll** target in Xcode
2. Go to **Signing & Capabilities**
3. Set your **Team** (Apple ID)
4. Set a unique **Bundle Identifier** — e.g. `com.yourname.cleanroll`
5. Enable **Automatically manage signing**

### 4. Run on device

Connect your iPhone, select it in Xcode, press **⌘R**.

On first install with a free Apple ID, go to:
> **Settings → General → VPN & Device Management → [Your Apple ID] → Trust**

Then press **⌘R** again.

---

## Permissions

CleanRoll requires the following Info.plist keys:

| Key | Purpose |
|---|---|
| `NSPhotoLibraryUsageDescription` | Explain why the app reads the photo library |
| `NSPhotoLibraryAddUsageDescription` | Explain why the app can delete/modify assets |

These are set automatically via `INFOPLIST_KEY_*` build settings in the Xcode project.

---

## Troubleshooting Common Errors

### 1. Provisioning / Signing Errors
**Error:** `"Failed Registering Bundle Identifier: The app identifier 'com.cleanroll.app' cannot be registered..."` or `"No profiles for 'com.cleanroll.app' were found..."`

**Root Cause:** Bundle Identifiers must be globally unique across all Apple Developer accounts. Someone else (or another team) has already registered `com.cleanroll.app`.

**Resolution:**
1. In Xcode, select the **CleanRoll** target and go to the **Signing & Capabilities** tab.
2. Change the **Bundle Identifier** to something unique to you (e.g., `com.yourname.cleanroll`).
3. Ensure your Apple ID is selected under **Team** (a Personal Team is fine).
4. Make sure **"Automatically manage signing"** is checked.
5. If prompted, click "Try Again" to generate the provisioning profile.

### 2. "Could not launch" Error on Device
**Error:** Xcode builds the app successfully but fails to launch it on your connected iPhone.

**Resolution:**
1. Ensure your iPhone is unlocked and on the home screen when you press Run.
2. If this is your first time deploying to this device with your Apple ID, you must trust the developer certificate. On your iPhone, go to **Settings → General → VPN & Device Management → [Your Apple ID]**, and tap **Trust**.
3. *For iOS 16+ devices:* Ensure **Developer Mode** is turned on in **Settings → Privacy & Security → Developer Mode**.

---

## Sorting Options

| Sort | Description |
|---|---|
| Largest First | Find the biggest files eating your storage |
| Smallest First | Find tiny duplicates or stray thumbnails |
| Newest | Most recently captured |
| Oldest | Oldest media in your library |
| Longest Video | Find long screen recordings or exports |

## Filter Options

| Filter | Shows |
|---|---|
| All | Everything in your library |
| Photos | Images only |
| Videos | Videos only |
| Screenshots | `PHAssetMediaSubtype.photoScreenshot` |
| Recordings | `PHAssetMediaSubtype.videoScreenRecording` |

---

## Known Limitations

- **iCloud-only assets**: File size is reported correctly (PhotoKit knows the cloud size), but the full image is not downloaded when browsing the grid. It downloads on demand in the detail view.
- **Exact vs. estimated size**: `PHAssetResource.value(forKey: "fileSize")` returns the stored size, which may differ slightly from the actual file exported to disk in some edge cases (e.g., HEIC with adjustments).
- **iOS 17 minimum**: Uses `@Observable` and other Swift 5.9 APIs. For iOS 16 support, refactor `LibraryViewModel` to use `@ObservableObject + @Published`.
- **Free developer account**: Apps expire after 7 days. Re-run from Xcode to reinstall.

---

## Roadmap

- [ ] Persist scan results — instant re-launch without re-scanning
- [ ] Incremental scan — only process new/changed assets
- [ ] Duplicate detection — by dimensions or perceptual hash
- [ ] Video playback in detail view
- [ ] Storage savings summary — "You freed X MB!"
- [ ] Share / export selected items
- [ ] iPad layout with sidebar

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Contributing

Pull requests are welcome. For any changes, open an issue first to discuss what you'd like to change.

---

*Built with SwiftUI + PhotoKit. No third-party dependencies.*
