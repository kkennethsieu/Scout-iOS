import SwiftUI

/// A compact informational callout: an SF Symbol + a short message on a tinted
/// `sAccentSoft` surface. Reusable anywhere an inline tip/hint is needed (e.g. the
/// review form's photo tip).
///
/// Use `init(message:)` for static copy (supports markdown / localization) and
/// `init(verbatim:)` for dynamic runtime strings (e.g. view-model-provided text).
struct STipBanner: View {
    let icon: String
    private let text: Text

    init(icon: String = "lightbulb", message: LocalizedStringKey) {
        self.icon = icon
        self.text = Text(message)
    }

    init(icon: String = "lightbulb", verbatim message: String) {
        self.icon = icon
        self.text = Text(verbatim: message)
    }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.sAccent)
            text
                .font(.sBodyS)
                .foregroundStyle(Color.sTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .padding(.horizontal, Spacing.md)
        .background(Color.sAccentSoft, in: RoundedRectangle(cornerRadius: Radius.md))
    }
}

// MARK: - Preview

#Preview("STipBanner") {
    VStack(spacing: Spacing.lg) {
        STipBanner(message: "**Tip:** High-resolution shots with natural lighting showcase spots best.")
        STipBanner(icon: "info.circle",
                   message: "Aggregate facts appear once a spot has three or more reviews.")
        STipBanner(verbatim: "Couldn't read the location in this photo — drag your pin to where you took it.")
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sBackground)
}
