import SwiftUI

/// A saved list's detail: back / sort / more chrome, the list name + description,
/// then a vertical feed of `SpotCard`s (reused from Explore). Pushed onto the
/// Saved tab's stack.
struct SavedListDetailScreen: View {
    let list: SavedList

    @State private var detailVM: SavedListDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(SavedStore.self) private var store
    /// Optional so previews (which don't inject them) don't crash.
    @Environment(TabBarVisibility.self) private var tabBarVisibility: TabBarVisibility?
    @Environment(TabRouter.self) private var router: TabRouter?

    @State private var saveTarget: SpotSummary?
    @State private var sort: SavedSpotSort = .recentlyAdded
    @State private var showSort = false
    @State private var showMap = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var actionError: String?
    /// Measured height of the floating top bar, used to inset the scroll content
    /// so the header clears the overlay (replaces the old `safeAreaInset`).
    @State private var topBarHeight: CGFloat = 0

    init(list: SavedList, service: SavedListService = AppServices.savedLists) {
        self.list = list
        _detailVM = State(initialValue: SavedListDetailViewModel(listID: list.id, service: service))
    }

    /// The live list from the store (so edits show immediately); falls back to the
    /// value we were pushed with, e.g. during the delete dismiss.
    private var currentList: SavedList {
        store.lists.first { $0.id == list.id } ?? list
    }

    private var sortedSpots: [SpotSummary] { sort.sorted(detailVM.spots) }

    /// The list is loaded and actually has spots — gates the floating Map button.
    private var hasSpots: Bool {
        detailVM.state == .loaded && !detailVM.spots.isEmpty
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.sBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    feed
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, topBarHeight + Spacing.sm)
                // Extra bottom room so the last card clears the floating Map button.
                .padding(.bottom, hasSpots ? Spacing.xxxl + Spacing.lg : Spacing.xl)
            }
        }
        .overlay(alignment: .bottom) {
            if hasSpots {
                SMapButton { showMap = true }
                    .padding(.bottom, Spacing.lg)
            }
        }
        .overlay(alignment: .top) {
            SavedListControls(
                showsMenu: !currentList.isSystem,
                onBack: { dismiss() },
                onSort: { showSort = true },
                onEdit: { showEdit = true },
                onDelete: { showDeleteConfirm = true }
            )
            .padding(.top, Spacing.xs)
            // Measure the floating controls so the header clears them at rest.
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                topBarHeight = height
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showMap) {
            ListMapScreen(title: currentList.name, spots: detailVM.spots)
        }
        .sheet(isPresented: $showSort) {
            SSortSheet(
                options: SavedSpotSort.allCases,
                selection: $sort,
                label: \.label,
                icon: \.icon
            )
        }
        .sheet(item: $saveTarget) { spot in
            SaveToListSheet(spotID: spot.id)
        }
        .savedListManagement(
            listName: currentList.name,
            listDescription: currentList.description ?? "",
            showEdit: $showEdit,
            showDeleteConfirm: $showDeleteConfirm,
            error: $actionError,
            onSubmitEdit: submitEdit,
            onConfirmDelete: confirmDelete
        )
        .onAppear { tabBarVisibility?.requestHidden() }
        .onDisappear { tabBarVisibility?.releaseHidden() }
        .task {
            if detailVM.state == .idle { await detailVM.load() }
        }
    }

    // MARK: - List management

    private func submitEdit(name: String, description: String) {
        Task {
            do { try await store.updateList(id: list.id, name: name, description: description) }
            catch { actionError = error.localizedDescription }
        }
    }

    private func confirmDelete() {
        Task {
            do {
                try await store.deleteList(id: list.id)
                dismiss()
            } catch {
                actionError = error.localizedDescription
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(currentList.name)
                    .font(.sDisplayM)
                    .foregroundStyle(Color.sTextPrimary)
                if let description = currentList.description, !description.isEmpty {
                    Text(description)
                        .font(.sBody)
                        .foregroundStyle(Color.sTextSecondary)
                }
            }
            // Collaborators hidden for v1 — no sharing/collaborator backend yet.
        }
    }

    // MARK: - Feed

    @ViewBuilder
    private var feed: some View {
        switch detailVM.state {
        case .idle, .loading:
            SLoadingState()
        case .failed(let message):
            SErrorStateView(message: message) {
                Task { await detailVM.load() }
            }
            .padding(.top, Spacing.xxxl)
        case .loaded:
            if detailVM.spots.isEmpty {
                emptyState
            } else {
                spotList
            }
        }
    }

    private var spotList: some View {
        LazyVStack(spacing: Spacing.xl) {
            ForEach(sortedSpots) { spot in
                NavigationLink(value: spot) {
                    SpotCard(
                        spot: spot,
                        isSaved: store.isSaved(spot.id)
                    ) {
                        saveTarget = spot
                    }
                }
                .buttonStyle(.plain)
                .onAppear {
                    if spot.id == detailVM.spots.last?.id {
                        Task { await detailVM.loadMore() }
                    }
                }
            }

            if detailVM.isLoadingMore {
                ProgressView()
                    .tint(Color.sAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
        }
    }

    private var emptyState: some View {
        SEmptyStateView(
            icon: "bookmark",
            title: "Add spots to your list",
            message: "Tap the save icon on any spot, then select this list to start adding it.",
            actionTitle: "Explore Spots"
        ) {
            // Pop back to the Saved root (restores the tab bar via onDisappear),
            // then cross-fade over to the Explore tab so the switch isn't instant.
            dismiss()
            withAnimation(.easeInOut(duration: 0.35)) {
                router?.selection = .explore
            }
        }
        .padding(.top, Spacing.xxxl)
        .frame(maxWidth: .infinity)
    }

}

// MARK: - Preview

#Preview("Saved List Detail") {
    NavigationStack {
        SavedListDetailScreen(list: SavedList.samples[1], service: MockSavedListService())
    }
    .environment(SavedStore(service: MockSavedListService()))
}

#Preview("Saved List Detail — Dark") {
    NavigationStack {
        SavedListDetailScreen(list: SavedList.samples[0], service: MockSavedListService())
    }
    .environment(SavedStore(service: MockSavedListService()))
    .preferredColorScheme(.dark)
}

#Preview("Saved List Detail — Empty") {
    let empty = SavedList(
        id: "empty",
        name: "Weekend hikes",
        description: "Nothing here yet.",
        spotCount: 0,
        coverPhotoUrl: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    return NavigationStack {
        SavedListDetailScreen(list: empty, service: MockSavedListService(listSpots: []))
    }
    .environment(SavedStore(service: MockSavedListService()))
}
