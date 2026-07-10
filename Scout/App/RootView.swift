import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Environment(UpdateChecker.self) private var updateChecker

    var body: some View {
        content
            .task { await updateChecker.check() }
    }

    @ViewBuilder
    private var content: some View {
        // A required update outranks everything — the build is unsupported.
        if case .required(let url) = updateChecker.state {
            UpdateRequiredScreen(updateURL: url)
        } else if auth.isResolvingAuth {
            // Anonymous users browse freely; sign-in is gated at the action level
            // (see `AuthGate`), not here. Once auth resolves, always show the app.
            SplashScreen()
        } else {
            MainTabView()
        }
    }
}
