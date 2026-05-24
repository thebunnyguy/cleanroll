import SwiftUI

/// Bottom bar showing selection count, total size, and delete button.
struct StorageFooterView: View {
    @Bindable var viewModel: LibraryViewModel

    var body: some View {
        if viewModel.isSelecting {
            HStack(spacing: 16) {
                // MARK: Selection Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.selectedCount) selected")
                        .font(.subheadline.weight(.semibold))

                    if viewModel.selectedCount > 0 {
                        Text(ByteFormatter.string(fromBytes: viewModel.selectedTotalSize))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // MARK: Select All / Deselect
                Button {
                    if viewModel.selectedCount == viewModel.displayedItems.count {
                        viewModel.deselectAll()
                    } else {
                        viewModel.selectAll()
                    }
                } label: {
                    Text(viewModel.selectedCount == viewModel.displayedItems.count
                         ? "Deselect All" : "Select All")
                        .font(.subheadline.weight(.medium))
                }

                // MARK: Delete Button
                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedCount > 0
                                ? Color.red
                                : Color.gray.opacity(0.4),
                            in: Capsule()
                        )
                }
                .disabled(viewModel.selectedCount == 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview {
    StorageFooterView(viewModel: {
        let vm = LibraryViewModel()
        vm.isSelecting = true
        return vm
    }())
}
