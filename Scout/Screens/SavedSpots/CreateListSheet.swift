import SwiftUI

/// Full-screen sheet for creating or editing a saved list: a name field, a
/// description box, and a submit button. A non-empty trimmed name is always
/// required (submit stays disabled until then). The trimmed values are handed
/// back via `onSubmit`; the caller owns the write (see `SavedStore`).
struct CreateListSheet: View {
    enum Mode { case create, edit }

    var mode: Mode = .create
    var onSubmit: (_ name: String, _ description: String) -> Void = { _, _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String

    init(mode: Mode = .create,
         name: String = "",
         description: String = "",
         onSubmit: @escaping (_ name: String, _ description: String) -> Void = { _, _ in }) {
        self.mode = mode
        self.onSubmit = onSubmit
        _name = State(initialValue: name)
        _description = State(initialValue: description)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var title: String {
        mode == .create ? "Create a list" : "Edit list"
    }

    private var submitTitle: String {
        mode == .create ? "Create list" : "Save changes"
    }

    var body: some View {
        VStack(spacing: 0) {
            SSheetHeader(title: title) { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    STextField(
                        label: "List name",
                        text: $name,
                        placeholder: "e.g. Weekend hikes",
                        autocapitalization: .words
                    )

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Description")
                            .font(.sHeadingS)
                            .foregroundStyle(Color.sTextTertiary)
                        STextArea(
                            text: $description,
                            placeholder: "What's this list about?",
                            minHeight: 100
                        )
                    }

                    SPrimaryButton(title: submitTitle) {
                        submit()
                    }
                    .disabled(trimmedName.isEmpty)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.xl)
    }

    private func submit() {
        guard !trimmedName.isEmpty else { return }
        onSubmit(trimmedName, description.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
    }
}

// MARK: - Preview

#Preview("Create a list") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            CreateListSheet()
        }
}

#Preview("Edit list") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            CreateListSheet(mode: .edit, name: "my hikes", description: "test description")
        }
}

#Preview("Create a list — Dark") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            CreateListSheet()
        }
        .preferredColorScheme(.dark)
}
