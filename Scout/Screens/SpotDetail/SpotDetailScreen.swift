import SwiftUI

struct SpotDetailScreen: View {
    @State private var viewModel: SpotDetailViewModel
    @State private var showSaveSheet = false
    @Environment(\.dismiss) private var dismiss
    /// Optional so previews (which don't inject them) don't crash.
    @Environment(TabBarVisibility.self) private var tabBarVisibility: TabBarVisibility?
    @Environment(SavedStore.self) private var savedStore: SavedStore?
    @Environment(AuthGate.self) private var authGate: AuthGate?

    init(spotID: String, service: SpotService = AppServices.spot) {
        _viewModel = State(initialValue: SpotDetailViewModel(spotID: spotID, service: service))
    }

    var body: some View {
        ZStack(alignment: .center) {
            Color.sBackground.ignoresSafeArea()

            switch viewModel.state {
            case .idle, .loading:
                SpotDetailSkeleton()
            case .failed(let message):
                SErrorStateView(message: message) {
                    Task { await viewModel.load() }
                }
            case .loaded:
                if let detail = viewModel.detail {
                    content(detail)
                }
            }
        }
        .overlay(alignment: .top) {
            SpotDetailControls(
                isSaved: savedStore?.isSaved(viewModel.detail?.id ?? "") ?? false,
                shareURL: viewModel.detail.map { Self.mapsURL(for: $0) },
                spotName: viewModel.detail?.name ?? "",
                onBack: { dismiss() },
                onTapSave: { gateSave { showSaveSheet = true } }
            )
            .padding(.top, Spacing.xs)
        }
        .overlay(alignment: .bottom) {
            if let detail = viewModel.detail {
                SpotDirectionsBar(
                    latitude: detail.publicLat,
                    longitude: detail.publicLng,
                    name: detail.name
                )
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSaveSheet) {
            if let detail = viewModel.detail {
                SaveToListSheet(spotID: detail.id)
            }
        }
        .onAppear { tabBarVisibility?.requestHidden() }
        .onDisappear { tabBarVisibility?.releaseHidden() }
        .task {
            if viewModel.state == .idle { await viewModel.load() }
        }
    }

    /// Saving needs an account: run directly when the gate isn't injected
    /// (previews), otherwise present sign-in first when signed out.
    private func gateSave(_ action: @escaping () -> Void) {
        guard let authGate else { action(); return }
        authGate.require(action)
    }

    // MARK: - Content

    private func content(_ detail: SpotDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                SpotDetailHero(photos: detail.heroPhotos)

                VStack(alignment: .leading, spacing: Spacing.xl) {
                    SpotTitleBlock(name: detail.name, subtitle: detail.subtitle, rating: detail.avgRating, reviewCount: detail.reviewCount)

                    SpotQuickFacts(detail: detail)

                    SpotAISummary(summary: detail.aiSummary)

                    SpotLookAround(latitude: detail.publicLat, longitude: detail.publicLng)

                    SpotShootingTimes(times: detail.shootingTimes)

                    SpotGearComposition(
                        gearRecommendations: detail.recentGearRecommendations,
                        compositionHints: detail.recentCompositionHints
                    )

                    SpotAccessLogistics(
                        permitRequired: detail.modePermitRequired,
                        droneAllowed: detail.modeDroneAllowed,
                        tripodAllowed: detail.modeTripodAllowed
                    )

                    SpotReviewsSection(spotName: detail.name, viewModel: viewModel)
                }
                .padding(.horizontal, Spacing.lg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)   // anchor to scroll width
            .padding(.bottom, 96)   // room for the sticky Leave-a-review bar
        }
        .ignoresSafeArea(edges: .top)
    }

    /// An Apple Maps link to the spot's public location, used by the Share button.
    private static func mapsURL(for detail: SpotDetail) -> URL {
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [
            URLQueryItem(name: "ll", value: "\(detail.publicLat),\(detail.publicLng)"),
            URLQueryItem(name: "q", value: detail.name)
        ]
        return components.url ?? URL(string: "https://maps.apple.com/")!
    }
}

// MARK: - Preview

#Preview("Spot Detail") {
    NavigationStack {
        SpotDetailScreen(spotID: "1", service: MockSpotService())
    }
}

#Preview("Spot Detail — Dark") {
    NavigationStack {
        SpotDetailScreen(spotID: "1", service: MockSpotService())
    }
    .preferredColorScheme(.dark)
}
