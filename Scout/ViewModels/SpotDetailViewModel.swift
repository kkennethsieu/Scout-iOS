import SwiftUI
import Observation

@Observable
@MainActor
final class SpotDetailViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - State

    let spotID: String
    private(set) var detail: SpotDetail?
    private(set) var reviews: [Review] = []
    private(set) var state: LoadState = .idle
    /// More review pages are available — drives the "load more" trigger / footer.
    private(set) var hasMore = false
    /// A `loadMoreReviews()` fetch is in flight (distinct from the initial `loading`).
    private(set) var isLoadingMore = false

    /// Cursor for the *next* reviews page; `nil` once the list is fully loaded.
    /// Readable so the All Reviews screen can seed its own feed from this one.
    private(set) var reviewsCursor: String?

    // MARK: - Dependencies

    private let service: SpotService
    private let pageSize = 10

    init(spotID: String, service: SpotService = AppServices.spot) {
        self.spotID = spotID
        self.service = service
    }

    // MARK: - Actions

    func load() async {
        state = .loading
        reviewsCursor = nil
        do {
            async let detailTask = service.fetchSpotDetail(id: spotID)
            async let reviewsTask = service.fetchReviews(spotID: spotID, limit: pageSize, cursor: nil, sort: ReviewSort.scout.apiValue)
            detail = try await detailTask
            let page = try await reviewsTask
            reviews = page.items
            reviewsCursor = page.nextCursor
            hasMore = page.nextCursor != nil
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Appends the next reviews page. No-ops unless the list is loaded, more pages
    /// exist, and no fetch is already running. On failure the loaded reviews are
    /// kept and the cursor is preserved, so a later scroll trigger retries.
    func loadMoreReviews() async {
        guard state == .loaded, hasMore, !isLoadingMore, let cursor = reviewsCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.fetchReviews(spotID: spotID, limit: pageSize, cursor: cursor, sort: ReviewSort.scout.apiValue)
            reviews.append(contentsOf: page.items)
            reviewsCursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            // Keep the loaded reviews; a later trigger will retry this page.
        }
    }

    var reviewCountText: String {
        guard let detail else { return "" }
        return "\(detail.reviewCount) people shared their view"
    }

    /// Builds a search view model for this spot's reviews, reusing this VM's
    /// service so previews/tests inherit the same (mock) backend.
    func makeReviewSearchViewModel() -> ReviewSearchViewModel {
        ReviewSearchViewModel(spotID: spotID, service: service)
    }

    /// Builds a standalone sortable feed for the All Reviews screen, reusing this
    /// VM's service. Kept separate so the All screen's sorting never reorders this
    /// VM's preview feed.
    func makeReviewFeedViewModel() -> ReviewFeedViewModel {
        ReviewFeedViewModel(spotID: spotID, service: service)
    }
}
