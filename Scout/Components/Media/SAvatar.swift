import SwiftUI

/// A circular avatar. Shows a locally-supplied `image` if present, else a remote
/// `url`, else the accent-soft `person.fill` placeholder. Sized square and clipped
/// to a circle. Shared by the profile header, the editable avatar, and review
/// cards — pass `size` to match the surrounding hierarchy (96pt profile, 32pt rows).
struct SAvatar: View {
    var url: URL? = nil
    /// A locally-held image (e.g. a just-picked photo) that takes precedence over `url`.
    var image: Image? = nil
    var size: CGFloat = 96

    var body: some View {
        Group {
            if let image {
                image.resizable().scaledToFill()
            } else if let url {
                AsyncImage(url: url) { remote in
                    remote.resizable().scaledToFill()
                } placeholder: {
                    Color.sBorderSubtle
                }
            } else {
                Circle()
                    .fill(Color.sAccentSoft)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.42))
                            .foregroundStyle(Color.sTextTertiary)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Preview

#Preview("SAvatar") {
    HStack(spacing: Spacing.lg) {
        SAvatar(size: 96)            // placeholder
        SAvatar(size: 64)
        SAvatar(size: 32)
    }
    .padding(Spacing.lg)
    .background(Color.sBackground)
}
