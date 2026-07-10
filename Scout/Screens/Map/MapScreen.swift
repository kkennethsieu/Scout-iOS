import SwiftUI
import MapKit

/// Map tab: spots from the same `SpotSummary` feed as Explore, dropped as pins.
/// Tapping a pin reveals a preview card that pushes the full Spot Detail.
struct MapScreen: View {
    @State private var viewModel: MapViewModel
    @State private var location = LocationManager()

    init(service: SpotService = AppServices.spot) {
        _viewModel = State(initialValue: MapViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                map

                VStack(spacing: Spacing.sm) {
                    PlaceSearchField(placeholder: "Map area",
                                     bias: location.coordinate) { place in
                        viewModel.moveCamera(to: place.region)
                    }

                    if viewModel.showSearchArea {
                        SearchAreaButton(isLoading: viewModel.isSearchingArea) {
                            viewModel.searchVisibleArea()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let text = viewModel.fallbackBannerText {
                        STipBanner(icon: "location.slash", verbatim: text)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
                .animation(.spring(duration: 0.3), value: viewModel.showSearchArea)
                .animation(.spring(duration: 0.3), value: viewModel.fallbackBannerText)

                overlay

                controlButtons
            }
            .navigationDestination(for: SpotSummary.self) { spot in
                SpotDetailScreen(spotID: spot.id)
            }
            .task {
                location.start()
                await viewModel.applyUserLocation(location.coordinate)
                if viewModel.state == .idle { await viewModel.load() }
            }
            .onChange(of: location.coordinate?.latitude) { _, _ in
                Task { await viewModel.applyUserLocation(location.coordinate) }
            }
            .enableSwipeBack()
        }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedSpotID) {
            if let coordinate = location.coordinate {
                Annotation("You", coordinate: coordinate) {
                    UserLocationDot()
                }
                .annotationTitles(.hidden)
            }

            SpotPins(spots: viewModel.spots, selectedID: viewModel.selectedSpotID)
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .ignoresSafeArea(edges: .top)
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.cameraMoved(to: context.region)
        }
    }

    // MARK: - Overlays (loading / error / selected preview)

    @ViewBuilder
    private var overlay: some View {
        switch viewModel.state {
        case .idle, .loading:
            SLoadingState()
        case .failed(let message):
            SErrorStateView(message: message){
                Task { await viewModel.load() }
            }
            .padding(Spacing.lg)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(Color.sBackground))
            .padding(Spacing.lg)
        case .loaded:
            preview
        }
    }

    private var preview: some View {
        SpotPreviewOverlay(
            spot: viewModel.selectedSpot,
            distance: viewModel.selectedSpot.flatMap { viewModel.distanceText(for: $0) },
            bottomPadding: Spacing.xxxl + Spacing.lg
        )
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        let isDenied = location.authorizationStatus == .denied
            || location.authorizationStatus == .restricted
        return VStack {
            Spacer()
            HStack {
                Spacer()
                MapControlButton(
                    systemImage: isDenied ? "location.slash" : "location.fill",
                    tint: isDenied ? Color.sTextSecondary : Color.sAccent
                ) {
                    if let coordinate = location.coordinate {
                        viewModel.recenter(on: coordinate)
                    } else {
                        location.requestPermission()   // not yet authorized — prompt / retry
                    }
                }
            }
        }
        .padding(.trailing, Spacing.lg)
        // Sit above the selected-spot preview card when it's showing.
        .padding(.bottom, viewModel.selectedSpot == nil ? 120 : 160)
        .animation(.spring(duration: 0.3), value: viewModel.selectedSpotID)
    }
}

// MARK: - Preview

#Preview("MapScreen") {
    MapScreen(service: MockSpotService())
}
