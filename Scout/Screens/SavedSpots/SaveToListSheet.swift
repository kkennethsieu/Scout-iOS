import SwiftUI

/// "Save to a list" sheet: a Create-new-list row plus the user's lists, each with
/// a multi-select checkbox seeded from the spot's current membership. Edits are
/// collected locally and committed in one `setMembership` PATCH when the sheet
/// closes; the returned snapshot refreshes hearts/checkboxes app-wide.
///
/// Reads the shared `SavedStore` from the environment. When none is injected
/// (previews), it degrades to a local-only checklist over `SavedList.samples`.
struct SaveToListSheet: View {
    var spotID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(SavedStore.self) private var store: SavedStore?
    @Environment(ToastCenter.self) private var toasts: ToastCenter?

    @State private var selected: Set<String> = []
    @State private var initialSelection: Set<String> = []
    @State private var showCreateList = false

    private var lists: [SavedList] { store?.lists ?? SavedList.samples }

    var body: some View {
        VStack(spacing: 0) {
            SSheetHeader(title: "Save to a list") { dismiss() }

            ScrollView {
                SListGroup {
                    CreateNewListRow { showCreateList = true }

                    ForEach(lists) { list in
                        Button {
                            toggle(list.id)
                        } label: {
                            SavedListRow(list: list, accessory: .checkbox(selected.contains(list.id)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.xl)
        .sensoryFeedback(.selection, trigger: selected)
        .onAppear {
            let current = store?.listIDs(containingSpot: spotID) ?? []
            selected = current
            initialSelection = current
        }
        .onDisappear(perform: commit)
        .sheet(isPresented: $showCreateList) {
            CreateListSheet { name, description in
                createList(name: name, description: description)
            }
        }
    }

    private func toggle(_ id: String) {
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
    }

    /// Create a list and pre-check it (you make a list to save this spot into it).
    private func createList(name: String, description: String) {
        guard let store else { return }
        Task {
            try? await store.createList(name: name, description: description)
            if let created = store.lists.last { selected.insert(created.id) }
        }
    }

    /// One PATCH with the final set when the sheet closes (only if it changed).
    /// The store outlives the sheet, so this completes after dismissal — and the
    /// global toast host (also outside the sheet) shows the confirmation.
    private func commit() {
        guard let store, selected != initialSelection else { return }
        let ids = Array(selected)
        let saved = !selected.isEmpty
        Task {
            do {
                try await store.setMembership(spotID: spotID, listIDs: ids)
                toasts?.show(saved ? "Saved to your lists" : "Removed from your lists")
            } catch { }
        }
    }
}

// MARK: - Preview

#Preview("Save to a list") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            SaveToListSheet(spotID: "1")
        }
}

#Preview("Save to a list — Dark") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            SaveToListSheet(spotID: "1")
        }
        .preferredColorScheme(.dark)
}
