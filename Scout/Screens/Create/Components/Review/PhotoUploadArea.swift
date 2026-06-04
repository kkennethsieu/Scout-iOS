import SwiftUI

/// Photo picker area for the review form. Empty state is a dashed "add photos"
/// drop zone; once photos exist it shows a horizontal gallery of thumbnails
/// (each removable) plus a compact add tile while under `maxPhotos`.
///
/// Presentational only — the owner provides `photos` and handles `onAdd` /
/// `onRemove` (the actual camera / library presentation lives in the screen).
struct PhotoUploadArea: View {
    var photos: [Data] = []
    var maxPhotos: Int = 5
    var onAdd: () -> Void = {}
    var onRemove: (Int) -> Void = { _ in }

    /// Decoded once per change to `photos` (keyed on count, which is the only way
    /// photos change here) so the form's text-field re-renders don't re-decode.
    @State private var thumbnails: [Image?] = []

    private var canAdd: Bool { photos.count < maxPhotos }

    var body: some View {
        Group {
            if photos.isEmpty {
                emptyDropZone
            } else {
                gallery
            }
        }
        .onAppear(perform: rebuildThumbnails)
        .onChange(of: photos.count) { _, _ in rebuildThumbnails() }
    }

    private func rebuildThumbnails() {
        thumbnails = photos.map { Image(data: $0) }
    }

    // MARK: - Empty state

    private var emptyDropZone: some View {
        Button(action: onAdd) {
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

    // MARK: - Gallery

    private var gallery: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("\(photos.count) of \(maxPhotos) photos")
                .font(.sCaption)
                .foregroundStyle(Color.sTextTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Array(thumbnails.enumerated()), id: \.offset) { index, image in
                        thumbnail(image, index: index)
                    }
                    if canAdd { addTile }
                }
            }
        }
    }

    private func thumbnail(_ image: Image?, index: Int) -> some View {
        // Color base + overlay + clip so a decoded image can't stretch the tile.
        Color.sSurface
            .frame(width: 96, height: 96)
            .overlay {
                image?
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(alignment: .topTrailing) {
                Button {
                    onRemove(index)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.45))
                        .padding(4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove photo \(index + 1)")
            }
    }

    private var addTile: some View {
        Button(action: onAdd) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "camera.badge.plus")
                    .font(.system(size: 20, weight: .regular))
                Text("Add")
                    .font(.sCaption)
            }
            .foregroundStyle(Color.sTextSecondary)
            .frame(width: 96, height: 96)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(Color.sBorderDefault,
                                  style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add photo")
    }
}

// MARK: - Preview

#Preview("Photo Upload Area — empty") {
    PhotoUploadArea(maxPhotos: 3)
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sBackground)
}
