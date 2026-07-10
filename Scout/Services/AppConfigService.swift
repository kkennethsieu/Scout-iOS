import Foundation

/// Fetches app-wide client config (`GET /config`) — the version gates behind the
/// "update your app" prompt. Unauthenticated and not user-specific, so it's its
/// own small service (mirrors `LegalService`) that callers depend on via protocol.
nonisolated protocol AppConfigService {
    func fetchAppConfig() async throws -> AppConfig
}

/// `BackendClient`-backed `AppConfigService` (`GET /config`).
nonisolated struct LiveAppConfigService: AppConfigService {
    var client = BackendClient()

    func fetchAppConfig() async throws -> AppConfig {
        try await client.get("config")
    }
}

/// Hardcoded config for development / previews. Defaults keep the app "up to date"
/// (both gates at/below a low version) so nothing prompts unless a test overrides.
nonisolated struct MockAppConfigService: AppConfigService {
    var config = AppConfig(iosMinVersion: "1.0", iosLatestVersion: "1.1.0",
                           iosUpdateUrl: "https://apps.apple.com/app/scout")
    var delay: Duration = .milliseconds(100)

    func fetchAppConfig() async throws -> AppConfig {
        try await Task.sleep(for: delay)
        return config
    }
}
