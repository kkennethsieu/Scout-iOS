import SwiftUI
import MapKit

/// Create-flow map step: position the spot with a fixed centre pin (pan the map
/// under it), see nearby existing spots, and either review one of those or
/// continue with a new spot. Reuses the shared map components.
///
/// Not wired — the CTA branches are `// TODO` stubs.
struct CreateMapScreen: View {
    let photoData: Data?
    /// The flow-owned accumulator. The map step writes its decision (final
    /// coordinate + existing/new target) into it, then calls `proceed`.
    let review: CreateReviewViewModel
    /// Advances the flow to the review form (pushes onto the NavigationStack).
    let proceed: () -> Void

    @State private var viewModel: CreateMapViewModel
    @State private var location = LocationManager()
    /// Decoded once from `photoData` so panning (which re-renders) doesn't
    /// re-decode the full-size photo every frame.
    @State private var thumbnail: Image?
    @State private var showNameSpot = false
    @Environment(\.dismiss) private var dismiss

    init(entry: CreateMapViewModel.Entry,
         photoData: Data? = nil,
         service: SpotService = AppServices.spot,
         review: CreateReviewViewModel,
         proceed: @escaping () -> Void) {
        self.photoData = photoData
        self.review = review
        self.proceed = proceed
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
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.start()
            location.start()
            if thumbnail == nil, let photoData {
                thumbnail = Image(data: photoData)
            }
        }
        // Adopt the device location once, only in the no-photo-location fallback.
        .onChange(of: location.coordinate?.latitude) { _, _ in
            if let coordinate = location.coordinate {
                viewModel.useCurrentLocation(coordinate)
            }
        }
        .sheet(isPresented: $showNameSpot) {
            NameSpotSheet(
                placeNames: viewModel.nearbyPlaceNames,
                onSelect: { name in
                    review.place(coordinate: viewModel.pinCoordinate, regionText: viewModel.regionText)
                    review.setNewSpotName(name)
                    proceed()
                }
            )
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
        if let thumbnail {
            thumbnail
                .resizable()
                .scaledToFill()
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
                if let spot = viewModel.selectedSpot {
                    // Existing spot → straight to the review form, no Name Picker.
                    review.place(coordinate: viewModel.pinCoordinate, regionText: viewModel.regionText)
                    review.reviewExisting(id: spot.id, name: spot.name)
                    proceed()
                } else {
                    viewModel.loadNearbyPlaces()   // fetch only when needed
                    showNameSpot = true            // Confirm New → Name Picker
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

private func previewReview() -> CreateReviewViewModel {
    CreateReviewViewModel(target: .newSpot(name: ""))
}

#Preview("Create Map — photo location") {
    CreateMapScreen(
        entry: .photo(CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)),
        service: MockSpotService(),
        review: previewReview(),
        proceed: {}
    )
}

#Preview("Create Map — no photo location") {
    CreateMapScreen(entry: .photo(nil), service: MockSpotService(),
                    review: previewReview(), proceed: {})
}

#Preview("Create Map — current location") {
    CreateMapScreen(
        entry: .currentLocation(CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)),
        service: MockSpotService(),
        review: previewReview(),
        proceed: {}
    )
}
