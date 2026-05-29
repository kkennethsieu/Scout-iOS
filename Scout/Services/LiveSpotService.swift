import Foundation

/// `URLSession`-backed `SpotService` that talks to the Scout backend.
///
/// Backend routes:
/// - `GET /spots` → `[SpotSummaryResponse]`
/// - `GET /spots/{id}` → `SpotResponse` (full aggregates)
/// - `GET /spots/{id}/reviews` → `PaginatedReviews` envelope
nonisolated struct LiveSpotService: SpotService {
    /// Backend base URL. Defaults to the local dev server on port 8000.
    var baseURL = URL(string: "http://localhost:8000")!
    var session: URLSession = .shared

    /// Supplies the Firebase ID token for the `Authorization: Bearer` header.
    var token: @MainActor () async throws -> String? = { try await AuthService.shared.idToken() }

    /// Placeholder query center + radius until CoreLocation is wired. `/spots`
    /// requires a point and radius; these cover the sample-data region for now.
    var latitude: Double = 34.0522
    var longitude: Double = -118.2437
    var radiusKm: Double = 50
    var limit: Int = 20

    func fetchSpots() async throws -> [SpotSummary] {
        try await get("spots", query: [
            "lat": "\(latitude)",
            "lng": "\(longitude)",
            "radius_km": "\(radiusKm)",
            "limit": "\(limit)"
        ])
    }

    func fetchSpotDetail(id: String) async throws -> SpotDetail {
        try await get("spots/\(id)")
    }

    func fetchReviews(spotID: String) async throws -> [Review] {
        // Returns the first page; cursor pagination can be layered on once the
        // full reviews screen exists.
        let page: PaginatedReviews = try await get("spots/\(spotID)/reviews", query: [
            "limit": "\(limit)"
        ])
        return page.items
    }

    // MARK: - Request plumbing

    private func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )
        if !query.isEmpty {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else { throw SpotServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bearer = try await token() {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SpotServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SpotServiceError.http(status: http.statusCode)
        }

        do {
            return try await JSONDecoder.scout.decode(T.self, from: data)
        } catch {
            throw SpotServiceError.decoding(error)
        }
    }
}

// MARK: - Errors

enum SpotServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case http(status: Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Couldn't build the request URL."
        case .invalidResponse:
            return "The server sent an unexpected response."
        case .http(let status) where status == 401:
            return "Your session expired. Please sign in again."
        case .http(let status):
            return "Server error (\(status)). Please try again."
        case .decoding:
            return "Couldn't read the server's response."
        }
    }
}
