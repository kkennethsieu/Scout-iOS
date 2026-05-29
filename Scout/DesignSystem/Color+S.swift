import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let sBackground        = Color("background")
    static let sSurface           = Color("surface")
    static let sSurfaceElevated   = Color("surfaceElevated")

    // MARK: - Text
    static let sTextPrimary       = Color("textPrimary")
    static let sTextSecondary     = Color("textSecondary")
    static let sTextTertiary      = Color("textTertiary")
    
    // MARK: - Borders
    static let sBorderSubtle      = Color("borderSubtle")
    static let sBorderDefault     = Color("borderDefault")
    
    // MARK: - Accent
    static let sAccent            = Color("accent")
    static let sAccentSoft        = Color("accentSoft")
    
    // MARK: - Ratings
    static let sRatingFilled      = Color("ratingFilled")
    static let sRatingEmpty       = Color("ratingEmpty")
    
    // MARK: - Semantic
    static let sSuccess           = Color("success")
    static let sWarning           = Color("warning")
    static let sWarningSoft       = Color("warningSoft")
    static let sError             = Color("error")
}

#Preview("Scout Color Palette") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            colorRow("Background", .sBackground)
            colorRow("Surface", .sSurface)
            colorRow("Surface Elevated", .sSurfaceElevated)
            colorRow("Text Primary", .sTextPrimary)
            colorRow("Text Secondary", .sTextSecondary)
            colorRow("Text Tertiary", .sTextTertiary)
            colorRow("Border Subtle", .sBorderSubtle)
            colorRow("Border Default", .sBorderDefault)
            colorRow("Accent", .sAccent)
            colorRow("Accent Soft", .sAccentSoft)
            colorRow("Rating Filled", .sRatingFilled)
            colorRow("Rating Empty", .sRatingEmpty)
            colorRow("Success", .sSuccess)
            colorRow("Warning", .sWarning)
            colorRow("Warning Soft", .sWarningSoft)
            colorRow("Error", .sError)
        }
        .padding()
    }
    .background(Color.sBackground)
}

@ViewBuilder
private func colorRow(_ name: String, _ color: Color) -> some View {
    HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 48, height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.sBorderSubtle, lineWidth: 0.5)
            )
        Text(name)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.sTextPrimary)
        Spacer()
    }
}
