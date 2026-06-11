import SwiftUI

/// Centered empty/zero state: an icon, a title, an optional message, and an
/// optional CTA. Shared across the app (Explore feed, Search, Profile tabs).
/// Mirrors `SErrorStateView`'s shape so empty and error states read alike.
struct SEmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.sTextTertiary)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                if let message {
                    Text(message)
                        .font(.sBody)
                        .foregroundStyle(Color.sTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let actionTitle, let action {
                SSecondaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 200)
                    .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: 280)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Preview

#Preview("Empty State") {
    ZStack {
        Color.sBackground.ignoresSafeArea()
        SEmptyStateView(
            icon: "mappin.slash",
            title: "No spots yet",
            message: "Check back soon.",
            actionTitle: "Show all spots"
        ) {}
    }
}

#Preview("Empty State — Dark") {
    ZStack {
        Color.sBackground.ignoresSafeArea()
        SEmptyStateView(icon: "magnifyingglass", title: "No results",
                        message: "No spots or places match your search.")
    }
    .preferredColorScheme(.dark)
}
