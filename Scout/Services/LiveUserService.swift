import Foundation

/// `BackendClient`-backed `UserService`.
///
/// Backend routes:
/// - `GET /users/me` → `UserProfile`
/// - `GET /users/me/reviews` → `PaginatedReviews` envelope (cursor-paginated)
/// - `DELETE /users/me` → 204 (deletes the user + data + Firebase auth user)
nonisolated struct LiveUserService: UserService {
    var client = BackendClient()
    var pageLimit = 10

    func fetchCurrentUser() async throws -> UserProfile {
        try await client.get("users/me")
    }

    func fetchMyReviews(limit: Int, cursor: String?) async throws -> PaginatedReviews {
        var query = ["limit": "\(limit)"]
        if let cursor { query["cursor"] = cursor }
        return try await client.get("users/me/reviews", query: query)
    }

    func deleteReview(id: String) async throws {
        try await client.delete("reviews/\(id)")
    }

    func deleteAccount() async throws {
        try await client.delete("users/me")
    }
}
