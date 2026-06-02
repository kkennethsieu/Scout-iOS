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

                recenterButton
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
                    SpotMapMarker(isSelected: viewModel.selectedSpotID == spot.id)
                }
                .tag(spot.id)
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

    // MARK: - Recenter button

    private var recenterButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                MapRecenterButton(status: location.authorizationStatus) {
                    if let coordinate = location.coordinate {
                        viewModel.recenter(on: coordinate)
                    } else {
                        location.start()   // not yet authorized — prompt / retry
                    }
                }
            }
        }
        .padding(.trailing, Spacing.lg)
        // Sit above the selected-spot preview card when it's showing.
        .padding(.bottom, viewModel.selectedSpot == nil ? Spacing.xl : 116)
        .animation(.spring(duration: 0.3), value: viewModel.selectedSpotID)
    }
}

// MARK: - User location dot

/// The "you are here" marker. Brand-accent dot with a soft accuracy halo.
private struct UserLocationDot: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.sAccent.opacity(0.18))
                .frame(width: 30, height: 30)
            Circle()
                .fill(Color.sAccent)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(.white, lineWidth: 2.5))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
        }
    }
}

// MARK: - Recenter button

/// Floating map control that snaps the camera back to the user's location.
private struct MapRecenterButton: View {
    var status: CLAuthorizationStatus
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: glyph)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isDenied ? Color.sTextSecondary : Color.sAccent)
                .frame(width: 46, height: 46)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var isDenied: Bool {
        status == .denied || status == .restricted
    }

    private var glyph: String {
        isDenied ? "location.slash" : "location.fill"
    }
}

// MARK: - Search this area button

/// Floating pill that re-queries the backend for the currently visible map area.
private struct SearchAreaButton: View {
    var isLoading: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text("Search this area")
            }
            .font(.sHeadingS)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Capsule().fill(Color.sAccent))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview("Map") {
    MapScreen(service: MockSpotService())
}
