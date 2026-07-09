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
    /// Set when a delete fails; the screen surfaces it as an alert.
    private(set) var deleteError: String?
    /// The id of the review currently being deleted, so its card can show a
    /// spinner instead of looking frozen. `nil` when no delete is in flight.
    private(set) var deletingReviewID: String?
    /// Account deletion is in flight — the screen blocks interaction + shows a spinner.
    private(set) var isDeletingAccount = false
    /// Set when account deletion fails; the screen surfaces it as an alert.
    private(set) var accountDeleteError: String?

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

    // MARK: - Delete

    /// Deletes one of the user's reviews. Awaits the server, then removes the card
    /// and decrements the header count. Returns `true` on success (so the screen
    /// can confirm with a toast); on failure the review is kept and the error is
    /// surfaced.
    @discardableResult
    func deleteReview(_ review: Review) async -> Bool {
        deletingReviewID = review.id
        defer { deletingReviewID = nil }
        do {
            try await userService.deleteReview(id: review.id)
            reviews.removeAll { $0.id == review.id }
            if let current = profile?.reviewCount {
                profile?.reviewCount = max(0, current - 1)
            }
            return true
        } catch {
            deleteError = error.localizedDescription
            return false
        }
    }

    func dismissDeleteError() {
        deleteError = nil
    }

    /// Swaps an edited review into the list in place (matched by id), so the card
    /// reflects the change immediately after Edit saves — no refetch, scroll
    /// position and pagination preserved. No-ops if the id isn't present. The
    /// success toast is posted by the screen (global `ToastCenter`).
    func applyUpdatedReview(_ review: Review) {
        guard let index = reviews.firstIndex(where: { $0.id == review.id }) else { return }
        reviews[index] = review
    }

    /// Adopts a profile returned from Edit Profile's save, so the header reflects
    /// the edits immediately without a refetch.
    func applyUpdatedProfile(_ profile: UserProfile) {
        self.profile = profile
    }

    // MARK: - Account deletion

    /// Permanently deletes the user's account on the backend (which also removes
    /// the Firebase auth user). Returns `true` on success so the screen can sign
    /// out; on failure surfaces the error and returns `false`.
    func deleteAccount() async -> Bool {
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        do {
            try await userService.deleteAccount()
            return true
        } catch {
            accountDeleteError = error.localizedDescription
            return false
        }
    }

    func dismissAccountDeleteError() {
        accountDeleteError = nil
    }

    // TODO: replace sample photo data with a service-backed load.
    nonisolated static let samplePhotoURLs: [URL] = (1...12).map {
        URL(string: "https://picsum.photos/seed/profile-\($0)/400/400")!
    }
}
