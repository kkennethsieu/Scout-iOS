import SwiftUI
import MapKit

/// Map tab: spots from the same `SpotSummary` feed as Explore, dropped as pins.
/// Tapping a pin reveals a preview card that pushes the full Spot Detail.
struct MapScreen: View {
    @State private var viewModel: MapViewModel

    init(service: SpotService = AppServices.spot) {
        _viewModel = State(initialValue: MapViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                map

                SSearchBar(text: $viewModel.searchText,
                           placeholder: "Map area",
                           showsFilter: false)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)

                overlay
            }
            .navigationDestination(for: SpotSummary.self) { spot in
                SpotDetailScreen(spotID: spot.id)
            }
            .task {
                if viewModel.state == .idle { await viewModel.load() }
            }
        }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedSpotID) {
            ForEach(viewModel.spots) { spot in
                Annotation(spot.name, coordinate: spot.coordinate) {
                    SpotMapMarker(isSelected: viewModel.selectedSpotID == spot.id)
                }
                .tag(spot.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .ignoresSafeArea() 
    }

    // MARK: - Overlays (loading / error / selected preview)

    @ViewBuilder
    private var overlay: some View {
        switch viewModel.state {
        case .idle, .loading:
            SLoadingState()
        case .failed(let message):
            SErrorStateView(message: message) {
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
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.selectedSpotID)
    }
}

// MARK: - Preview

#Preview("Map") {
    MapScreen(service: MockSpotService())
}
