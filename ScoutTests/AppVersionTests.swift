import Testing
@testable import Scout

/// Covers `AppVersion.compare` / `isOlder` — numeric, per-component version
/// comparison (the basis of the update gate).
struct AppVersionTests {

    @Test func comparesNumericallyNotLexically() {
        #expect(AppVersion.compare("1.2", "1.10") == .orderedAscending)   // 2 < 10, not "2" < "1"
        #expect(AppVersion.compare("1.10", "1.9") == .orderedDescending)  // 10 > 9
    }

    @Test func ordersMajorMinorPatch() {
        #expect(AppVersion.isOlder("1.0", than: "1.1"))
        #expect(AppVersion.isOlder("1.9", than: "2.0"))
        #expect(AppVersion.isOlder("2.0", than: "1.9") == false)
    }

    @Test func equalVersionsAreNotOlder() {
        #expect(AppVersion.compare("1.2.3", "1.2.3") == .orderedSame)
        #expect(AppVersion.isOlder("1.2.3", than: "1.2.3") == false)
    }

    @Test func missingTrailingComponentsCountAsZero() {
        #expect(AppVersion.compare("1", "1.0") == .orderedSame)
        #expect(AppVersion.isOlder("1", than: "1.1"))
        #expect(AppVersion.isOlder("1.0.0", than: "1") == false)
    }

    @Test func nonNumericComponentsTreatedAsZero() {
        #expect(AppVersion.compare("1.x", "1.0") == .orderedSame)
        #expect(AppVersion.isOlder("1.x", than: "1.1"))
    }
}
