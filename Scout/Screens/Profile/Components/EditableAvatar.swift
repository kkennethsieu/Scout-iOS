import SwiftUI
import PhotosUI

/// The profile-picture editor on `EditProfileScreen`: a circular avatar with a
/// camera badge. Tapping it opens the system photo library; the picked photo's
/// raw `Data` is reported up via `onPick` (the owning view model holds the preview
/// and uploads on save). Controlled — it shows whatever `image`/`url` it's given.
struct EditableAvatar: View {
    /// A locally-picked preview image (takes precedence over `url`).
    var image: Image?
    /// The existing remote avatar, shown until a new photo is picked.
    var url: URL?
    /// Reports the raw bytes of a newly picked photo.
    var onPick: (Data) -> Void

    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
            SAvatar(url: url, image: image)
                .overlay(alignment: .bottomTrailing) { cameraBadge }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change profile picture")
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    onPick(data)
                }
            }
        }
    }

    // MARK: - Camera badge

    private var cameraBadge: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(Color.sAccent, in: Circle())
            .overlay(Circle().stroke(Color.sBackground, lineWidth: 2))
    }
}

// MARK: - Preview

#Preview("Editable Avatar") {
    EditableAvatar(image: nil, url: nil, onPick: { _ in })
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sBackground)
}
