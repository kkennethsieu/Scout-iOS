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

        var deleteError: Error?
        func deleteReview(id: String) async throws {
            if let deleteError { throw deleteError }
        }

        var accountDeleteError: Error?
        func deleteAccount() async throws {
            if let accountDeleteError { throw accountDeleteError }
        }
    }

    /// A service whose `deleteReview` blocks until `release` yields, so a test can
    /// observe the in-flight `deletingReviewID` mid-delete.
    private struct GatedDeleteService: UserService {
        var profile: UserProfile = .sample
        var firstPage: PaginatedReviews
        let release: AsyncStream<Void>

        func fetchCurrentUser() async throws -> UserProfile { profile }
        func fetchMyReviews(limit: Int, cursor: String?) async throws -> PaginatedReviews { firstPage }
        func deleteReview(id: String) async throws {
            var iterator = release.makeAsyncIterator()
            _ = await iterator.next()
        }
        func deleteAccount() async throws {}
    }

    private func review(_ id: String) -> Review {
        Review(id: id, spotId: "s", spotName: "Spot",
               publicLat: 0, publicLng: 0, city: "Seattle", adminArea: "WA",
               userId: "u", photoUrls: [],
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
                                 homeCity: "San Francisco", homeCountry: "CA",
                                 photoUrl: nil, reviewCount: 42),
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

    // MARK: - Delete

    @Test func deleteRemovesReviewAndDecrementsCount() async {
        let service = StubService(
            profile: UserProfile(id: "u1", displayName: "Marcus Chen",
                                 homeCity: "SF", homeCountry: "CA",
                                 photoUrl: nil, reviewCount: 2),
            pages: [nil: PaginatedReviews(items: [review("a"), review("b")], limit: 10, nextCursor: nil)]
        )
        let vm = makeVM(service)
        await vm.load()

        await vm.deleteReview(review("a"))

        #expect(vm.reviews.map(\.id) == ["b"])
        #expect(vm.profile?.reviewCount == 1)
        #expect(vm.deleteError == nil)
    }

    @Test func deleteFailureSetsErrorAndKeepsReview() async {
        var service = StubService(
            profile: UserProfile(id: "u1", displayName: "Marcus Chen",
                                 homeCity: "SF", homeCountry: "CA",
                                 photoUrl: nil, reviewCount: 2),
            pages: [nil: PaginatedReviews(items: [review("a"), review("b")], limit: 10, nextCursor: nil)]
        )
        service.deleteError = SpotServiceError.invalidResponse
        let vm = makeVM(service)
        await vm.load()

        await vm.deleteReview(review("a"))

        #expect(vm.reviews.map(\.id) == ["a", "b"])
        #expect(vm.profile?.reviewCount == 2)
        #expect(vm.deleteError != nil)
    }

    @Test func deletingReviewIDTracksInFlightDelete() async {
        let release = AsyncStream<Void>.makeStream()
        let service = GatedDeleteService(
            firstPage: PaginatedReviews(items: [review("a")], limit: 10, nextCursor: nil),
            release: release.stream
        )
        let vm = makeVM(service)
        await vm.load()

        let task = Task { await vm.deleteReview(review("a")) }
        await Task.yield()
        #expect(vm.deletingReviewID == "a")

        // Let the delete finish, then it should clear and remove the review.
        release.continuation.yield(())
        release.continuation.finish()
        await task.value

        #expect(vm.deletingReviewID == nil)
        #expect(vm.reviews.isEmpty)
    }

    // MARK: - Account deletion

    @Test func deleteAccountSucceeds() async {
        let vm = makeVM(StubService())

        let ok = await vm.deleteAccount()

        #expect(ok)
        #expect(vm.accountDeleteError == nil)
        #expect(!vm.isDeletingAccount)
    }

    @Test func deleteAccountFailureSetsErrorAndReturnsFalse() async {
        var service = StubService()
        service.accountDeleteError = SpotServiceError.invalidResponse
        let vm = makeVM(service)

        let ok = await vm.deleteAccount()

        #expect(!ok)
        #expect(vm.accountDeleteError != nil)
        #expect(!vm.isDeletingAccount)
    }
}
