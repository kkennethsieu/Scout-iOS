import SwiftUI
import CoreLocation

struct MainTabView: View {
    @State private var selection: MainTab = .explore
    @State private var showCreateSheet = false
    @State private var tabBarVisibility = TabBarVisibility()

    @State private var location = LocationManager()
    @State private var showLocationPrimer = false
    /// One-shot: the primer is shown once, the first launch after sign-in.
    @AppStorage("hasRequestedLocation") private var hasRequestedLocation = false

    var body: some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 10) {
                if !tabBarVisibility.isHidden {
                    STabBar(selection: $selection) {
                        showCreateSheet = true
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut(duration: 0.1), value: tabBarVisibility.isHidden)
            .environment(tabBarVisibility)
            .modifier(CreateSpotFlow(isPresented: $showCreateSheet))
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
            tabContent(.saved) { SavedView() }
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

// MARK: - Placeholder Views

struct SavedView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sBackground.ignoresSafeArea()
                Text("Saved").font(.sHeadingM).foregroundStyle(Color.sTextPrimary)
            }
            .navigationTitle("Saved")
        }
    }
}

