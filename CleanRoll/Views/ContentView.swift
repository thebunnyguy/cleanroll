import SwiftUI

/// Root view. Handles permission gating, scan lifecycle, and main navigation.
struct ContentView: View {
    @State private var viewModel = LibraryViewModel()

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            Group {
                switch viewModel.permissionState {
                case .unknown:
                    permissionRequestView

                case .authorized, .limited:
                    mainLibraryView

                case .denied, .restricted:
                    permissionDeniedView
                }
            }
            .navigationTitle("CleanRoll")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .sheet(item: $vm.selectedDetailItem) { item in
                NavigationStack {
                    MediaDetailView(item: item)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    viewModel.selectedDetailItem = nil
                                }
                            }
                        }
                }
            }
            .alert("Delete Items?",
                   isPresented: $vm.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete \(viewModel.selectedCount) Items", role: .destructive) {
                    Task { await viewModel.deleteSelectedItems() }
                }
            } message: {
                Text("This will delete \(viewModel.selectedCount) items (\(ByteFormatter.string(fromBytes: viewModel.selectedTotalSize))). This action cannot be undone.")
            }
            .alert("Error",
                   isPresented: .init(
                       get: { viewModel.errorMessage != nil },
                       set: { if !$0 { viewModel.errorMessage = nil } }
                   )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Main Library View

    private var mainLibraryView: some View {
        VStack(spacing: 0) {
            // Scan state banner
            if viewModel.scanState.isScanning {
                scanProgressBanner
            }

            // Summary bar
            if case .completed = viewModel.scanState {
                summaryBar
            }

            // Filter + Sort bar
            if !viewModel.allItems.isEmpty {
                FilterSortBar(viewModel: viewModel)
            }

            // Grid
            if viewModel.allItems.isEmpty && !viewModel.scanState.isScanning {
                emptyStateView
            } else {
                MediaGridView(viewModel: viewModel)
            }

            // Selection footer
            StorageFooterView(viewModel: viewModel)
                .animation(.easeInOut(duration: 0.25), value: viewModel.isSelecting)
        }
        .task {
            if case .idle = viewModel.scanState {
                await viewModel.startScan()
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.permissionState == .authorized || viewModel.permissionState == .limited {
                HStack(spacing: 12) {
                    // Rescan button
                    Button {
                        Task { await viewModel.startScan() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.scanState.isScanning)

                    // Select mode toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.isSelecting.toggle()
                        }
                    } label: {
                        Text(viewModel.isSelecting ? "Done" : "Select")
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }

    // MARK: - Permission Request View

    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 8) {
                Text("Photo Library Access")
                    .font(.title2.weight(.bold))

                Text("CleanRoll needs access to your photos to scan for large files and help you free up storage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                Task { await viewModel.requestPermission() }
            } label: {
                Text("Grant Access")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Access Denied")
                .font(.title2.weight(.bold))

            Text("Please enable photo library access in Settings to use CleanRoll.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No media found")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Your photo library appears to be empty.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    // MARK: - Scan Progress Banner

    private var scanProgressBanner: some View {
        VStack(spacing: 6) {
            if case .scanning(let completed, let total) = viewModel.scanState {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning… \(completed) of \(total)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(viewModel.scanState.progress * 100))%")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: viewModel.scanState.progress)
                    .tint(Color.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.librarySummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(ByteFormatter.string(fromBytes: viewModel.totalLibrarySize))
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(.systemGray6).opacity(0.5))
    }
}

#Preview {
    ContentView()
}
