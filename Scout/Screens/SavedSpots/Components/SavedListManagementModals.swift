import SwiftUI

/// Bundles the saved-list management modals — edit sheet, delete confirmation,
/// and error alert — into one modifier so the detail screen's `body` stays about
/// layout, not chrome. The screen owns the booleans and supplies the actions.
private struct SavedListManagementModals: ViewModifier {
    let listName: String
    let listDescription: String
    @Binding var showEdit: Bool
    @Binding var showDeleteConfirm: Bool
    @Binding var error: String?
    var onSubmitEdit: (_ name: String, _ description: String) -> Void
    var onConfirmDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showEdit) {
                CreateListSheet(mode: .edit, name: listName, description: listDescription) { name, description in
                    onSubmitEdit(name, description)
                }
            }
            .confirmationDialog(
                "Delete this list?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete list", role: .destructive, action: onConfirmDelete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
            .alert("Something went wrong", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { error != nil }, set: { if !$0 { error = nil } })
    }
}

extension View {
    /// Attaches the saved-list edit / delete / error modals (see `SavedListManagementModals`).
    func savedListManagement(
        listName: String,
        listDescription: String,
        showEdit: Binding<Bool>,
        showDeleteConfirm: Binding<Bool>,
        error: Binding<String?>,
        onSubmitEdit: @escaping (_ name: String, _ description: String) -> Void,
        onConfirmDelete: @escaping () -> Void
    ) -> some View {
        modifier(SavedListManagementModals(
            listName: listName,
            listDescription: listDescription,
            showEdit: showEdit,
            showDeleteConfirm: showDeleteConfirm,
            error: error,
            onSubmitEdit: onSubmitEdit,
            onConfirmDelete: onConfirmDelete
        ))
    }
}
