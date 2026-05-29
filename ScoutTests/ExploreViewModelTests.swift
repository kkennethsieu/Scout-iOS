import Testing
import Foundation
@testable import Scout

/// A SpotService stub returning a fixed list, so view-model tests don't depend
/// on the mock's artificial latency or sample contents.
private struct StubSpotService: SpotService {
    var spots: [SpotSummary] = []
    var detail: SpotDetail = .sample
    var reviews: [Review] = []
    var error: Error?

    func fetchSpots() async throws -> [SpotSummary] {
        if let error { throw error }
        return spots
    }
    func fetchSpotDetail(id: String) async throws -> SpotDetail {
        if let error { throw error }
        return detail
    }
    func fetchReviews(spotID: String) async throws -> [Review] {
        if let error { throw error }
        return reviews
    }
}

private struct StubError: LocalizedError {
    var errorDescription: String? { "stub failure" }
}

@MainActor
struct ExploreViewModelTests {

    @Test func loadPopulatesSpotsAndMarksLoaded() async {
        let service = StubSpotService(spots: [.sample(id: "1"), .sample(id: "2")])
        let vm = ExploreViewModel(service: service)

        await vm.load()

        #expect(vm.state == .loaded)
        #expect(vm.spots.count == 2)
    }

    @Test func loadFailureSetsFailedState() async {
        let service = StubSpotService(error: StubError())
        let vm = ExploreViewModel(service: service)

        await vm.load()

        #expect(vm.state == .failed("stub failure"))
        #expect(vm.spots.isEmpty)
    }

    @Test func searchFiltersByNameCaseInsensitively() async {
        let service = StubSpotService(spots: [
            .sample(id: "1", name: "Cedar Cathedral"),
            .sample(id: "2", name: "Mirror Reservoir")
        ])
        let vm = ExploreViewModel(service: service)
        await vm.load()

        vm.searchText = "mirror"

        #expect(vm.filteredSpots.count == 1)
        #expect(vm.filteredSpots.first?.name == "Mirror Reservoir")
    }

    @Test func emptySearchReturnsAllSpots() async {
        let service = StubSpotService(spots: [.sample(id: "1"), .sample(id: "2")])
        let vm = ExploreViewModel(service: service)
        await vm.load()

        vm.searchText = ""

        #expect(vm.filteredSpots.count == 2)
    }

    @Test func mostPopularSortOrdersByReviewCountDescending() async {
        let service = StubSpotService(spots: [
            .sample(id: "1", reviewCount: 57),
            .sample(id: "2", reviewCount: 342),
            .sample(id: "3", reviewCount: 128)
        ])
        let vm = ExploreViewModel(service: service)
        await vm.load()

        vm.sort = .mostPopular

        #expect(vm.filteredSpots.map(\.reviewCount) == [342, 128, 57])
    }

    @Test func scoutSortPreservesServerOrder() async {
        let service = StubSpotService(spots: [
            .sample(id: "1", reviewCount: 57),
            .sample(id: "2", reviewCount: 342),
            .sample(id: "3", reviewCount: 128)
        ])
        let vm = ExploreViewModel(service: service)
        await vm.load()

        vm.sort = .scout

        #expect(vm.filteredSpots.map(\.id) == ["1", "2", "3"])
    }

    @Test func closestSortOrdersByAscendingDistance() async {
        let service = StubSpotService(spots: [
            .sample(id: "a"), .sample(id: "b"), .sample(id: "c")
        ])
        let vm = ExploreViewModel(service: service)
        await vm.load()

        vm.sort = .closest
        let distances = vm.filteredSpots.map { vm.distance(for: $0) }

        #expect(distances == distances.sorted())
    }

    @Test func spotCountTextCapsAt500Plus() async {
        let many = (0..<600).map { SpotSummary.sample(id: "\($0)") }
        let vm = ExploreViewModel(service: StubSpotService(spots: many))
        await vm.load()

        #expect(vm.spotCountText == "500+ spots")
    }

    @Test func spotCountTextShowsExactBelow500() async {
        let few = (0..<3).map { SpotSummary.sample(id: "\($0)") }
        let vm = ExploreViewModel(service: StubSpotService(spots: few))
        await vm.load()

        #expect(vm.spotCountText == "3 spots")
    }

    @Test func distanceTextIsDeterministicPerSpot() {
        let vm = ExploreViewModel(service: StubSpotService())
        let spot = SpotSummary.sample(id: "stable-id")

        #expect(vm.distanceText(for: spot) == vm.distanceText(for: spot))
        #expect(vm.distanceText(for: spot).hasSuffix("miles away"))
    }
}

@MainActor
struct SpotDetailViewModelTests {

    @Test func loadPopulatesDetailAndReviews() async {
        let service = StubSpotService(detail: .sample, reviews: Review.samples)
        let vm = SpotDetailViewModel(spotID: "1", service: service)

        await vm.load()

        #expect(vm.state == .loaded)
        #expect(vm.detail?.name == "The Emerald Basin")
        #expect(vm.reviews.count == Review.samples.count)
    }

    @Test func loadFailureSetsFailedState() async {
        let vm = SpotDetailViewModel(spotID: "1", service: StubSpotService(error: StubError()))

        await vm.load()

        #expect(vm.state == .failed("stub failure"))
        #expect(vm.detail == nil)
    }

    @Test func reviewCountTextUsesDetailCount() async {
        let vm = SpotDetailViewModel(spotID: "1", service: StubSpotService(detail: .sample))
        await vm.load()

        #expect(vm.reviewCountText == "128 people shared their view")
    }
}
