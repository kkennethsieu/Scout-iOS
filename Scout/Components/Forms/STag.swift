import SwiftUI

/// A small, non-interactive soft-accent pill used to tag metadata such as a
/// spot's category ("Alpine") or distance ("32m away"). For the selectable
/// filter pills see `SFilterChip`.
struct STag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.sCaption)
            .foregroundStyle(Color.sAccent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 2)
            .background(Color.sAccentSoft, in: Capsule())
    }
}

// MARK: - Preview

#Preview("Tag") {
    HStack(spacing: Spacing.sm) {
        STag(text: "Alpine")
        STag(text: "Coastal")
        STag(text: "32m away")
    }
    .padding()
    .background(Color.sBackground)
}
