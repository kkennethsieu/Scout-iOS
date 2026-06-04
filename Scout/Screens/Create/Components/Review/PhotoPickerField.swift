import SwiftUI
import PhotosUI

/// Photo input for the review form: renders `PhotoUploadArea` and owns the source
/// selection (camera vs. library), the system library picker, and decoding picked
/// items to `Data`. All the picking state lives here; the owner just supplies the
/// current `photos` and handles `onAdd` / `onRemove`.
struct PhotoPickerField: View {
    let photos: [Data]
    var maxPhotos: Int
    var onAdd: (Data) -> Void
    var onRemove: (Int) -> Void

    @State private var showSourceDialog = false
    @State private var showLibraryPicker = false
    @State private var libraryItems: [PhotosPickerItem] = []
    #if os(iOS)
    @State private var showCamera = false
    #endif

    var body: some View {
        PhotoUploadArea(
            photos: photos,
            maxPhotos: maxPhotos,
            onAdd: addPhotoTapped,
            onRemove: onRemove
        )
        .confirmationDialog("Add a photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
            #if os(iOS)
            if CameraPicker.isAvailable {
                Button("Take Photo") { showCamera = true }
            }
            #endif
            Button("Choose from Library") { showLibraryPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showLibraryPicker,
            selection: $libraryItems,
            maxSelectionCount: remainingPhotoSlots,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: libraryItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await loadLibrary(items) }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in
                showCamera = false
                if let data { onAdd(data) }
            }
            .ignoresSafeArea()
        }
        #endif
    }

    private var remainingPhotoSlots: Int {
        max(1, maxPhotos - photos.count)
    }

    private func addPhotoTapped() {
        #if os(iOS)
        if CameraPicker.isAvailable {
            showSourceDialog = true
        } else {
            showLibraryPicker = true   // simulator / no camera → straight to library
        }
        #else
        showLibraryPicker = true
        #endif
    }

    /// Loads each picked item as `Data` and forwards it; the owner's `onAdd`
    /// enforces the cap, so extra selections beyond the remaining slots are ignored.
    private func loadLibrary(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                onAdd(data)
            }
        }
        libraryItems = []
    }
}
