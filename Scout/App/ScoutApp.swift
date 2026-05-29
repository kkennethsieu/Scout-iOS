//
//  ScoutApp.swift
//  Scout
//
//  Created by Kenneth Sieu on 5/20/26.
//

import SwiftUI
import FirebaseCore

@main
struct ScoutApp: App {
    @State private var authService: AuthService
    
    init() {
        FirebaseApp.configure()
        authService = AuthService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                RootView()
            }
            .environment(authService)
            .animation(.easeInOut(duration: 0.25), value: authService.isAuthenticated)
            .animation(.easeInOut(duration: 0.25), value: authService.isResolvingAuth)
        }
    }
}

