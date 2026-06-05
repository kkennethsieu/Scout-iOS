import SwiftUI

/// Bottom bar for the create-flow map: a "SPOTTED IN" region readout with an info
/// button, over the primary CTA (review the selected spot, or continue with a new
/// one). Presentational — the owner supplies the region/CTA text and handles taps.
struct ConfirmLocationFooter: View {
    let regionText: String
    let ctaTitle: String
    var onInfo: () -> Void = {}
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("SPOTTED IN")
                        .font(.sCaption)
                        .foregroundStyle(Color.sTextTertiary)
                    Text(regionText)
                        .font(.sHeadingM)
                        .foregroundStyle(Color.sTextPrimary)
                }

                Spacer()

                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.sTextTertiary)
                }
                .buttonStyle(.plain)
            }

            SPrimaryButton(title: ctaTitle, action: onContinue)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(Color.sBackground)
        .overlay(alignment: .top) {
            Divider().background(Color.sBorderSubtle)
        }
    }
}

// MARK: - Preview

#Preview("Confirm Location Footer") {
    VStack {
        Spacer()
        ConfirmLocationFooter(regionText: "Portland, USA",
                              ctaTitle: "Continue with new spot") {}
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sBackground)
}
