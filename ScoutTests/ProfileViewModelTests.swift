import Testing
import Foundation
@testable import Scout

/// Covers `ProfileViewModel`: default tab, the profile + paginated reviews load,
/// the `hasMore`/cursor bookkeeping, and failure handling.
@MainActor
struct ProfileViewModelTests {

    // MARK: - Stub service

    /// Serves a fixed profile + a sequence of review pages keyed by cursor, or throws.
    private struct StubService: UserService {
        var profile: UserProfile = .sample
        var pages: [String?: PaginatedReviews] = [:]
        var error: Error?

        func fetchCurrentUser() async throws -> UserProfile {
            if let error { throw error }
            return profile
        }

        func fetchMyReviews(limit: Int, cursor: String?) async throws -> PaginatedReviews {
            if let error { throw error }
            return pages[cursor] ?? PaginatedReviews(items: [], limit: limit, nextCursor: nil)
        }
    }

    private func review(_ id: String) -> Review {
        Review(id: id, spotId: "s", spotName: "Spot", userId: "u", photoUrls: [],
               overallRating: 4, notes: nil, bestTimeOfDay: [], bestSeason: [],
               accessLevel: nil, entranceFee: nil, crowdLevel: nil,
               gearRecommendations: nil, compositionHints: nil,
               permitRequired: nil, droneAllowed: nil, tripodAllowed: nil,
               createdAt: Date())
    }

    private func makeVM(_ service: UserService) -> ProfileViewModel {
        ProfileViewModel(userService: service)
    }

    // MARK: - Tab

    @Test func defaultsToReviewsTab() {
        #expect(makeVM(StubService()).selectedTab == .reviews)
    }

    @Test func tabTitles() {
        #expect(ProfileViewModel.Tab.photos.title == "Photos")
        #expect(ProfileViewModel.Tab.reviews.title == "Reviews")
    }

    // MARK: - Load

    @Test func loadPopulatesProfileAndFirstPage() async {
        let service = StubService(
            profile: UserProfile(id: "u1", displayName: "Marcus Chen",
                                 location: "SF", photoURL: nil, reviewCount: 42),
            pages: [nil: PaginatedReviews(items: [review("a"), review("b")], limit: 10, nextCursor: "p2")]
        )
        let vm = makeVM(service)
        await vm.load()

        #expect(vm.state == .loaded)
        #expect(vm.profile?.reviewCount == 42)
        #expect(vm.reviews.map(\.id) == ["a", "b"])
        #expect(vm.hasMore)
    }

    @Test func loadWithoutCursorHasNoMore() async {
        let service = StubService(pages: [
            nil: PaginatedReviews(items: [review("a")], limit: 10, nextCursor: nil)
        ])
        let vm = makeVM(service)
        await vm.load()

        #expect(vm.hasMore == false)
    }

    @Test func loadFailureSetsFailedState() async {
        let vm = makeVM(StubService(error: SpotServiceError.invalidResponse))
        await vm.load()

        if case .failed = vm.state {} else {
            Issue.record("Expected .failed, got \(vm.state)")
        }
        #expect(vm.profile == nil)
        #expect(vm.reviews.isEmpty)
    }

    // MARK: - Load more

    @Test func loadMoreAppendsNextPageAndClearsHasMore() async {
        let service = StubService(pages: [
            nil: PaginatedReviews(items: [review("a")], limit: 10, nextCursor: "p2"),
            "p2": PaginatedReviews(items: [review("b")], limit: 10, nextCursor: nil)
        ])
        let vm = makeVM(service)
        await vm.load()
        await vm.loadMore()

        #expect(vm.reviews.map(\.id) == ["a", "b"])
        #expect(vm.hasMore == false)
    }

    @Test func loadMoreIsNoOpWhenNoMorePages() async {
        let service = StubService(pages: [
            nil: PaginatedReviews(items: [review("a")], limit: 10, nextCursor: nil)
        ])
        let vm = makeVM(service)
        await vm.load()
        await vm.loadMore()

        #expect(vm.reviews.map(\.id) == ["a"])
    }
}
