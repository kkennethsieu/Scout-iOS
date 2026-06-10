import Foundation
import Observation

/// Drives the Profile screen: the signed-in user's backend profile (incl. the
/// authoritative `reviewCount`), their reviews (cursor-paginated), and which tab
/// is showing. The profile is fetched fresh on each load rather than read from
/// the cached Firebase auth user. Flow/nav state (the selected tab) lives here.
///
/// Photos are still sample-only; the profile + Reviews tab are wired to the service.
@Observable
@MainActor
final class ProfileViewModel {
    enum Tab: Hashable, CaseIterable {
        case photos, reviews

        var title: String {
            switch self {
            case .photos: "Photos"
            case .reviews: "Reviews"
            }
        }
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - State

    var selectedTab: Tab = .reviews

    let photoURLs: [URL]

    private(set) var profile: UserProfile?
    private(set) var reviews: [Review] = []
    private(set) var state: LoadState = .idle
    /// More pages are available — drives the "load more" trigger / footer spinner.
    private(set) var hasMore = false
    /// A `loadMore()` fetch is in flight (distinct from the initial `loading`).
    private(set) var isLoadingMore = false

    /// Cursor for the *next* page; `nil` once the list is fully loaded.
    private var cursor: String?

    // MARK: - Dependencies

    private let userService: UserService
    private let pageSize = 10

    nonisolated init(userService: UserService = AppServices.user,
                     photoURLs: [URL] = ProfileViewModel.samplePhotoURLs) {
        self.userService = userService
        self.photoURLs = photoURLs
    }

    // MARK: - Loading

    /// Loads the profile + first page of reviews. Shows the full loader only on
    /// the first load; a refetch (tab re-activation, pull-to-refresh) updates in
    /// place and, on failure, leaves the existing content intact.
    func load() async {
        let isFirstLoad = profile == nil
        if isFirstLoad { state = .loading }
        cursor = nil
        do {
            async let profileTask = userService.fetchCurrentUser()
            async let pageTask = userService.fetchMyReviews(limit: pageSize, cursor: nil)
            profile = try await profileTask
            let page = try await pageTask
            reviews = page.items
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
            state = .loaded
        } catch {
            if isFirstLoad { state = .failed(error.localizedDescription) }
        }
    }

    /// Appends the next page. No-ops unless the list is loaded, more pages exist,
    /// and no fetch is already running. On failure the list is left intact and
    /// the cursor is preserved, so the next trigger retries.
    func loadMore() async {
        guard state == .loaded, hasMore, !isLoadingMore, let cursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await userService.fetchMyReviews(limit: pageSize, cursor: cursor)
            reviews.append(contentsOf: page.items)
            self.cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            // Keep the loaded reviews; a later trigger will retry this page.
        }
    }

    // TODO: replace sample photo data with a service-backed load.
    nonisolated static let samplePhotoURLs: [URL] = (1...12).map {
        URL(string: "https://picsum.photos/seed/profile-\($0)/400/400")!
    }
}
