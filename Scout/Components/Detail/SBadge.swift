import SwiftUI

/// A small accent pill badge for short labels (e.g. "Required", "New", "Just
/// Added"). Pass any title; styling stays consistent — `sCaption` accent text on
/// a tinted `sAccentSoft` capsule.
struct SBadge: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.sCaption)
            .foregroundStyle(Color.sAccent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 2)
            .background(Color.sAccentSoft, in: Capsule())
    }
}

// MARK: - Preview

#Preview("SBadge") {
    HStack(spacing: Spacing.sm) {
        Text("Photos").font(.sHeadingL)
        SBadge("Required")
        SBadge("New")
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sBackground)
}
