import SwiftUI

/// A titled section: a heading label above its content. Used across the app
/// (Spot Detail sections, the Explore filter sheet, future forms). Pass
/// `titleFont` to match the surrounding hierarchy — `.sHeadingL` for full-screen
/// sections, `.sHeadingS` for compact ones like sheet groups.
struct SSection<Content: View>: View {
    let title: String
    var titleFont: Font = .sHeadingL
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(titleFont)
                .foregroundStyle(Color.sTextPrimary)
            content
        }
    }
}
