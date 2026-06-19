import SwiftUI

/// Full-page "Share a Location" landing screen: a hero invitation, the two entry
/// options (upload photos / use current location), and a metadata tip.
///
/// Presentational only — it reports the user's choice via callbacks. `CreateFlowHost`
/// (the Create tab) owns the photo picker, location, and downstream flow. Composes
/// the existing `RecommendedOption`, `CurrentLocationOption`, and `STipBanner`.
struct ShareLocationScreen: View {
    /// The user tapped "Upload photos first".
    var onTapUpload: () -> Void = {}
    /// The user tapped "Use my current location".
    var onUseCurrentLocation: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("Share a Location")
                .font(.sDisplayL)
                .foregroundStyle(Color.sTextPrimary)

            heroCard

            VStack(spacing: Spacing.md) {
                RecommendedOption { onTapUpload() }
                CurrentLocationOption { onUseCurrentLocation() }
            }

            STipBanner(
                message: "Upload high-resolution shots to help others discover the best views. We'll automatically fetch the location from your photo metadata."
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.sBackground)
    }

    // MARK: - Hero

    /// A landscape photo with a dark gradient scrim so the invitation copy stays
    /// legible over the brightest part of the image.
    private var heroCard: some View {
        Color.sAccentSoft
            .overlay {
                Image("auth-mountain")
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Document your journey")
                        .font(.sHeadingL)
                        .foregroundStyle(.white)

                    Text("Contribute to the collective eye of the landscape.")
                        .font(.sBody)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.lg)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Document your journey. Contribute to the collective eye of the landscape.")
    }
}

// MARK: - Preview

#Preview("Share a Location") {
    ShareLocationScreen()
}

#Preview("Share a Location — Dark") {
    ShareLocationScreen()
        .preferredColorScheme(.dark)
}
