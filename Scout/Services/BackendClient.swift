import Foundation

/// Shared HTTP plumbing for the Scout backend: base URL, session, the
/// `Authorization: Bearer` Firebase token, and JSON GET + decoding. The Live
/// service implementations (`LiveSpotService`, `LiveUserService`) hold one of
/// these so request handling lives in a single place.
nonisolated struct BackendClient {
    /// Backend base URL. Defaults to the local dev server on port 8000.
    var baseURL = URL(string: "http://127.0.0.1:8000")!
//    var baseURL = URL(string: "https://sprite-armadillo-scarf.ngrok-free.dev")!
    var session: URLSession = .shared

    /// Supplies the Firebase ID token for the `Authorization: Bearer` header.
    var token: @MainActor () async throws -> String? = { try await AuthService.shared.idToken() }

    /// Performs an authenticated GET and decodes the JSON body.
    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
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

    /// Performs an authenticated POST with a JSON body and decodes the response.
    func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
        try await send("POST", path, body: body)
    }

    /// Performs an authenticated PATCH with a JSON body and decodes the response.
    func patch<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
        try await send("PATCH", path, body: body)
    }

    /// Shared JSON-body request path for POST/PATCH.
    private func send<T: Decodable>(_ method: String, _ path: String, body: some Encodable) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bearer = try await token() {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder.scout.encode(body)

        let (data, response) = try await session.data(for: request)
        return try decode(T.self, from: data, response: response)
    }

    /// Performs an authenticated DELETE with no response body (expects 204).
    func delete(_ path: String) async throws {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "DELETE"
        if let bearer = try await token() {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await session.data(for: request)
        try validateStatus(response)
    }

    /// Validates the HTTP status and decodes the body with the shared decoder.
    func decode<T: Decodable>(_ type: T.Type, from data: Data, response: URLResponse) throws -> T {
        try validateStatus(response)
        do {
            return try JSONDecoder.scout.decode(T.self, from: data)
        } catch {
            throw SpotServiceError.decoding(error)
        }
    }

    /// Throws unless the response is a 2xx HTTP status.
    private func validateStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SpotServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SpotServiceError.http(status: http.statusCode)
        }
    }
}
