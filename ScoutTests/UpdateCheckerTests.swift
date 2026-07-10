import Testing
import Foundation
@testable import Scout

/// Covers `UpdateChecker`: mapping the backend version gates + the running version
/// onto the update state, and failing open when config can't be fetched.
@MainActor
struct UpdateCheckerTests {

    private let updateURL = "https://apps.apple.com/app/scout"

    private func makeChecker(current: String,
                             min: String, latest: String,
                             url: String? = nil,
                             error: Bool = false) -> UpdateChecker {
        let service = StubConfigService(
            config: AppConfig(iosMinVersion: min, iosLatestVersion: latest,
                              iosUpdateUrl: url ?? updateURL),
            fails: error
        )
        return UpdateChecker(service: service, currentVersion: current)
    }

    @Test func requiredWhenBelowMinimum() async {
        let checker = makeChecker(current: "1.0", min: "1.1", latest: "1.5")
        await checker.check()
        #expect(checker.state == .required(URL(string: updateURL)!))
    }

    @Test func optionalWhenBelowLatestButSupported() async {
        let checker = makeChecker(current: "1.2", min: "1.0", latest: "1.5")
        await checker.check()
        #expect(checker.state == .optional(URL(string: updateURL)!))
    }

    @Test func upToDateWhenAtOrAboveLatest() async {
        let atLatest = makeChecker(current: "1.5", min: "1.0", latest: "1.5")
        await atLatest.check()
        #expect(atLatest.state == .upToDate)

        let ahead = makeChecker(current: "1.6", min: "1.0", latest: "1.5")
        await ahead.check()
        #expect(ahead.state == .upToDate)
    }

    @Test func minimumOutranksLatest() async {
        // Below both → required (the blocking gate wins).
        let checker = makeChecker(current: "0.9", min: "1.1", latest: "1.5")
        await checker.check()
        #expect(checker.state == .required(URL(string: updateURL)!))
    }

    @Test func failsOpenWhenServiceThrows() async {
        let checker = makeChecker(current: "0.1", min: "9.9", latest: "9.9", error: true)
        await checker.check()
        #expect(checker.state == .unknown)   // never blocks on a fetch failure
    }

    @Test func failsOpenOnMalformedURL() async {
        let checker = makeChecker(current: "1.0", min: "2.0", latest: "2.0", url: "")
        await checker.check()
        #expect(checker.state == .unknown)
    }
}

// MARK: - Stub

private nonisolated struct StubConfigService: AppConfigService {
    var config: AppConfig
    var fails: Bool

    func fetchAppConfig() async throws -> AppConfig {
        if fails { throw SpotServiceError.invalidResponse }
        return config
    }
}
