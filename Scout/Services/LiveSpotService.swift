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

    func fetchReviews(spotID: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        var query = ["limit": "\(limit)", "sort": sort]
        if let cursor { query["cursor"] = cursor }
        return try await client.get("spots/\(spotID)/reviews", query: query)
    }

    func searchReviews(spotID: String, query: String, limit: Int, cursor: String?, sort: String) async throws -> PaginatedReviews {
        var params = ["q": query, "limit": "\(limit)", "sort": sort]
        if let cursor { params["cursor"] = cursor }
        return try await client.get("spots/\(spotID)/reviews/search", query: params)
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

        // The user can only review a spot once. A repeat comes back as 409
        // `REVIEW_ALREADY_EXISTS` carrying their existing review's id — surface it
        // typed so the UI can offer to update that review with the new draft.
        if let http = response as? HTTPURLResponse, http.statusCode == 409,
           let existing = try? JSONDecoder.scout.decode(ReviewAlreadyExistsResponse.self, from: data),
           existing.code == "REVIEW_ALREADY_EXISTS" {
            throw SpotServiceError.alreadyReviewed(spotID: existing.spotId,
                                                   reviewID: existing.reviewId,
                                                   message: existing.detail)
        }

        return try client.decode(Review.self, from: data, response: response)
    }

    /// Updates the signed-in user's review (owner-only JSON PATCH). Text/attribute
    /// fields only — the endpoint doesn't touch photos.
    func updateReview(reviewID: String, payload: NewReviewPayload) async throws -> Review {
        try await client.patch("reviews/\(reviewID)", body: ReviewUpdatePayload(payload))
    }

    /// The flattened body of a 409 `REVIEW_ALREADY_EXISTS` response. Keys arrive
    /// snake_case and are camel-cased by `JSONDecoder.scout` (`review_id` → `reviewId`).
    nonisolated struct ReviewAlreadyExistsResponse: Decodable {
        let code: String
        let spotId: String
        let reviewId: String
        let detail: String?
    }

    /// JSON body for `PATCH /reviews/{id}` (`ReviewUpdate`). Mirrors the review
    /// content of a `NewReviewPayload` minus spot identity and photos. Encoded by
    /// `JSONEncoder.scout` (`.convertToSnakeCase`); nil optionals are omitted, so
    /// the backend's `exclude_unset` preserves those fields' existing values while
    /// the always-sent fields replace theirs with the new draft.
    nonisolated struct ReviewUpdatePayload: Encodable {
        let overallRating: Int
        let notes: String
        let bestTimeOfDay: [String]
        let bestSeason: [String]
        let accessLevel: String?
        let entranceFee: Double?
        let crowdLevel: String?
        let gearRecommendations: String
        let compositionHints: String
        let permitRequired: Bool?
        let droneAllowed: Bool?
        let tripodAllowed: Bool?

        init(_ p: NewReviewPayload) {
            overallRating = p.overallRating
            notes = p.notes
            bestTimeOfDay = p.bestTimeOfDay
            bestSeason = p.bestSeason
            accessLevel = p.accessLevel
            entranceFee = p.entranceFee
            crowdLevel = p.crowdLevel
            gearRecommendations = p.gearRecommendations
            compositionHints = p.compositionHints
            permitRequired = p.permitRequired
            droneAllowed = p.droneAllowed
            tripodAllowed = p.tripodAllowed
        }
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

        // A duplicate spot comes back as 409 `SPOT_ALREADY_EXISTS` carrying the
        // existing spot's id/name/message. Surface it as a typed error so the UI
        // can offer to add the review to that spot instead of dead-ending. Any
        // other 409 (or an unparseable body) falls through to the generic path.
        if let http = response as? HTTPURLResponse, http.statusCode == 409,
           let dup = try? JSONDecoder.scout.decode(DuplicateSpotResponse.self, from: data),
           dup.code == "SPOT_ALREADY_EXISTS" {
            throw SpotServiceError.duplicateSpot(existingSpotID: dup.spotId,
                                                 name: dup.name,
                                                 message: dup.detail)
        }

        return try client.decode(CreatedSpotReview.self, from: data, response: response)
    }

    /// The flattened body of a 409 `SPOT_ALREADY_EXISTS` response. Keys arrive
    /// snake_case and are camel-cased by `JSONDecoder.scout` (`spot_id` → `spotId`).
    nonisolated struct DuplicateSpotResponse: Decodable {
        let code: String
        let spotId: String
        let name: String
        let detail: String?
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
    /// A create was rejected because a spot already exists nearby (409). Carries
    /// the existing spot so the UI can offer to add the review there.
    case duplicateSpot(existingSpotID: String, name: String, message: String?)
    /// A review was rejected because the user already reviewed this spot (409).
    /// Carries their existing review so the UI can offer to update it.
    case alreadyReviewed(spotID: String, reviewID: String, message: String?)

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
        case .http(let status) where status == 409:
            // The backend rejects a create when a spot already exists at that
            // location/name. Retrying can't succeed, so don't suggest it.
            return "A spot already exists at this location."
        case .http(let status):
            return "Server error (\(status)). Please try again."
        case .duplicateSpot(_, _, let message):
            return message ?? "A spot already exists at this location."
        case .alreadyReviewed(_, _, let message):
            return message ?? "You've already reviewed this spot."
        case .decoding:
            return "Couldn't read the server's response."
        }
    }
}
