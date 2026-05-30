import SwiftUI
/// Composed from existing primitives (`SSheetHeader`, design tokens). The two
/// option rows are co-located private subviews since they're specific to this
/// sheet's layout.
struct ShareSpotSheet: View {
    /// Start the photo-upload flow (review form with EXIF tagging).
    var onUploadPhotos: () -> Void = {}
    /// Start the current-location flow (Confirm Location / precise pin).
    var onCurrentLocation: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SSheetHeader(title: "Share Spot") { dismiss() }

            VStack(spacing: Spacing.md) {
                RecommendedOption {
                    dismiss()
                    onUploadPhotos()
                }
                CurrentLocationOption {
                    dismiss()
                    onCurrentLocation()
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            Spacer(minLength: 0)
        }
        .background(Color.sBackground)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.xl)
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
