import SwiftUI

/// The sticky bottom submit bar for the review form: a primary Submit button over
/// a `.ultraThinMaterial` background, with an optional one-line hint shown beneath
/// it when submission is blocked (e.g. "Add at least one photo to post.").
///
/// Presentational — the owner supplies `isEnabled` / `hint` (from the view model)
/// and handles the actual submit in `onSubmit`.
struct ReviewSubmitBar: View {
    var title: String = "Submit Review"
    var isSubmitting: Bool
    var isEnabled: Bool
    var hint: String?
    var onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: Spacing.sm) {
                SPrimaryButton(title: title, isLoading: isSubmitting, action: onSubmit)
                    .disabled(!isEnabled)

                if let hint {
                    Text(hint)
                        .font(.sBodyS)
                        .foregroundStyle(Color.sTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview("Review Submit Bar") {
    VStack(spacing: Spacing.xl) {
        Spacer()
        ReviewSubmitBar(isSubmitting: false, isEnabled: false,
                        hint: "Add at least one photo to post.") {}
        ReviewSubmitBar(isSubmitting: false, isEnabled: true, hint: nil) {}
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sBackground)
}
