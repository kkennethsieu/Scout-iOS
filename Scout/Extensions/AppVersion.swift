import Foundation

/// Semantic-ish version helpers for the update check. Compares dotted versions
/// **numerically per component** (so "1.10" > "1.9", unlike a string compare);
/// missing trailing components count as 0 ("1" == "1.0"); non-numeric parts → 0.
nonisolated enum AppVersion {
    /// The running app's marketing version (`CFBundleShortVersionString`), e.g. "1.0".
    static var current: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    /// The running app's build number (`CFBundleVersion`), e.g. "1".
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    static func compare(_ a: String, _ b: String) -> ComparisonResult {
        let lhs = components(a)
        let rhs = components(b)
        for i in 0..<max(lhs.count, rhs.count) {
            let x = i < lhs.count ? lhs[i] : 0
            let y = i < rhs.count ? rhs[i] : 0
            if x != y { return x < y ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }

    /// True when `a` is strictly older than `b`.
    static func isOlder(_ a: String, than b: String) -> Bool {
        compare(a, b) == .orderedAscending
    }

    private static func components(_ version: String) -> [Int] {
        version.split(separator: ".").map { Int($0) ?? 0 }
    }
}
