import Foundation

/// App-wide client config from the backend (`GET /config`) — currently the iOS
/// version gates that drive the "update your app" prompt. Keys arrive snake_case
/// and are camel-cased by `JSONDecoder.scout`.
nonisolated struct AppConfig: Decodable, Equatable {
    /// Builds older than this are unsupported → blocking "update required" gate.
    let iosMinVersion: String
    /// Newest published build → soft "update available" nudge when behind it.
    let iosLatestVersion: String
    /// Where the "Update" button sends the user (App Store / TestFlight).
    let iosUpdateUrl: String
}
