import SwiftUI

/// Full-screen, non-dismissible gate shown when the build is below the minimum
/// supported version (`UpdateChecker` → `.required`). The only way forward is to
/// update, so there's no close control — `RootView` shows this instead of the app.
struct UpdateRequiredScreen: View {
    let updateURL: URL
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Color.sBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)

                VStack(spacing: Spacing.sm) {
                    Text("Time to update")
                        .font(.sDisplayM)
                        .foregroundStyle(Color.sTextPrimary)

                    Text("This version of Scout is no longer supported. Update to the latest version to keep exploring.")
                        .font(.sBodyL)
                        .foregroundStyle(Color.sTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                SPrimaryButton(title: "Update") {
                    openURL(updateURL)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxxl)
        }
    }
}

// MARK: - Preview

#Preview("Update Required") {
    UpdateRequiredScreen(updateURL: URL(string: "https://apps.apple.com/app/scout")!)
}
