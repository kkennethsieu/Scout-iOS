import Foundation

/// Fetches spots for the Explore feed and detail pages. A concrete networking
/// implementation can be dropped in later without touching the views — they
/// depend on this protocol, not on URLSession.
nonisolated protocol SpotService {
    /// Fetches spots near `region`. Pass `nil` to use the service's default
    /// query window (used by the Explore feed, which isn't map-driven yet).
    func fetchSpots(near region: SpotRegion?) async throws -> [SpotSummary]
    func fetchSpotDetail(id: String) async throws -> SpotDetail
    func fetchReviews(spotID: String) async throws -> [Review]
    /// Submits a review for an existing spot (multipart). Returns the created review.
    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review
    /// Creates a new spot + its first review in one request (multipart). The
    /// backend reverse-geocodes the coordinate; returns the saved spot + review.
    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview
}

extension SpotService {
    /// Convenience for callers that don't care about a specific area.
    func fetchSpots() async throws -> [SpotSummary] {
        try await fetchSpots(near: nil)
    }
}

/// Hardcoded data for development. Swap for a real `URLSession`-backed service
/// once the spots endpoints are wired.
nonisolated struct MockSpotService: SpotService {
    var delay: Duration = .milliseconds(400)

    func fetchSpots(near region: SpotRegion?) async throws -> [SpotSummary] {
        try await Task.sleep(for: delay)   // simulate network latency
        return SpotSummary.samples
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
