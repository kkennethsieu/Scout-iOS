import SwiftUI

/// Shown in the create flow when a spot's location can't be determined — the
/// uploaded photo has no GPS EXIF and/or location access is unavailable. Offers
/// the two recovery paths plus a cancel.
///
/// Not wired yet — the actions are stubs.
struct LocationErrorSheet: View {
    /// Try again with a different photo (re-opens the photo picker).
    var onPickDifferentPhoto: () -> Void = {}
    /// Take the user to enable location permissions.
    var onEnableLocation: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.sm) {
                icon

                Text("We can't read the location")
                    .font(.sHeadingL)
                    .foregroundStyle(Color.sTextPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("We need location access or a photo with location data")
                    .font(.sBody)
                    .foregroundStyle(Color.sTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Spacing.xxl)
            .padding(.horizontal, Spacing.lg)

            actions

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(Color.sBackground)
        .presentationDetents([.height(440)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.xl)
    }

    // MARK: - Icon

    private var icon: some View {
        Image(systemName: "location.slash")
            .font(.system(size: 26, weight: .regular))
            .foregroundStyle(Color.sTextSecondary)
            .frame(width: 64, height: 64)
            .background(Color.sSurface, in: Circle())
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: Spacing.md) {
            SPrimaryButton(title: "Pick a different photo") {
                // TODO: re-open the photo picker
                onPickDifferentPhoto()
            }

            SSecondaryButton(title: "Enable location permissions") {
                // TODO: route to location permission settings
                onEnableLocation()
            }

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextPrimary)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Location Error") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            LocationErrorSheet()
        }
}

#Preview("Location Error — Dark") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            LocationErrorSheet()
        }
        .preferredColorScheme(.dark)
}
