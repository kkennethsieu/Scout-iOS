#if os(iOS)
import SwiftUI
import UIKit

/// Wraps `UIImagePickerController` for in-app camera capture, returning the photo
/// as JPEG `Data`. iOS-only — macOS/visionOS have no camera picker, so callers
/// gate the "Take Photo" option on `CameraPicker.isAvailable`.
struct CameraPicker: UIViewControllerRepresentable {
    /// Called with the captured photo, or `nil` if the user cancelled. The caller
    /// is responsible for dismissing the presentation.
    var onComplete: (Data?) -> Void

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onComplete: (Data?) -> Void

        init(onComplete: @escaping (Data?) -> Void) {
            self.onComplete = onComplete
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onComplete(image?.jpegData(compressionQuality: 0.9))
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onComplete(nil)
        }
    }
}
#endif
