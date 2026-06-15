import SwiftUI

struct SpotDetailScreen: View {
    @State private var viewModel: SpotDetailViewModel
    @State private var showSaveSheet = false
    @Environment(\.dismiss) private var dismiss
    /// Optional so previews (which don't inject them) don't crash.
    @Environment(TabBarVisibility.self) private var tabBarVisibility: TabBarVisibility?
    @Environment(SavedStore.self) private var savedStore: SavedStore?

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
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSaveSheet) {
            if let detail = viewModel.detail {
                SaveToListSheet(spotID: detail.id)
            }
        }
        .onAppear { tabBarVisibility?.isHidden = true }
        .onDisappear { tabBarVisibility?.isHidden = false }
        .task {
            if viewModel.state == .idle { await viewModel.load() }
        }
    }

    // MARK: - Content

    private func content(_ detail: SpotDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                SpotDetailHero(
                    photos: detail.heroPhotos,
                    isSaved: savedStore?.isSaved(detail.id) ?? false,
                    onBack: { dismiss() },
                    onShare: { /* TODO: share sheet */ },
                    onTapSave: { showSaveSheet = true }
                )

                VStack(alignment: .leading, spacing: Spacing.xl) {
                    SpotTitleBlock(name: detail.name, subtitle: detail.subtitle, rating: detail.avgRating, reviewCount: detail.reviewCount)

                    SpotQuickFacts(detail: detail)

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

                    SpotReviewsSection(
                        reviews: viewModel.reviews,
                        countText: viewModel.reviewCountText,
                        onViewAll: { /* TODO: navigate to all reviews */ }
                    )
                }
                .padding(.horizontal, Spacing.lg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)   // anchor to scroll width
            .padding(.bottom, 96)   // room for the sticky Leave-a-review bar
        }
        .ignoresSafeArea(edges: .top)
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
