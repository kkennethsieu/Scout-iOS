import SwiftUI

/// A saved list's detail: back / sort / more chrome, the list name + description,
/// a collaborators row, then a vertical feed of `SpotCard`s (reused from
/// Explore). Sort, more, the add-collaborator button, and the floating Map
/// button are decorative for now. Pushed onto the Saved tab's stack.
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
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var actionError: String?

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

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                feed
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, 96) // room for the floating Map button
        }
        .background(Color.sBackground)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .safeAreaInset(edge: .bottom) {
            if !detailVM.spots.isEmpty { mapButton }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: SpotSummary.self) { spot in
            SpotDetailScreen(spotID: spot.id)
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
        .sheet(isPresented: $showEdit) {
            CreateListSheet(
                mode: .edit,
                name: currentList.name,
                description: currentList.description ?? ""
            ) { name, description in
                Task {
                    do { try await store.updateList(id: list.id, name: name, description: description) }
                    catch { actionError = error.localizedDescription }
                }
            }
        }
        .confirmationDialog(
            "Delete this list?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete list", role: .destructive) {
                Task {
                    do {
                        try await store.deleteList(id: list.id)
                        dismiss()
                    } catch {
                        actionError = error.localizedDescription
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
        .alert("Something went wrong", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
        }
        .onAppear { tabBarVisibility?.isHidden = true }
        .onDisappear { tabBarVisibility?.isHidden = false }
        .task {
            if detailVM.state == .idle { await detailVM.load() }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: Spacing.sm) {
            iconButton("chevron.left") { dismiss() }
                .accessibilityLabel("Back")

            Spacer()

            iconButton("arrow.up.arrow.down") { showSort = true }
                .accessibilityLabel("Sort")

            // The app-managed Favorites list can't be edited or deleted, so it
            // has no overflow menu.
            if !currentList.isSystem {
                Menu {
                    Button { showEdit = true } label: {
                        Label("Edit list", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete list", systemImage: "trash")
                    }
                } label: {
                    iconLabel("ellipsis")
                }
                .accessibilityLabel("More")
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.sBackground)
    }

    private func iconButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            iconLabel(name)
        }
        .buttonStyle(.plain)
    }

    private func iconLabel(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color.sTextPrimary)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
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

            collaborators
        }
    }

    private var collaborators: some View {
        HStack(spacing: Spacing.sm) {
            SAvatar(size: 32)

            Button {
                // TODO: add collaborator
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.sTextSecondary)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.sBorderDefault, lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add to list")
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

    // MARK: - Map button

    /// Decorative for now — there's no list map yet.
    private var mapButton: some View {
        Button {
            // TODO: present list map
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "map")
                    .font(.system(size: 15, weight: .semibold))
                Text("Map")
                    .font(.sHeadingS)
            }
            .foregroundStyle(Color.sTextPrimary)
            .padding(.horizontal, Spacing.xl)
            .frame(height: 48)
            .background(
                Capsule().fill(Color.sSurface)
            )
            .overlay(
                Capsule().stroke(Color.sBorderDefault, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.bottom, Spacing.sm)
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
