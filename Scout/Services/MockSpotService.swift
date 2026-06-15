import Foundation

/// Fetches spots for the Explore feed and detail pages. A concrete networking
/// implementation can be dropped in later without touching the views — they
/// depend on this protocol, not on URLSession.
nonisolated protocol SpotService {
    /// Fetches a cursor-paginated page of spots near `region`. Pass `nil` for the
    /// service's default query window; pass a prior page's `nextCursor` to page on.
    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots
    /// Global name search (case-insensitive substring, ranked) powering the
    /// search bar's Spots section. Not geo-scoped.
    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary]
    func fetchSpotDetail(id: String) async throws -> SpotDetail
    func fetchReviews(spotID: String) async throws -> [Review]
    /// Submits a review for an existing spot (multipart). Returns the created review.
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review
    /// Creates a new spot + its first review in one request (multipart). The
    /// backend reverse-geocodes the coordinate; returns the saved spot + review.
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview
}

extension SpotService {
    /// First page only, items unwrapped — for callers that don't paginate
    /// (Search, Map, CreateMap).
    func fetchSpots(near region: SpotRegion? = nil) async throws -> [SpotSummary] {
        try await fetchSpots(near: region, limit: 20, cursor: nil).items
    }
}

/// Hardcoded data for development. Swap for a real `URLSession`-backed service
/// once the spots endpoints are wired.
nonisolated struct MockSpotService: SpotService {
    var delay: Duration = .milliseconds(400)

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        try await Task.sleep(for: delay)   // simulate network latency
        // Paginate the samples by integer-offset cursor so "load more" is
        // exercisable in previews/tests.
        let start = cursor.flatMap(Int.init) ?? 0
        let slice = Array(SpotSummary.samples.dropFirst(start).prefix(limit))
        let end = start + slice.count
        let next = end < SpotSummary.samples.count ? String(end) : nil
        return PaginatedSpots(items: slice, limit: limit, nextCursor: next)
    }

    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] {
        try await Task.sleep(for: delay)
        return Array(
            SpotSummary.samples
                .filter { $0.name.localizedCaseInsensitiveContains(query) }
                .prefix(limit)
        )
    }

    func fetchSpotDetail(id: String) async throws -> SpotDetail {
        try await Task.sleep(for: delay)
        return SpotDetail.sample
    }

    func fetchReviews(spotID: String) async throws -> [Review] {
        try await Task.sleep(for: delay)
        return Review.samples
    }

    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review {
        try await Task.sleep(for: delay)
        return Review.samples[0]
    }

    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        try await Task.sleep(for: delay)
        return CreatedSpotReview(spot: .sample, review: Review.samples[0])
    }
}

// MARK: - Decoding

extension JSONDecoder {
    /// Configured to decode the backend's snake_case keys and ISO-8601 dates.
    /// Ready for the real networking layer.
    static let scout: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

extension JSONEncoder {
    /// Mirror of `JSONDecoder.scout` for request bodies: camelCase → snake_case
    /// keys, ISO-8601 dates.
    static let scout: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
