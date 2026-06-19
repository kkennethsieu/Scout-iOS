import SwiftUI
import Observation

/// Drives the search field on `ViewAllReviewsScreen`: a debounced, cursor-paginated
/// backend search over a single spot's reviews (`GET /spots/{id}/reviews/search`).
/// Kept separate from `SpotDetailViewModel` (which owns the canonical review feed)
/// so the screen can swap between the feed and search results by `isActive`.
///
/// Mirrors `SearchViewModel`'s debounce: each keystroke cancels the pending fetch
/// and reschedules, so only the latest query hits the network.
@Observable
@MainActor
final class ReviewSearchViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - State

    /// Bound to the search field. Typing schedules a debounced search.
    var query: String = "" {
        didSet { scheduleSearch() }
    }

    private(set) var results: [Review] = []
    private(set) var state: LoadState = .idle
    /// More result pages are available — drives the "load more" trigger / footer.
    private(set) var hasMore = false
    /// A `loadMore()` fetch is in flight (distinct from the initial `loading`).
    private(set) var isLoadingMore = false
    /// Server-side ordering applied to results; changed via `setSort`.
    private(set) var sort: ReviewSort = .scout

    /// The query is long enough to search — the screen shows results instead of
    /// the feed once this is true.
    var isActive: Bool { trimmed(query).count >= minQueryLength }

    /// Cursor for the *next* results page; `nil` once the list is fully loaded.
    private var cursor: String?

    // MARK: - Dependencies & tuning

    private let spotID: String
    private let service: SpotService
    private let pageSize = 20
    /// The endpoint accepts `q` from 2 chars; we require a few more so we don't
    /// fire low-signal searches that match half the reviews.
    private let minQueryLength = 3
    /// Matches the endpoint's `q` maximum.
    private let maxQueryLength = 50
    private let debounce: Duration = .milliseconds(300)
    private var searchTask: Task<Void, Never>?
    /// The trimmed query we last kicked off a fetch for, so repeat keystrokes
    /// that don't change the effective query (trailing spaces, re-typing the
    /// same text) don't hit the backend again.
    private var lastSearchedQuery: String?

    init(spotID: String, service: SpotService = AppServices.spot) {
        self.spotID = spotID
        self.service = service
    }

    // MARK: - Search

    /// Debounces a backend search. Clears results below the min length so the
    /// screen falls back to the feed as the user deletes back down.
    private func scheduleSearch() {
        let q = trimmed(query)
        guard q.count >= minQueryLength else {
            searchTask?.cancel()
            lastSearchedQuery = nil
            results = []
            cursor = nil
            hasMore = false
            state = .idle
            return
        }
        // The effective query is unchanged and isn't in a failed state we'd want
        // to retry — keep the current results / in-flight fetch, don't re-hit.
        let lastAttemptFailed: Bool = { if case .failed = state { true } else { false } }()
        guard q != lastSearchedQuery || lastAttemptFailed else { return }
        lastSearchedQuery = q
        searchTask?.cancel()
        state = .loading
        searchTask = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await self?.performSearch(q)
        }
    }

    /// Runs the search now. Internal so tests can drive it without the debounce.
    /// A superseded (cancelled) call bails before mutating state so it can't
    /// clobber a newer query's results.
    func performSearch(_ rawQuery: String) async {
        let q = String(trimmed(rawQuery).prefix(maxQueryLength))
        guard q.count >= minQueryLength else {
            results = []
            cursor = nil
            hasMore = false
            state = .idle
            return
        }
        cursor = nil
        do {
            let page = try await service.searchReviews(spotID: spotID, query: q, limit: pageSize, cursor: nil, sort: sort.apiValue)
            guard !Task.isCancelled else { return }
            results = page.items
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
            state = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.localizedDescription)
        }
    }

    /// Appends the next results page. No-ops unless results are loaded, more pages
    /// exist, and no fetch is already running. On failure the cursor is preserved
    /// so a later scroll trigger retries.
    func loadMore() async {
        guard state == .loaded, hasMore, !isLoadingMore, let cursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.searchReviews(
                spotID: spotID,
                query: String(trimmed(query).prefix(maxQueryLength)),
                limit: pageSize,
                cursor: cursor,
                sort: sort.apiValue
            )
            results.append(contentsOf: page.items)
            self.cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            // Keep loaded results; a later trigger will retry this page.
        }
    }

    /// Applies a new sort order. When a search is active, re-runs it immediately
    /// (no debounce — this is an explicit action, not typing).
    func setSort(_ sort: ReviewSort) {
        guard sort != self.sort else { return }
        self.sort = sort
        guard isActive else { return }
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            await self.performSearch(self.query)
        }
    }

    private func trimmed(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
