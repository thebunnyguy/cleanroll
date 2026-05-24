import SwiftUI

/// Scrollable grid of media thumbnails with lazy loading.
struct MediaGridView: View {
    @Bindable var viewModel: LibraryViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.displayedItems, id: \.localIdentifier) { item in
                    MediaGridCell(
                        item: item,
                        isSelected: viewModel.selectedIdentifiers.contains(item.localIdentifier),
                        isSelecting: viewModel.isSelecting,
                        onTap: {
                            handleTap(item: item)
                        }
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Tap Handling

    private func handleTap(item: MediaItem) {
        if viewModel.isSelecting {
            viewModel.toggleSelection(for: item.localIdentifier)
        } else {
            // Navigate to detail view (handled via navigation in ContentView)
            viewModel.selectedDetailItem = item
        }
    }
}
