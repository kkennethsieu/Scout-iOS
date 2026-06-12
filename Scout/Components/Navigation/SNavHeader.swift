import SwiftUI

/// A reusable top navigation bar for modal or pushed sub-flows.
/// Includes a centered title and a leading back button with a subtle bottom divider.
struct SNavHeader: View {
    let title: String
    /// Optionally allow hiding the back button if this header is used on a root screen
    var showBackButton: Bool = true

    /// Optional trailing text action (e.g. "Save"). When `trailingTitle` and
    /// `trailingAction` are both set, an accent text button is pinned to the
    /// trailing edge, mirroring the leading back button.
    var trailingTitle: String? = nil
    var trailingAction: (() -> Void)? = nil
    var trailingDisabled: Bool = false

    var body: some View {
        ZStack {
            // Centered Title
            Text(title)
                .font(.sHeadingM)
                .foregroundStyle(Color.sTextPrimary)
                .lineLimit(1)

            // Leading Back Button
            if showBackButton {
                HStack {
                    SBackButton()
                    Spacer()
                }
            }

            // Trailing Action
            if let trailingTitle, let trailingAction {
                HStack {
                    Spacer()
                    Button(action: trailingAction) {
                        Text(trailingTitle)
                            .font(.sHeadingS)
                            .foregroundStyle(Color.sAccent)
                            .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .disabled(trailingDisabled)
                    .opacity(trailingDisabled ? 0.4 : 1)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color.sBackground)
        .overlay(alignment: .bottom) {
            Divider().background(Color.sBorderSubtle)
        }
    }
}
