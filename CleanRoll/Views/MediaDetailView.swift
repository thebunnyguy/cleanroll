import SwiftUI
import Photos

/// Full-size media preview with complete metadata display.
struct MediaDetailView: View {
    let item: MediaItem
    @State private var fullImage: UIImage?
    @State private var isLoadingImage = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Image / Video Preview
                ZStack {
                    if let fullImage {
                        Image(uiImage: fullImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 300)
                            .overlay {
                                if isLoadingImage {
                                    ProgressView("Loading…")
                                        .tint(.secondary)
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "icloud.and.arrow.down")
                                            .font(.largeTitle)
                                            .foregroundStyle(.secondary)
                                        Text("iCloud Only")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                    }

                    // Video play icon overlay
                    if item.mediaType == .video {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.white.opacity(0.85))
                            .shadow(radius: 8)
                    }
                }

                // MARK: - Metadata Card
                VStack(spacing: 0) {
                    metadataSection
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFullImage()
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(spacing: 0) {
            // File Size — hero stat
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("File Size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(ByteFormatter.string(fromBytes: item.fileSize))
                        .font(.title2.weight(.bold).monospacedDigit())
                }
                Spacer()
                Image(systemName: item.mediaType == .video ? "video.fill" : "photo.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .padding()
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Grid of metadata rows
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                if item.mediaType == .video {
                    MetadataCell(
                        label: "Duration",
                        value: DurationFormatter.descriptiveString(from: item.duration),
                        icon: "timer"
                    )
                }

                MetadataCell(
                    label: "Resolution",
                    value: item.resolution,
                    icon: "rectangle.split.3x3"
                )

                MetadataCell(
                    label: "Megapixels",
                    value: String(format: "%.1f MP", item.megapixels),
                    icon: "camera.metering.matrix"
                )

                if let date = item.creationDate {
                    MetadataCell(
                        label: "Date",
                        value: date.formatted(date: .abbreviated, time: .shortened),
                        icon: "calendar"
                    )
                }

                MetadataCell(
                    label: "Type",
                    value: item.mediaType.label,
                    icon: item.mediaType.systemImage
                )

                if item.isScreenshot {
                    MetadataCell(
                        label: "Category",
                        value: "Screenshot",
                        icon: "camera.viewfinder"
                    )
                }

                if item.isScreenRecording {
                    MetadataCell(
                        label: "Category",
                        value: "Screen Recording",
                        icon: "record.circle"
                    )
                }

                if item.isFavorite {
                    MetadataCell(
                        label: "Favorite",
                        value: "Yes",
                        icon: "heart.fill"
                    )
                }

                if item.isCloudOnly {
                    MetadataCell(
                        label: "Storage",
                        value: "iCloud Only",
                        icon: "icloud"
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Load Full Image

    private func loadFullImage() async {
        guard let asset = PhotoLibraryService.fetchAsset(identifier: item.localIdentifier) else {
            isLoadingImage = false
            return
        }

        let screenWidth = UIScreen.main.bounds.width
        let targetSize = CGSize(
            width: screenWidth * UIScreen.main.scale,
            height: screenWidth * UIScreen.main.scale
        )

        let image = await ThumbnailService.shared.requestFullImage(
            for: asset,
            targetSize: targetSize
        )

        fullImage = image
        isLoadingImage = false
    }
}

// MARK: - MetadataCell

private struct MetadataCell: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }
}
