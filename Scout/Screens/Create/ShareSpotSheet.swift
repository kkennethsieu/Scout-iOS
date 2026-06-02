import SwiftUI
import PhotosUI

/// Root step of the create flow: choose to upload a photo (read EXIF) or use the
/// current location. Presentation-only — the parent `CreateSpotFlow` owns the
/// sheet chrome and navigation; this view just reports the user's choice.
struct ShareSpotSheet: View {
    /// Hands the picked image's raw data to the flow (which reads EXIF). Async
    /// so the loading overlay covers the whole pick → lookup round trip.
    var onUploadPhotos: (Data) async -> Void = { _ in }
    /// The user chose "use my current location".
    var onCurrentLocation: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoPicker = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.md) {
                RecommendedOption {
                    showPhotoPicker = true
                }
                CurrentLocationOption {
                    onCurrentLocation()
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(Color.sBackground)
        .overlay {
            if isLoadingPhoto {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("Share Spot")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $pickedItem,
                      matching: .images,
                      photoLibrary: .shared())
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
    }

    /// Loads the chosen photo as raw `Data`, then forwards it to the flow.
    private func load(_ item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer {
            isLoadingPhoto = false
            pickedItem = nil   // allow re-picking the same asset next time
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        await onUploadPhotos(data)
    }
}

// MARK: - Preview

#Preview("Share Spot") {
    NavigationStack {
        ShareSpotSheet()
    }
}

#Preview("Share Spot — Dark") {
    NavigationStack {
        ShareSpotSheet()
    }
    .preferredColorScheme(.dark)
}
