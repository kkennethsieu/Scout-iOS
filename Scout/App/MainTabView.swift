import SwiftUI
import CoreLocation

struct MainTabView: View {
    @State private var router = TabRouter()
    @State private var tabBarVisibility = TabBarVisibility()
    @State private var savedStore = SavedStore()
    @State private var authGate = AuthGate()
    @State private var toasts = ToastCenter()

    @Environment(AuthService.self) private var auth

    private var selection: MainTab { router.selection }

    @State private var location = LocationManager()
    @State private var showLocationPrimer = false
    /// One-shot: the primer is shown once, the first launch after sign-in.
    @AppStorage("hasRequestedLocation") private var hasRequestedLocation = false

    var body: some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 10) {
                if !tabBarVisibility.isHidden {
                    STabBar(selection: $router.selection)
                        .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut(duration: 0.1), value: tabBarVisibility.isHidden)
            // Single app-wide toast host, above every tab and surviving the
            // sign-out flip. Screens post via `@Environment(ToastCenter.self)`.
            .sToast(message: Binding(
                get: { toasts.message },
                set: { if $0 == nil { toasts.dismiss() } }
            ))
            .environment(tabBarVisibility)
            .environment(router)
            .environment(savedStore)
            .environment(authGate)
            .environment(toasts)
            .task {
                // Saved lists are user-scoped: only hydrate when signed in.
                // Anonymous users get them after gated sign-in (onChange below).
                if auth.isAuthenticated { await savedStore.load() }
            }
            .sheet(isPresented: $authGate.isPresenting, onDismiss: { authGate.sheetDismissed() }) {
                AuthScreen(isModal: true)
            }
            .onChange(of: auth.isAuthenticated) { _, isAuthed in
                if isAuthed {
                    authGate.authenticationSucceeded()
                    Task { await savedStore.load() }
                }
            }
            .sheet(isPresented: $showLocationPrimer, onDismiss: { hasRequestedLocation = true }) {
                LocationPrimerSheet(
                    onEnable: {
                        location.requestPermission()
                        showLocationPrimer = false
                    },
                    onSkip: { showLocationPrimer = false }
                )
            }
            .task {
                // Prime location once, right as the app opens on Explore.
                if !hasRequestedLocation && location.authorizationStatus == .notDetermined {
                    showLocationPrimer = true
                }
            }
    }

    /// All tabs stay instantiated and are shown/hidden by opacity so their state
    /// (scroll position, loaded data, navigation stack) survives switching — the
    /// behaviour the native `TabView` gave us for free.
    private var content: some View {
        ZStack {
            tabContent(.explore) { ExploreScreen() }
            tabContent(.map) { MapScreen() }
            tabContent(.create) { CreateFlowHost(isActive: selection == .create) }
            tabContent(.saved) { SavedScreen(isActive: selection == .saved) }
            tabContent(.profile) { ProfileScreen(isActive: selection == .profile) }
        }
    }

    @ViewBuilder
    private func tabContent<V: View>(_ tab: MainTab, @ViewBuilder _ view: () -> V) -> some View {
        view()
            .opacity(selection == tab ? 1 : 0)
            .allowsHitTesting(selection == tab)
            .zIndex(selection == tab ? 1 : 0)
    }
}

