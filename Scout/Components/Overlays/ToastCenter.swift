import SwiftUI
import Observation

/// App-wide host for transient success toasts. Injected via `.environment` from
/// `MainTabView` (which also renders the single `.sToast` bound to it), so any
/// screen can confirm an action — "Saved to your lists", "Review deleted",
/// "Signed out" — with `@Environment(ToastCenter.self)` → `show(_:)`. Hosting it
/// at the tab root means the toast floats above every tab and survives the
/// sign-out flip (so log-out / account-deletion confirmations still appear).
@MainActor
@Observable
final class ToastCenter {
    /// The message currently showing, or `nil`. The `.sToast` modifier auto-clears
    /// it after its duration.
    var message: String?

    /// Shows a toast (replacing any current one — the newest wins).
    func show(_ message: String) {
        self.message = message
    }

    func dismiss() {
        message = nil
    }
}
