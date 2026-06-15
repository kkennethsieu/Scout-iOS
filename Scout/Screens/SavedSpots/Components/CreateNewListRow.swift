import SwiftUI

/// The "+ Create new list" action row: an accent circle with a plus, then the
/// label. Shared by the Saved tab and the "Save to a list" sheet so the entry
/// point looks identical in both places.
struct CreateNewListRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.sAccent, in: Circle())

                Text("Create new list")
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)

                Spacer(minLength: 0)
            }
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("CreateNewListRow") {
    CreateNewListRow {}
        .padding(.horizontal, Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.sBackground)
}
