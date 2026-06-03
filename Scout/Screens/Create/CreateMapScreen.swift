import SwiftUI
import MapKit

/// Create-flow map step: position the spot with a fixed centre pin (pan the map
/// under it), see nearby existing spots, and either review one of those or
/// continue with a new spot. Reuses the shared map components.
///
/// Not wired — the CTA branches are `// TODO` stubs.
struct CreateMapScreen: View {
    var photoURL: URL?

    @State private var viewModel: CreateMapViewModel
    @State private var location = LocationManager()
    @Environment(\.dismiss) private var dismiss

    init(entry: CreateMapViewModel.Entry,
         photoURL: URL? = nil,
         service: SpotService = AppServices.spot) {
        self.photoURL = photoURL
        _viewModel = State(initialValue: CreateMapViewModel(entry: entry, service: service))
    }

    var body: some View {
        ZStack(alignment: .top) {
            map.ignoresSafeArea()

            centerPin
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

            chrome
        }
        .onAppear {
            viewModel.start()
            location.start()
        }
        // Adopt the device location once, only in the no-photo-location fallback.
        .onChange(of: location.coordinate?.latitude) { _, _ in
            if let coordinate = location.coordinate {
                viewModel.useCurrentLocation(coordinate)
            }
        }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedSpotID) {
            ForEach(viewModel.nearbySpots) { spot in
                Annotation(spot.name, coordinate: spot.coordinate) {
                    nearbyMarker(spot)
                }
                .tag(spot.id)
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(viewModel.isHybrid ? .hybrid : .standard(pointsOfInterest: .excludingAll))
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.cameraIdled(at: context.region)
        }
    }

    private func nearbyMarker(_ spot: SpotSummary) -> some View {
        VStack(spacing: 2) {
            SpotMapMarker(isSelected: viewModel.selectedSpotID == spot.id)
            Text(spot.name)
                .font(.sCaption)
                .foregroundStyle(Color.sTextPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 2)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                .fixedSize()
        }
    }

    // MARK: - Centre pin

    private var centerPin: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(Color.sAccent, lineWidth: 3))
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

            dragHint.offset(y: -36)
        }
    }

    private var dragHint: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.system(size: 11, weight: .semibold))
            Text("Drag to adjust")
                .font(.sCaption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(.black.opacity(0.78), in: Capsule())
        .fixedSize()
    }

    // MARK: - Chrome

    private var chrome: some View {
        VStack(spacing: 0) {
            header
            bannerBar

            HStack {
                Spacer()
                photoThumbnail
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            Spacer()

            HStack {
                Spacer()
                VStack(spacing: Spacing.sm) {
                    MapControlButton(systemImage: "scope") {
                        viewModel.recenterOnPin()
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

    private var bannerBar: some View {
        Text(viewModel.banner.text)
            .font(.sBodyS)
            .foregroundStyle(Color.sTextSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Color.sSurface)
    }

    @ViewBuilder
    private var photoThumbnail: some View {
        if let photoURL {
            Color.sBorderSubtle
                .overlay {
                    AsyncImage(url: photoURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "photo").foregroundStyle(Color.sTextTertiary)
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
    }

    private var footer: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("SPOTTED IN")
                        .font(.sCaption)
                        .foregroundStyle(Color.sTextTertiary)
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

            SPrimaryButton(title: viewModel.ctaTitle) {
                if viewModel.selectedSpot != nil {
                    // TODO: open the Review form for the selected existing spot
                } else {
                    // TODO: open the Name Picker for a new spot
                }
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

#Preview("Create Map — photo location") {
    CreateMapScreen(
        entry: .photo(CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)),
        photoURL: URL(string: "https://picsum.photos/seed/emerald/300/300"),
        service: MockSpotService()
    )
}

#Preview("Create Map — no photo location") {
    CreateMapScreen(entry: .photo(nil), service: MockSpotService())
}

#Preview("Create Map — current location") {
    CreateMapScreen(
        entry: .currentLocation(CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)),
        service: MockSpotService()
    )
}
