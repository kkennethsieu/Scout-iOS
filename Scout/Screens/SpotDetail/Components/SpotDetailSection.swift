import SwiftUI

/// A titled section wrapper used throughout the Spot Detail screen: a Heading L
/// label above its content.
struct SpotDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.sHeadingL)
                .foregroundStyle(Color.sTextPrimary)
            content
        }
    }
}
