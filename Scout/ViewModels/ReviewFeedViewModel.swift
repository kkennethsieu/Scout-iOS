import SwiftUI
import Observation

/// A standalone, sortable, cursor-paginated feed of a spot's reviews — owned by
/// `ViewAllReviewsScreen`. Kept separate from `SpotDetailViewModel`'s feed so
/// changing the sort here never reorders the Spot Detail preview. Mirrors that
/// VM's `load` / `loadMore` shape, with `sort` threaded through.
@Observable
@MainActor
final class ReviewFeedViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - State

    private(set) var reviews: [Review] = []
    private(set) var state: LoadState = .idle
    private(set) var hasMore = false
    private(set) var isLoadingMore = false
    private(set) var sort: ReviewSort = .scout

    /// Cursor for the *next* page; `nil` once the list is fully loaded.
    private var cursor: String?

    // MARK: - Dependencies

    private let spotID: String
    private let service: SpotService
    private let pageSize = 10

    init(spotID: String, service: SpotService = AppServices.spot) {
        self.spotID = spotID
        self.service = service
    }

    // MARK: - Loading

    /// Loads the first page in `sort` order, replacing any current results.
    func load(sort: ReviewSort) async {
        self.sort = sort
        state = .loading
        cursor = nil
        do {
            let page = try await service.fetchReviews(
                spotID: spotID, limit: pageSize, cursor: nil, sort: sort.apiValue
            )
            reviews = page.items
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Appends the next page in the current sort order. On failure the loaded
    /// reviews and cursor are kept, so a later scroll trigger retries.
    func loadMore() async {
        guard state == .loaded, hasMore, !isLoadingMore, let cursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.fetchReviews(
                spotID: spotID, limit: pageSize, cursor: cursor, sort: sort.apiValue
            )
            reviews.append(contentsOf: page.items)
            self.cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            // Keep what's loaded; a later trigger will retry this page.
        }
    }

    /// Seeds this feed from an already-loaded default-sort feed (the shared
    /// `SpotDetailViewModel`), so opening the screen at the default order shows
    /// instantly without a re-fetch.
    func adopt(reviews: [Review], cursor: String?, hasMore: Bool) {
        self.reviews = reviews
        self.cursor = cursor
        self.hasMore = hasMore
        self.sort = .scout
        state = .loaded
    }
}
