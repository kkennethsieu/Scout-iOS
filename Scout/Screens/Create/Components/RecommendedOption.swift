import SwiftUI

struct RecommendedOption: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("RECOMMENDED")
                        .font(.sCaption)
                        .tracking(0.4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(.white.opacity(0.15), in: Capsule())

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Upload photos first")
                            .font(.sHeadingM)
                            .foregroundStyle(.white)

                        Text("Select images from your gallery to automatically tag location and camera settings.")
                            .font(.sBodyS)
                            .foregroundStyle(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "camera")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: Radius.md))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(Color.sAccent, in: RoundedRectangle(cornerRadius: Radius.lg))
        }
        .buttonStyle(OptionCardStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Upload photos first. Recommended.")
        .accessibilityHint("Select images from your gallery to automatically tag location and camera settings.")
    }
}
