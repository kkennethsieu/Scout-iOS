import SwiftUI

/// A pre-permission primer shown once after sign-in, before the system location
/// prompt. Explains why Scout wants location so the user makes an informed choice
/// (and we don't burn the one-shot system prompt on a confused "Don't Allow").
struct LocationPrimerSheet: View {
    var onEnable: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: 0)

            Image(systemName: "location.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.sAccent)

            VStack(spacing: Spacing.sm) {
                Text("See spots near you")
                    .font(.sHeadingL)
                    .foregroundStyle(Color.sTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Scout uses your location to surface nearby photo spots, show how far away each one is, and drop your pin when you share a spot.")
                    .font(.sBody)
                    .foregroundStyle(Color.sTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(spacing: Spacing.sm) {
                SPrimaryButton(title: "Enable Location", icon: "location.fill", action: onEnable)
                Button("Not Now", action: onSkip)
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextSecondary)
                    .frame(minHeight: 44)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.sBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview("Location Primer") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            LocationPrimerSheet(onEnable: {}, onSkip: {})
        }
}
