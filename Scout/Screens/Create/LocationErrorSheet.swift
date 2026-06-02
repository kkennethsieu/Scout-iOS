import SwiftUI

/// Shown when we can't determine where a spot is — either because an uploaded
/// photo had no GPS EXIF, or because reading the device's current location
/// failed. The copy and the primary recovery action depend on which path
/// failed; the fallback actions (map picker, cancel) are shared.
///
/// Not wired yet — `source` defaults to `.photoUpload` and the actions are stubs.
struct LocationErrorSheet: View {
    /// Which action failed, which drives the title/subtitle/primary button.
    nonisolated enum Source: Hashable {
        case photoUpload       // no GPS data found in the uploaded photo
        case currentLocation   // couldn't read the device's location

        var title: String {
            switch self {
            case .photoUpload:     "We can't read the location"
            case .currentLocation: "We can't read your location"
            }
        }

        var message: String {
            switch self {
            case .photoUpload:     "We couldn't find GPS data in this photo"
            case .currentLocation: "We couldn't find GPS data on your location"
            }
        }

        var primaryTitle: String {
            switch self {
            case .photoUpload:     "Use my current location"
            case .currentLocation: "Upload photo first"
            }
        }
    }

    var source: Source = .photoUpload
    var onPrimary: () -> Void = {}
    var onPickOnMap: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.sm) {
                icon

                Text(source.title)
                    .font(.sHeadingL)
                    .foregroundStyle(Color.sTextPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(source.message)
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
        .navigationTitle("")
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
            SPrimaryButton(title: source.primaryTitle) {
                onPrimary()
            }

            SSecondaryButton(title: "Pick location on map") {
                onPickOnMap()
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

#Preview("Photo upload failed") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            LocationErrorSheet(source: .photoUpload)
        }
}

#Preview("Current location failed") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            LocationErrorSheet(source: .currentLocation)
        }
}

#Preview("Photo upload failed — Dark") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            LocationErrorSheet(source: .photoUpload)
        }
        .preferredColorScheme(.dark)
}
