import SwiftUI
import MapKit

/// Map-based location picker in the create flow. The pin stays fixed at the
/// screen centre; the user pans the map under it to position the spot, and the
/// region readout updates live. Not wired — "Confirm & Continue" just dismisses.
struct ConfirmLocationScreen: View {
    var source: String = "Manual"
    var photoURL: URL? = URL(string: "https://picsum.photos/seed/emerald/300/300")

    @State private var viewModel = ConfirmLocationViewModel()
    @State private var location = LocationManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            map

            centerPin
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

            chrome
        }
        .onAppear {
            viewModel.start()
            location.start()
        }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $viewModel.cameraPosition) { }
            .mapStyle(viewModel.mapStyle)
            .ignoresSafeArea()
            .onMapCameraChange(frequency: .onEnd) { context in
                viewModel.cameraIdled(at: context.region)
            }
    }

    // MARK: - Centre pin

    private var centerPin: some View {
        ZStack {
            // Target reticle marking the exact selected point.
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                Circle()
                    .stroke(Color.sAccent, lineWidth: 3)
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(Color.sAccent)
                    .frame(width: 8, height: 8)
            }

            dragHint
                .offset(y: 34)
        }
    }

    private var dragHint: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "hand.draw")
                .font(.system(size: 11, weight: .semibold))
            Text("Drag to adjust")
                .font(.sCaption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(.black.opacity(0.75), in: Capsule())
        .fixedSize()
    }

    // MARK: - Chrome (header, floating cards, controls, footer)

    private var chrome: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: Spacing.md) {
                SSearchBar(text: $viewModel.searchText,
                           placeholder: "Search for a location…",
                           showsFilter: false)

                HStack(alignment: .top) {
                    selectedLocationCallout
                    Spacer(minLength: Spacing.md)
                    photoThumbnail
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)

            Spacer()

            HStack {
                Spacer()
                VStack(spacing: Spacing.sm) {
                    MapControlButton(systemImage: "location.fill") {
                        if let coordinate = location.coordinate {
                            viewModel.recenter(on: coordinate)
                        } else {
                            location.start()
                        }
                    }
                    MapControlButton(systemImage: "square.2.stack.3d") {
                        viewModel.toggleStyle()
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.md)

            footer
        }
    }

    private var header: some View {
        ZStack {
            Text("Confirm Location")
                .font(.sHeadingM)
                .foregroundStyle(Color.sTextPrimary)

            SBackButton()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color.sBackground)
        .overlay(alignment: .bottom) {
            Divider().background(Color.sBorderSubtle)
        }
    }

    private var selectedLocationCallout: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "mappin")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.sAccent)

            VStack(alignment: .leading, spacing: 1) {
                Text(source.uppercased())
                    .font(.sCaption)
                    .foregroundStyle(Color.sTextTertiary)
                Text("Selected Location")
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextPrimary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private var photoThumbnail: some View {
        Color.sBorderSubtle
            .overlay {
                AsyncImage(url: photoURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "photo")
                        .foregroundStyle(Color.sTextTertiary)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(.white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }

    private var footer: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Spotted in")
                        .font(.sBodyS)
                        .foregroundStyle(Color.sTextSecondary)
                    Text(viewModel.regionText)
                        .font(.sHeadingM)
                        .foregroundStyle(Color.sTextPrimary)
                }

                Spacer()

                Button {
                    // TODO: explain how the location was determined
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.sTextTertiary)
                }
                .buttonStyle(.plain)
            }

            SPrimaryButton(title: "Confirm & Continue") {
                // TODO: hand the chosen coordinate to the create flow
                dismiss()
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(Color.sBackground)
        .overlay(alignment: .top) {
            Divider().background(Color.sBorderSubtle)
        }
    }
}

// MARK: - Preview

#Preview("Confirm Location") {
    ConfirmLocationScreen()
}
