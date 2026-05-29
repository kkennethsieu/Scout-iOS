import SwiftUI

/// Centered error state with an icon, message, and an optional retry button.
/// Follows the design system §6.8 `SErrorStateView` spec.
struct SErrorStateView: View {
    let message: String
    var title: String = "Something went wrong"
    var retryTitle: String = "Try again"
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(Color.sError)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                Text(message)
                    .font(.sBody)
                    .foregroundStyle(Color.sTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let onRetry {
                SSecondaryButton(title: retryTitle, action: onRetry)
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

#Preview("Error State") {
    ZStack {
        Color.sBackground.ignoresSafeArea()
        SErrorStateView(message: "Couldn't load spots. Check your connection.") {}
    }
}
