import Testing
@testable import Scout

/// Covers `AuthGate`'s action-level gating logic: run-now when signed in,
/// defer-and-present when signed out, and the completion / cancel transitions.
/// Auth state is injected via the `isAuthenticated` seam so no Firebase is touched.
@MainActor
struct AuthGateTests {

    @Test func runsImmediatelyWhenAuthenticated() {
        let gate = AuthGate(isAuthenticated: { true })
        var ran = false
        gate.require { ran = true }

        #expect(ran)
        #expect(gate.isPresenting == false)
    }

    @Test func defersAndPresentsWhenSignedOut() {
        let gate = AuthGate(isAuthenticated: { false })
        var ran = false
        gate.require { ran = true }

        #expect(ran == false)
        #expect(gate.isPresenting)
    }

    @Test func successDismissesThenRunsActionOnceOnDismiss() {
        let gate = AuthGate(isAuthenticated: { false })
        var runCount = 0
        gate.require { runCount += 1 }

        // Success dismisses the sheet but defers the action to onDismiss.
        gate.authenticationSucceeded()
        #expect(gate.isPresenting == false)
        #expect(runCount == 0)

        // The action runs once the sheet has dismissed.
        gate.sheetDismissed()
        #expect(runCount == 1)

        // A second dismissal is a no-op — the action was cleared.
        gate.sheetDismissed()
        #expect(runCount == 1)
    }

    @Test func cancelDismissDiscardsPendingAction() {
        let gate = AuthGate(isAuthenticated: { false })
        var ran = false
        gate.require { ran = true }

        // Sheet dismissed without a successful sign-in (swipe / close button).
        gate.sheetDismissed()
        #expect(ran == false)
    }

    @Test func successIsIgnoredWhenNotPresenting() {
        let gate = AuthGate(isAuthenticated: { false })
        // No pending require(); an auth-state flip shouldn't arm anything.
        gate.authenticationSucceeded()
        var ran = false
        gate.require { ran = true }  // now signed-out path stashes again
        gate.sheetDismissed()
        #expect(ran == false)
    }
}
