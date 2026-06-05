import SwiftUI

/// A reusable top navigation bar for modal or pushed sub-flows.
/// Includes a centered title and a leading back button with a subtle bottom divider.
struct SNavHeader: View {
    let title: String
    /// Optionally allow hiding the back button if this header is used on a root screen
    var showBackButton: Bool = true

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
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color.sBackground)
        .overlay(alignment: .bottom) {
            Divider().background(Color.sBorderSubtle)
        }
    }
}
