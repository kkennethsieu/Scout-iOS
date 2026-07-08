import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth
    
    var body: some View {
        // Anonymous users browse freely; sign-in is gated at the action level
        // (see `AuthGate`), not here. Once auth resolves, always show the app.
        if auth.isResolvingAuth {
            SplashScreen()
        } else {
            MainTabView()
        }
    }
}
