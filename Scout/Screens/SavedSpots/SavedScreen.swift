import SwiftUI

/// The Saved tab root: a large "Saved" title, a "Lists" tab strip, a "Create new
/// list" action, then the user's saved lists from the shared `SavedStore`.
struct SavedScreen: View {
    enum Tab: CaseIterable, Hashable {
        case lists
        var title: String { switch self { case .lists: "Lists" } }
    }

    @Environment(SavedStore.self) private var store
    @Environment(AuthService.self) private var auth

    @State private var selectedTab: Tab = .lists
    @State private var showCreateList = false
    @State private var actionError: String?

    /// True when the Saved tab is the active one. Toggling it true re-fetches, so
    /// counts/covers stay current each time the tab is shown.
    var isActive: Bool = true

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })
    }

    @ViewBuilder
    var body: some View {
        // Signed out, the Saved tab is the sign-in screen itself.
        if auth.isAuthenticated {
            signedInBody
        } else {
            AuthScreen()
        }
    }

    private var signedInBody: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Saved")
                        .font(.sDisplayL)
                        .foregroundStyle(Color.sTextPrimary)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.xxl)

                    SSegmentedControl(
                        options: Tab.allCases,
                        selection: $selectedTab,
                        label: \.title
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)

                    content
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.xs)
                }
            }
            .background(Color.sBackground)
            .refreshable { await store.refresh() }
            .navigationDestination(for: SavedList.self) { list in
                SavedListDetailScreen(list: list)
            }
            .navigationDestination(for: SpotSummary.self) { spot in
                SpotDetailScreen(spotID: spot.id)
            }
            .sheet(isPresented: $showCreateList) {
                CreateListSheet { name, description in
                    Task {
                        do { try await store.createList(name: name, description: description) }
                        catch { actionError = error.localizedDescription }
                    }
                }
            }
            .alert("Couldn't create list", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(actionError ?? "")
            }
            .task(id: isActive) {
                // First time: full load. Returning to the tab: silent refresh.
                // Only reached while signed in (the tab is `AuthScreen` otherwise).
                guard isActive else { return }
                if store.state == .idle {
                    await store.load()
                } else {
                    await store.refresh()
                }
            }
            .enableSwipeBack()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            SLoadingState()
        case .failed(let message):
            SErrorStateView(message: message) {
                Task { await store.load() }
            }
            .padding(.top, Spacing.xxxl)
        case .loaded:
            lists
        }
    }

    private var lists: some View {
        SListGroup {
            CreateNewListRow { showCreateList = true }

            ForEach(store.lists) { list in
                NavigationLink(value: list) {
                    SavedListRow(list: list)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview("Saved") {
    SavedScreen()
        .environment(SavedStore(service: MockSavedListService()))
}

#Preview("Saved — Dark") {
    SavedScreen()
        .environment(SavedStore(service: MockSavedListService()))
        .preferredColorScheme(.dark)
}
