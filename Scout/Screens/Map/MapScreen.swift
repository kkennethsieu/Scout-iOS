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
                    SSearchBar(text: $viewModel.searchText,
                               placeholder: "Map area",
                               showsFilter: false)

                    if viewModel.showSearchArea {
                        SearchAreaButton(isLoading: viewModel.isSearchingArea) {
                            viewModel.searchVisibleArea()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
                .animation(.spring(duration: 0.3), value: viewModel.showSearchArea)

                overlay

                controlButtons
            }
            .navigationDestination(for: SpotSummary.self) { spot in
                SpotDetailScreen(spotID: spot.id)
            }
            .task {
                if viewModel.state == .idle { await viewModel.load() }
            }
            .onAppear { location.start() }
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

            ForEach(viewModel.spots) { spot in
                Annotation(spot.name, coordinate: spot.coordinate) {
                    NearbySpotMarker(name: spot.name,
                                     isSelected: viewModel.selectedSpotID == spot.id)
                }
                .tag(spot.id)
                .annotationTitles(.hidden)
            }
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

    @ViewBuilder
    private var preview: some View {
        VStack {
            Spacer()
            if let spot = viewModel.selectedSpot {
                NavigationLink(value: spot) {
                    MapSpotPreview(spot: spot, distance: viewModel.distanceText(for: spot))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.selectedSpotID)
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
