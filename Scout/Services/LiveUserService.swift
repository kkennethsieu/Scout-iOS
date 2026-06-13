import Foundation

/// `BackendClient`-backed `UserService`.
///
/// Backend routes:
/// - `GET /users/me` → `UserProfile`
/// - `GET /users/me/reviews` → `PaginatedReviews` envelope (cursor-paginated)
/// - `PATCH /users/me` → `UserProfile` (multipart: text fields + optional `photo`)
/// - `DELETE /users/me` → 204 (deletes the user + data + Firebase auth user)
nonisolated struct LiveUserService: UserService {
    var client = BackendClient()
    var pageLimit = 10

    /// Avatars render at most ~96pt (≈288px @3x), so downscale to 512px before
    /// upload — plenty sharp, a fraction of the bytes of the 2048px review default.
    private let avatarMaxPixel = 512

    func fetchCurrentUser() async throws -> UserProfile {
        try await client.get("users/me")
    }

    func fetchMyReviews(limit: Int, cursor: String?) async throws -> PaginatedReviews {
        var query = ["limit": "\(limit)"]
        if let cursor { query["cursor"] = cursor }
        return try await client.get("users/me/reviews", query: query)
    }

    func updateProfile(_ update: ProfileUpdate) async throws -> UserProfile {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        if let displayName = update.displayName {
            body.appendFormField("display_name", displayName, boundary: boundary)
        }
        if let homeCity = update.homeCity {
            body.appendFormField("home_city", homeCity, boundary: boundary)
        }
        if let homeCountry = update.homeCountry {
            body.appendFormField("home_country", homeCountry, boundary: boundary)
        }
        if let photoData = update.photoData {
            guard let jpeg = photoData.jpegForUpload(maxPixel: avatarMaxPixel) else {
                throw SpotServiceError.imageEncoding
            }
            body.appendFileField("photo", filename: "avatar.jpg",
                                 mimeType: "image/jpeg", fileData: jpeg, boundary: boundary)
        }
        body.appendString("--\(boundary)--\r\n")

        var request = URLRequest(url: client.baseURL.appending(path: "users/me"))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        if let bearer = try await client.token() {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (data, response) = try await client.session.data(for: request)
        return try client.decode(UserProfile.self, from: data, response: response)
    }

    func deleteReview(id: String) async throws {
        try await client.delete("reviews/\(id)")
    }

    func deleteAccount() async throws {
        try await client.delete("users/me")
    }
}
