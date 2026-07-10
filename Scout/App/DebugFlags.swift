#if DEBUG
import Foundation

/// Debug-only switches for exercising states that are hard to reproduce against
/// the real backend. Compiled out of Release builds entirely, so nothing here can
/// ship. Edit the values here to test, then set them back to the "off" value.
enum DebugFlags {

    /// Forces the update checker into a state without touching the backend.
    /// `nil` → use the live `/config` endpoint (normal behavior).
    ///
    /// To test, return one of the presets below:
    ///   - `.softUpdate` → the dismissible "Update available" nudge
    ///   - `.hardUpdate` → the blocking "Time to update" gate
    static var forcedUpdateConfig: AppConfig? {
        nil
//         return .softUpdate
//         return .hardUpdate
    }
}

extension AppConfig {
    private static let scoutAppStoreURL =
        "https://apps.apple.com/us/app/scout-photo-locations/id6781030287"

    /// A config that always reads as "a newer version exists" (soft nudge),
    /// regardless of the running build.
    static let softUpdate = AppConfig(
        iosMinVersion: "0.0", iosLatestVersion: "99.0.0", iosUpdateUrl: scoutAppStoreURL)

    /// A config that always reads as "you must update" (blocking gate).
    static let hardUpdate = AppConfig(
        iosMinVersion: "99.0.0", iosLatestVersion: "99.0.0", iosUpdateUrl: scoutAppStoreURL)
}
#endif
