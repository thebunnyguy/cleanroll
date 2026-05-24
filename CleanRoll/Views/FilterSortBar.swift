import SwiftUI

/// Sort picker and horizontal filter chips.
struct FilterSortBar: View {
    @Bindable var viewModel: LibraryViewModel

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FilterOption.allCases) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            systemImage: filter.systemImage,
                            isActive: viewModel.filterOption == filter,
                            action: { viewModel.filterOption = filter }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider()
                .opacity(0.4)

            // MARK: - Sort Row
            HStack {
                Text("\(viewModel.displayedItems.count) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if viewModel.displayedItems.count != viewModel.allItems.count {
                    Text("of \(viewModel.allItems.count)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Menu {
                    ForEach(SortOption.allCases) { sort in
                        Button {
                            viewModel.sortOption = sort
                        } label: {
                            Label(sort.rawValue, systemImage: sort.systemImage)
                            if viewModel.sortOption == sort {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.sortOption.systemImage)
                        Text(viewModel.sortOption.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                isActive
                    ? AnyShapeStyle(Color.blue)
                    : AnyShapeStyle(.ultraThinMaterial)
            )
            .foregroundStyle(isActive ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? Color.clear : Color.primary.opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

#Preview {
    FilterSortBar(viewModel: LibraryViewModel())
}
