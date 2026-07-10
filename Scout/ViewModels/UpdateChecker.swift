import Foundation
import Observation

/// Decides whether the running build is behind, from the backend's `/config`
/// version gates. Drives the launch-time "update your app" experience: a blocking
/// gate below the minimum supported version, a dismissible nudge below the latest.
///
/// Injected app-wide via `.environment` from `ScoutApp`; read by `RootView` (hard
/// gate) and `MainTabView` (soft nudge). The service + current version are
/// injectable seams for tests.
@Observable
@MainActor
final class UpdateChecker {
    enum UpdateState: Equatable {
        /// Not checked yet, or the check failed — the app proceeds normally.
        case unknown
        case upToDate
        /// Behind the latest version → dismissible nudge, opening the URL.
        case optional(URL)
        /// Below the minimum supported version → blocking gate, opening the URL.
        case required(URL)
    }

    private(set) var state: UpdateState = .unknown

    private let service: AppConfigService
    private let currentVersion: String

    init(service: AppConfigService = AppServices.appConfig,
         currentVersion: String = AppVersion.current) {
        self.service = service
        self.currentVersion = currentVersion
    }

    /// Fetches config and resolves the state. **Fails open**: any network/parse/URL
    /// problem leaves the app unblocked (state unchanged from `.unknown`).
    func check() async {
        guard let config = try? await service.fetchAppConfig(),
              let url = URL(string: config.iosUpdateUrl) else { return }

        if AppVersion.isOlder(currentVersion, than: config.iosMinVersion) {
            state = .required(url)
        } else if AppVersion.isOlder(currentVersion, than: config.iosLatestVersion) {
            state = .optional(url)
        } else {
            state = .upToDate
        }
    }
}
