import SwiftUI

struct CurrentLocationOption: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.sAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.sAccentSoft, in: Circle())

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Use my current location")
                        .font(.sHeadingM)
                        .foregroundStyle(Color.sTextPrimary)

                    Text("Pin a spot right where you are standing now.")
                        .font(.sBodyS)
                        .foregroundStyle(Color.sTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.sTextTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(Color.sSurface, in: RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.sBorderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(OptionCardStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Use my current location")
        .accessibilityHint("Pin a spot right where you are standing now.")
    }
}
