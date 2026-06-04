import SwiftUI

/// A compact informational callout: an SF Symbol + a short message on a tinted
/// `sAccentSoft` surface. Reusable anywhere an inline tip/hint is needed (e.g.
/// the review form's photo tip). The message supports markdown (`**bold**`).
struct STipBanner: View {
    var icon: String = "lightbulb"
    let message: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.sAccent)
            Text(message)
                .font(.sBodyS)
                .foregroundStyle(Color.sTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(Color.sAccentSoft, in: RoundedRectangle(cornerRadius: Radius.md))
    }
}

// MARK: - Preview

#Preview("STipBanner") {
    VStack(spacing: Spacing.lg) {
        STipBanner(message: "**Tip:** High-resolution shots with natural lighting showcase spots best.")
        STipBanner(icon: "info.circle",
                   message: "Aggregate facts appear once a spot has three or more reviews.")
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sBackground)
}
