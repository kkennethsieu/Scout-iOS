import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The profile-picture editor on `EditProfileScreen`: a 96pt circular avatar with
/// a camera badge. Tapping it opens the system photo library and updates the
/// on-screen image locally — preview only, nothing is uploaded or persisted yet.
///
/// Mirrors `ProfileHeader`'s avatar visual (accent-soft fill + `person.fill`
/// fallback) and reuses the `PhotosPickerItem` → `Data` decode pattern from
/// `PhotoPickerField`.
struct EditableAvatar: View {
    /// The locally picked image, shown in place of the placeholder. Seeded `nil`
    /// (fake data) so it starts on the placeholder.
    @State private var image: Image?
    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
            SAvatar(image: image)
                .overlay(alignment: .bottomTrailing) { cameraBadge }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change profile picture")
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
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

    // MARK: - Loading

    /// Decodes the picked item to `Data`, then to an image for local preview.
    private func load(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        image = Self.image(from: data)
    }

    /// Builds a SwiftUI `Image` from raw photo data on whichever image type the
    /// platform provides (UIKit on iOS/visionOS, AppKit on macOS).
    private static func image(from data: Data) -> Image? {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        return nil
        #endif
    }
}

// MARK: - Preview

#Preview("Editable Avatar") {
    EditableAvatar()
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sBackground)
}
