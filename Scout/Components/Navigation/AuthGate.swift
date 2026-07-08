import SwiftUI
import Observation

/// Central coordinator for **action-level** auth gating. The app lets anonymous
/// users browse freely (Explore / Map / Spot Detail / Search); only actions that
/// need an identity — create/upload, leave a review, save to a list, view
/// Saved/Profile — call `require(_:)`.
///
/// If the user is signed in the action runs immediately. Otherwise the action is
/// stashed and the sign-in sheet is presented (bound to `isPresenting`); once
/// sign-in succeeds, `MainTabView` observes `AuthService.isAuthenticated` flipping
/// and calls `authenticationSucceeded()`, which dismisses the sheet. The stashed
/// action runs from the sheet's `onDismiss` (via `sheetDismissed()`) — *after* the
/// sign-in sheet is fully gone — so it can safely present a follow-up sheet (e.g.
/// "Save to list") without the two colliding. So "tap Save → sign in → the save
/// sheet opens" is seamless.
///
/// Injected via `.environment` from `MainTabView`. The `isAuthenticated` closure
/// is the test seam: production reads `AuthService.shared`, tests inject a stub.
@MainActor
@Observable
final class AuthGate {
    /// Drives the sign-in sheet presented by `MainTabView`.
    var isPresenting = false

    private var pendingAction: (() -> Void)?
    /// Set when auth succeeds while the sheet is up, so `sheetDismissed()` knows to
    /// run the pending action rather than discard it (as on a cancel).
    private var didAuthenticate = false
    private let isAuthenticated: @MainActor () -> Bool

    init(isAuthenticated: @escaping @MainActor () -> Bool = { AuthService.shared.isAuthenticated }) {
        self.isAuthenticated = isAuthenticated
    }

    /// Runs `action` now if signed in; otherwise presents sign-in and runs it
    /// after a successful sign-in (once the sheet has dismissed).
    func require(_ action: @escaping () -> Void) {
        if isAuthenticated() {
            action()
        } else {
            pendingAction = action
            didAuthenticate = false
            isPresenting = true
        }
    }

    /// Called when auth flips to authenticated while the sheet is up: dismiss it.
    /// The pending action runs from `sheetDismissed()` once dismissal completes.
    func authenticationSucceeded() {
        guard isPresenting else { return }
        didAuthenticate = true
        isPresenting = false
    }

    /// Called from the sheet's `onDismiss`. Runs the pending action only if the
    /// sheet closed because sign-in succeeded; a cancel/swipe discards it.
    func sheetDismissed() {
        let action = pendingAction
        let run = didAuthenticate
        pendingAction = nil
        didAuthenticate = false
        if run { action?() }
    }
}
