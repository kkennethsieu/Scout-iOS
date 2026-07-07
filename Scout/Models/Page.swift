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
    /// True when the backend couldn't find spots near the requested area and
    /// substituted popular spots from a default region (Los Angeles). Absent on
    /// payloads that don't support fallback (e.g. reviews) → defaults to false.
    let isFallback: Bool

    /// Memberwise-style init with `isFallback` defaulted, so the mock/stub
    /// services can construct pages without the flag.
    init(items: [Item], limit: Int, nextCursor: String?, isFallback: Bool = false) {
        self.items = items
        self.limit = limit
        self.nextCursor = nextCursor
        self.isFallback = isFallback
    }

    private enum CodingKeys: String, CodingKey { case items, limit, nextCursor, isFallback }

    /// Custom decode so `is_fallback` is optional on the wire — a payload that
    /// omits it (any pre-existing endpoint, e.g. reviews) decodes as `false`
    /// rather than throwing `keyNotFound`. Snake_case keys are mapped by
    /// `JSONDecoder.scout` (`.convertFromSnakeCase`) before matching CodingKeys.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([Item].self, forKey: .items)
        limit = try container.decode(Int.self, forKey: .limit)
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor)
        isFallback = try container.decodeIfPresent(Bool.self, forKey: .isFallback) ?? false
    }
}

typealias PaginatedReviews = Page<Review>
typealias PaginatedSpots   = Page<SpotSummary>
