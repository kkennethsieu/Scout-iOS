import SwiftUI

extension Font {
    // MARK: - Display
    /// 34pt semibold — hero titles (auth screens, splash)
    static let sDisplayL  = Font.system(size: 34, weight: .semibold)
    
    /// 28pt semibold — spot detail name, profile name
    static let sDisplayM  = Font.system(size: 28, weight: .semibold)
    
    // MARK: - Headings
    /// 22pt semibold — section titles
    static let sHeadingL  = Font.system(size: 22, weight: .semibold)
    
    /// 17pt semibold — card titles, list rows, section headers
    static let sHeadingM  = Font.system(size: 17, weight: .semibold)
    
    /// 15pt semibold — subsection labels, button text, form section headers
    static let sHeadingS  = Font.system(size: 15, weight: .semibold)
    
    // MARK: - Body
    /// 17pt regular — primary body, review notes
    static let sBodyL     = Font.system(size: 17, weight: .regular)
    
    /// 15pt regular — default, form labels
    static let sBody      = Font.system(size: 15, weight: .regular)
    
    /// 13pt regular — captions, metadata, EXIF chips
    static let sBodyS     = Font.system(size: 13, weight: .regular)
    
    // MARK: - Caption
    /// 11pt medium — pills, badges, tag labels, ORIGIN label
    static let sCaption   = Font.system(size: 11, weight: .medium)
}

#Preview("Scout Type Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            sample("Display L · 34pt", .sDisplayL)
            sample("Display M · 28pt", .sDisplayM)
            sample("Heading L · 22pt", .sHeadingL)
            sample("Heading M · 17pt", .sHeadingM)
            sample("Heading S · 15pt", .sHeadingS)
            sample("Body L · 17pt", .sBodyL)
            sample("Body · 15pt", .sBody)
            sample("Body S · 13pt", .sBodyS)
            sample("Caption · 11pt", .sCaption)
        }
        .padding()
    }
    .background(Color.sBackground)
}

@ViewBuilder
private func sample(_ label: String, _ font: Font) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.sTextTertiary)
            .textCase(.uppercase)
        Text("Find your next shot. Share where you stood.")
            .font(font)
            .foregroundStyle(Color.sTextPrimary)
    }
}
