import Foundation

/// Fetches spots for the Explore feed and detail pages. A concrete networking
/// implementation can be dropped in later without touching the views — they
/// depend on this protocol, not on URLSession.
nonisolated protocol SpotService {
    func fetchSpots() async throws -> [SpotSummary]
    func fetchSpotDetail(id: String) async throws -> SpotDetail
    func fetchReviews(spotID: String) async throws -> [Review]
}

/// Hardcoded data for development. Swap for a real `URLSession`-backed service
/// once the spots endpoints are wired.
nonisolated struct MockSpotService: SpotService {
    var delay: Duration = .milliseconds(400)

    func fetchSpots() async throws -> [SpotSummary] {
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
