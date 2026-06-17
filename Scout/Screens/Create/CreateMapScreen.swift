import SwiftUI
import MapKit

/// Create-flow map step: position the spot with a fixed centre pin (pan the map
/// under it), see nearby existing spots, and either review one of those or
/// continue with a new spot. Reuses the shared map components.
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

            CreateCenterPin()
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
                    commitPin()
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
                    NearbySpotMarker(name: spot.name,
                                     isSelected: viewModel.selectedSpotID == spot.id)
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

    // MARK: - Chrome

    private var chrome: some View {
        VStack(spacing: 0) {
            SNavHeader(title: "Confirm Location")
            STipBanner(verbatim: viewModel.banner.text)

            HStack {
                Spacer()
                MapPhotoThumbnail(image: thumbnail)
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

            ConfirmLocationFooter(
                regionText: viewModel.regionText,
                ctaTitle: viewModel.ctaTitle,
                onContinue: continueTapped
            )
        }
    }

    // MARK: - Actions

    /// Bottom-CTA action: review the selected existing spot (straight to the form,
    /// no Name Picker), or continue with a new spot (fetch nearby place names, then
    /// open the Name Picker).
    private func continueTapped() {
        if let spot = viewModel.selectedSpot {
            commitPin()
            review.reviewExisting(id: spot.id, name: spot.name)
            proceed()
        } else {
            viewModel.loadNearbyPlaces()   // fetch only when needed
            showNameSpot = true            // Confirm New → Name Picker
        }
    }

    /// Writes the final pin (coordinate + region) into the flow's review draft —
    /// shared by both the existing-spot and new-spot paths before they proceed.
    private func commitPin() {
        review.place(coordinate: viewModel.pinCoordinate, regionText: viewModel.regionText)
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
