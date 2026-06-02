import SwiftUI

/// Dashed-border "add photos" drop zone for the review form. Tapping it would
/// open the photo picker (not wired). Purely the empty/initial state for now.
struct PhotoUploadArea: View {
    var maxPhotos: Int = 5
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "camera.badge.plus")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.sTextSecondary)
                    .frame(width: 56, height: 56)
                    .background(Color.sSurface, in: Circle())

                Text("Add photos")
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextPrimary)

                Text("Up to \(maxPhotos) photos (JPEG or RAW)")
                    .font(.sBodyS)
                    .foregroundStyle(Color.sTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xxl)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(Color.sBorderDefault,
                                  style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Add photos")
        .accessibilityHint("Up to \(maxPhotos) photos, JPEG or RAW")
    }
}

// MARK: - Preview

#Preview("Photo Upload Area") {
    PhotoUploadArea()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sBackground)
}
