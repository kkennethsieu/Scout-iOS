import Foundation

/// The signed-in user's own data: their backend profile and their reviews. Owns
/// all `/users/me/*` endpoints. View models depend on this protocol, not on a
/// concrete networking type.
nonisolated protocol UserService {
    /// The current user's backend profile doc (`GET /users/me`).
    func fetchCurrentUser() async throws -> UserProfile
    /// The current user's reviews, newest first, cursor-paginated. Pass the
    /// previous page's `nextCursor` to fetch the next page (`nil` for page one).
    func fetchMyReviews(limit: Int, cursor: String?) async throws -> PaginatedReviews
    /// Deletes one of the caller's own reviews (`DELETE /reviews/{id}`).
    func deleteReview(id: String) async throws
}

/// Hardcoded data for development / real-device fallback.
nonisolated struct MockUserService: UserService {
    var delay: Duration = .milliseconds(400)

    func fetchCurrentUser() async throws -> UserProfile {
        try await Task.sleep(for: delay)
        return .sample
    }

    /// Two deterministic pages so pagination is exercisable offline: page one
    /// (cursor `nil`) hands back a `"p2"` cursor; page two (`"p2"`) ends the list.
    func fetchMyReviews(limit: Int, cursor: String?) async throws -> PaginatedReviews {
        try await Task.sleep(for: delay)
        switch cursor {
        case nil:
            return PaginatedReviews(items: Review.samples, limit: limit, nextCursor: "p2")
        default:
            return PaginatedReviews(items: Review.samples, limit: limit, nextCursor: nil)
        }
    }

    func deleteReview(id: String) async throws {
        try await Task.sleep(for: delay)
    }
}
