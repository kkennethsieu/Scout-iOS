import Foundation

/// A cursor-paginated page from the backend: `{ items, limit, next_cursor }`.
/// `nextCursor` (from `next_cursor`, via `JSONDecoder.scout`) is non-nil when more
/// pages are available — pass it back as the cursor to fetch the next page.
///
/// Shared by the list endpoints that now return this envelope: `GET /spots`,
/// `GET /spots/{id}/reviews`, `GET /users/me/reviews`.
nonisolated struct Page<Item: Decodable>: Decodable {
    let items: [Item]
    let limit: Int
    let nextCursor: String?
}

typealias PaginatedReviews = Page<Review>
typealias PaginatedSpots   = Page<SpotSummary>
