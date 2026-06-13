import Foundation

/// Fetches the hosted legal-document links (`GET /legal`). Unauthenticated and
/// not user-specific — its own small service so view models depend on a protocol
/// rather than `BackendClient` directly.
nonisolated protocol LegalService {
    func fetchLegalLinks() async throws -> LegalResponse
}

/// `BackendClient`-backed `LegalService` (`GET /legal`).
nonisolated struct LiveLegalService: LegalService {
    var client = BackendClient()

    func fetchLegalLinks() async throws -> LegalResponse {
        try await client.get("legal")
    }
}

/// Hardcoded links for development / real-device fallback.
nonisolated struct MockLegalService: LegalService {
    var delay: Duration = .milliseconds(200)

    func fetchLegalLinks() async throws -> LegalResponse {
        try await Task.sleep(for: delay)
        return LegalResponse(
            privacyPolicyUrl: "https://scout.app/privacy",
            termsOfServiceUrl: "https://scout.app/terms"
        )
    }
}
