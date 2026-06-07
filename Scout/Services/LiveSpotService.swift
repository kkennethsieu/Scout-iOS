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

    func fetchSpots(near region: SpotRegion?) async throws -> [SpotSummary] {
        // Use the requested map area if given; otherwise fall back to the
        // service's default center + radius.
        let area = region ?? SpotRegion(latitude: latitude,
                                        longitude: longitude,
                                        radiusKm: radiusKm)
        return try await get("spots", query: [
            "lat": "\(area.latitude)",
            "lng": "\(area.longitude)",
            "radius_km": "\(area.radiusKm)",
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

    func submitReview(spotID: String, payload: NewReviewPayload) async throws -> Review {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = try multipartBody(for: payload, boundary: boundary)

        var request = URLRequest(url: baseURL.appending(path: "spots/\(spotID)/reviews"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        if let bearer = try await token() {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        return try decode(Review.self, from: data, response: response)
    }

    func submitNewSpot(payload: NewReviewPayload) async throws -> CreatedSpotReview {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = try multipartBody(for: payload, boundary: boundary, includeSpotFields: true)

        var request = URLRequest(url: baseURL.appending(path: "spots/with-review"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        if let bearer = try await token() {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        return try decode(CreatedSpotReview.self, from: data, response: response)
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
        return try decode(T.self, from: data, response: response)
    }

    /// Validates the HTTP status and decodes the body with the shared decoder.
    private func decode<T: Decodable>(_ type: T.Type, from data: Data, response: URLResponse) throws -> T {
        guard let http = response as? HTTPURLResponse else {
            throw SpotServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SpotServiceError.http(status: http.statusCode)
        }
        do {
            return try JSONDecoder.scout.decode(T.self, from: data)
        } catch {
            throw SpotServiceError.decoding(error)
        }
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

// MARK: - Multipart encoding

private extension Data {
    nonisolated mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }

    nonisolated mutating func appendFormField(_ name: String, _ value: String, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        appendString("\(value)\r\n")
    }

    nonisolated mutating func appendFileField(_ name: String, filename: String,
                                              mimeType: String, fileData: Data, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(mimeType)\r\n\r\n")
        append(fileData)
        appendString("\r\n")
    }
}

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
