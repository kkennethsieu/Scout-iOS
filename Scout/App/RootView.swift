import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth
    
    var body: some View {
        if auth.isResolvingAuth {
            SplashScreen()
        } else if auth.isAuthenticated {
            MainTabView()
        } else {
            AuthScreen()
        }
    }
}
