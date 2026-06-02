import SwiftUI

/// Hosts the entire create-spot flow as a single sheet containing a
/// `NavigationStack`, driven by `CreateSpotViewModel`. Apply it once (e.g. on
/// `MainTabView`) and toggle `isPresented`; the flow owns everything else.
struct CreateSpotFlow: ViewModifier {
    @Binding var isPresented: Bool

    @State private var viewModel: CreateSpotViewModel
    @State private var location = LocationManager()

    init(isPresented: Binding<Bool>, service: SpotService = AppServices.spot) {
        _isPresented = isPresented
        _viewModel = State(initialValue: CreateSpotViewModel(service: service))
    }

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented, onDismiss: viewModel.reset) {
            NavigationStack(path: $viewModel.path) {
                ShareSpotSheet(
                    onUploadPhotos: { data in await viewModel.pickedPhoto(data) },
                    onCurrentLocation: { viewModel.choseCurrentLocation(coordinate: location.coordinate) }
                )
                .navigationDestination(for: CreateStep.self) { step in
                    destination(for: step)
                }
            }
            .presentationDetents(viewModel.detents, selection: $viewModel.detent)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Radius.xl)
            .task { location.start() }
            .onChange(of: viewModel.path) { _, _ in viewModel.syncDetent() }
            .onChange(of: viewModel.requestClose) { _, close in
                if close { isPresented = false }
            }
        }
    }

    @ViewBuilder
    private func destination(for step: CreateStep) -> some View {
        switch step {
        case .confirmLocation:
            ConfirmLocationPlaceholder()
        case .nearbySpots(let spots):
            NearbySpotsSheet(
                spots: spots,
                onSelect: { viewModel.selectedNearby($0) },
                onCreateNew: { viewModel.createNew() }
            )
        case .sameSpot(let spot):
            SameSpotSheet(
                spot: spot,
                onConfirm: { viewModel.confirmedSame($0) },
                onDifferentSpot: { viewModel.differentSpot() }
            )
        case .locationError(let source):
            LocationErrorSheet(
                source: source,
                onPrimary: { viewModel.errorPrimary() },
                onPickOnMap: { viewModel.pickOnMap() }
            )
        }
    }
}

// MARK: - Phase 2 placeholder

/// Stand-in for the precise-location map screen (Phase 2).
private struct ConfirmLocationPlaceholder: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 40))
                .foregroundStyle(Color.sAccent)
            Text("Confirm location")
                .font(.sHeadingL)
                .foregroundStyle(Color.sTextPrimary)
            Text("Precise location picker coming soon.")
                .font(.sBody)
                .foregroundStyle(Color.sTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sBackground)
        .navigationTitle("Confirm location")
    }
}
