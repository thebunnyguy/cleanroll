import SwiftUI
import Photos

/// A single grid cell displaying a thumbnail with overlay badges for
/// file size, video duration, and selection state.
struct MediaGridCell: View {
    let item: MediaItem
    let isSelected: Bool
    let isSelecting: Bool
    let onTap: () -> Void

    @State private var thumbnail: UIImage?
    @State private var requestID: PHImageRequestID?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // MARK: Thumbnail
            thumbnailView
                .clipped()

            // MARK: Gradient Overlay (bottom)
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            // MARK: Bottom Badges
            HStack(spacing: 4) {
                // File size badge
                Text(ByteFormatter.compactString(fromBytes: item.fileSize))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                // Video duration badge
                if item.mediaType == .video {
                    HStack(spacing: 2) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 7))
                        Text(DurationFormatter.compactString(from: item.duration))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                }

                // Screenshot badge
                if item.isScreenshot {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                }

                // iCloud badge
                if item.isCloudOnly {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 5)

            // MARK: Selection Checkmark
            if isSelecting {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.blue : Color.white.opacity(0.3))
                                .frame(width: 24, height: 24)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 1.5)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(6)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isSelected ? Color.blue : Color.clear,
                    lineWidth: isSelected ? 3 : 0
                )
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .task(id: item.localIdentifier) {
            await loadThumbnail()
        }
        .onDisappear {
            if let requestID {
                ThumbnailService.shared.cancelRequest(requestID)
            }
            thumbnail = nil
        }
    }

    // MARK: - Thumbnail View

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay {
                    ProgressView()
                        .tint(.secondary)
                }
        }
    }

    // MARK: - Load Thumbnail

    private func loadThumbnail() async {
        guard let asset = await fetchAsset() else { return }

        let id = ThumbnailService.shared.requestThumbnail(for: asset) { image in
            Task { @MainActor in
                self.thumbnail = image
            }
        }
        self.requestID = id
    }

    private func fetchAsset() async -> PHAsset? {
        PhotoLibraryService.fetchAsset(identifier: item.localIdentifier)
    }
}

#Preview {
    let sample = MediaItem(
        localIdentifier: "test-1",
        mediaTypeRaw: 2,
        creationDate: .now,
        duration: 125,
        pixelWidth: 1920,
        pixelHeight: 1080,
        fileSize: 45_000_000,
        isScreenshot: false,
        isScreenRecording: false,
        isFavorite: false,
        isCloudOnly: false
    )

    MediaGridCell(
        item: sample,
        isSelected: true,
        isSelecting: true,
        onTap: {}
    )
    .frame(width: 120, height: 120)
    .padding()
}

