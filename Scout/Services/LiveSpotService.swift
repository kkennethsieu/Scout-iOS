import Foundation

/// `URLSession`-backed `SpotService` that talks to the Scout backend.
///
/// Backend routes:
/// - `GET /spots` → `PaginatedSpots` envelope (`{ items, limit, next_cursor }`)
/// - `GET /spots/search` → `[SpotSummaryResponse]` (global name search)
/// - `GET /spots/{id}` → `SpotResponse` (full aggregates)
/// - `GET /spots/{id}/reviews` → `PaginatedReviews` envelope
nonisolated struct LiveSpotService: SpotService {
    /// Shared backend plumbing (base URL, session, Bearer token, GET/decode).
    var client = BackendClient()

    /// Placeholder query center + radius until CoreLocation is wired. `/spots`
    /// requires a point and radius; these cover the sample-data region for now.
    var latitude: Double = 34.0522
    var longitude: Double = -118.2437
    var radiusKm: Double = 50
    /// Default page size for the reviews list (the spots list takes `limit` per call).
    var limit: Int = 20

    func fetchSpots(near region: SpotRegion?, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        // Use the requested map area if given; otherwise fall back to the
        // service's default center + radius.
        let area = region ?? SpotRegion(latitude: latitude,
                                        longitude: longitude,
                                        radiusKm: radiusKm)
        var query = [
            "lat": "\(area.latitude)",
            "lng": "\(area.longitude)",
            "radius_km": "\(area.radiusKm)",
            "limit": "\(limit)"
        ]
        if let cursor { query["cursor"] = cursor }
        return try await client.get("spots", query: query)
    }

    func searchSpots(query: String, limit: Int) async throws -> [SpotSummary] {
        try await client.get("spots/search", query: [
            "q": query,
            "limit": "\(limit)"
        ])
    }

    func fetchSpotDetail(id: String) async throws -> SpotDetail {
        try await client.get("spots/\(id)")
    }

    func fetchReviews(spotID: String) async throws -> [Review] {
        // Returns the first page; cursor pagination can be layered on once the
        // full reviews screen exists.
        let page: PaginatedReviews = try await client.get("spots/\(spotID)/reviews", query: [
            "limit": "\(limit)"
        ])
        return page.items
    }

    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = try multipartBody(for: payload, boundary: boundary)

        var request = URLRequest(url: client.baseURL.appending(path: "spots/\(spotID)/reviews"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        if let bearer = try await client.token() {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (data, response) = try await client.session.data(for: request)
        return try client.decode(Review.self, from: data, response: response)
    }

    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = try multipartBody(for: payload, boundary: boundary, includeSpotFields: true)

        var request = URLRequest(url: client.baseURL.appending(path: "spots/with-review"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        if let bearer = try await client.token() {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (data, response) = try await client.session.data(for: request)
        return try client.decode(CreatedSpotReview.self, from: data, response: response)
    }

    // MARK: - Multipart

    /// Builds the `multipart/form-data` body for a review submission. Empty/nil
    /// optionals are omitted (so the backend stores `None`, not `""`, and enum
    /// fields never receive an invalid empty value).
    ///
    /// When `includeSpotFields` is true (the new-spot `/spots/with-review`
    /// endpoint) the spot's `name`/`lat`/`lng` are prepended; otherwise they're
    /// omitted (the existing-spot endpoint already knows the spot).
    private func multipartBody(for payload: NewReviewPayload, boundary: String,
                              includeSpotFields: Bool = false) throws -> Data {
        var body = Data()

        if includeSpotFields {
            body.appendFormField("name", payload.name, boundary: boundary)
            body.appendFormField("lat", String(payload.lat), boundary: boundary)
            body.appendFormField("lng", String(payload.lng), boundary: boundary)
        }

        body.appendFormField("overall_rating", String(payload.overallRating), boundary: boundary)

        if !payload.notes.isEmpty {
            body.appendFormField("notes", payload.notes, boundary: boundary)
        }
        if !payload.gearRecommendations.isEmpty {
            body.appendFormField("gear_recommendations", payload.gearRecommendations, boundary: boundary)
        }
        if !payload.compositionHints.isEmpty {
            body.appendFormField("composition_hints", payload.compositionHints, boundary: boundary)
        }
        if let access = payload.accessLevel, !access.isEmpty {
            body.appendFormField("access_level", access, boundary: boundary)
        }
        if let crowd = payload.crowdLevel, !crowd.isEmpty {
            body.appendFormField("crowd_level", crowd, boundary: boundary)
        }
        if let fee = payload.entranceFee {
            body.appendFormField("entrance_fee", String(fee), boundary: boundary)
        }

        for value in payload.bestTimeOfDay {
            body.appendFormField("best_time_of_day", value, boundary: boundary)
        }
        for value in payload.bestSeason {
            body.appendFormField("best_season", value, boundary: boundary)
        }

        if let permit = payload.permitRequired {
            body.appendFormField("permit_required", permit ? "true" : "false", boundary: boundary)
        }
        if let drone = payload.droneAllowed {
            body.appendFormField("drone_allowed", drone ? "true" : "false", boundary: boundary)
        }
        if let tripod = payload.tripodAllowed {
            body.appendFormField("tripod_allowed", tripod ? "true" : "false", boundary: boundary)
        }

        for (index, photo) in payload.photos.enumerated() {
            guard let jpeg = photo.jpegForUpload() else {
                throw SpotServiceError.imageEncoding
            }
            body.appendFileField("photos", filename: "photo-\(index).jpg",
                                 mimeType: "image/jpeg", fileData: jpeg, boundary: boundary)
        }

        body.appendString("--\(boundary)--\r\n")
        return body
    }
}

// Multipart `Data` helpers live in Extensions/Data+Multipart.swift (shared with LiveUserService).

// MARK: - Errors

enum SpotServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case http(status: Int)
    case decoding(Error)
    case imageEncoding

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Couldn't build the request URL."
        case .invalidResponse:
            return "The server sent an unexpected response."
        case .imageEncoding:
            return "Couldn't prepare a photo for upload."
        case .http(let status) where status == 401:
            return "Your session expired. Please sign in again."
        case .http(let status):
            return "Server error (\(status)). Please try again."
        case .decoding:
            return "Couldn't read the server's response."
        }
    }
}
