import SwiftUI
import PhotosUI

/// Create-spot entry sheet: choose to upload a photo or use the current
/// location. Self-contained (owns its header + detents); reports the user's
/// choice via callbacks. The downstream flow is being rebuilt.
struct ShareSpotSheet: View {
    /// The user picked a photo (raw image data).
    var onPhotoPicked: (Data) -> Void = { _ in }
    /// The user chose "use my current location".
    var onUseCurrentLocation: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoPicker = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

    var body: some View {
        VStack(spacing: 0) {
            SSheetHeader(title: "Share Spot") { dismiss() }

            VStack(spacing: Spacing.md) {
                RecommendedOption {
                    showPhotoPicker = true
                }
                CurrentLocationOption {
                    onUseCurrentLocation()
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            Spacer(minLength: 0)
        }
        .background(Color.sBackground)
        .overlay {
            if isLoadingPhoto {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.xl)
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $pickedItem,
                      matching: .images,
                      photoLibrary: .shared())
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
    }

    /// Loads the chosen photo as raw `Data`, then reports it.
    private func load(_ item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer {
            isLoadingPhoto = false
            pickedItem = nil   // allow re-picking the same asset next time
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        onPhotoPicked(data)
    }
}

// MARK: - Preview

#Preview("Share Spot") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            ShareSpotSheet()
        }
}

#Preview("Share Spot — Dark") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            ShareSpotSheet()
        }
        .preferredColorScheme(.dark)
}
