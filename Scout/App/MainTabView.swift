import SwiftUI

struct MainTabView: View {
    @State private var selection: MainTab = .explore
    @State private var showCreateSheet = false
    @State private var tabBarVisibility = TabBarVisibility()

    var body: some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !tabBarVisibility.isHidden {
                    STabBar(selection: $selection) {
                        showCreateSheet = true
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut(duration: 0.1), value: tabBarVisibility.isHidden)
            .environment(tabBarVisibility)
            .sheet(isPresented: $showCreateSheet) {
                ShareSpotSheet(
                    onUploadPhotos: {
                        // TODO: present photo-upload review flow
                    },
                    onCurrentLocation: {
                        // TODO: present Confirm Location / precise pin flow
                    }
                )
            }
    }

    /// All tabs stay instantiated and are shown/hidden by opacity so their state
    /// (scroll position, loaded data, navigation stack) survives switching — the
    /// behaviour the native `TabView` gave us for free.
    private var content: some View {
        ZStack {
            tabContent(.explore) { ExploreScreen() }
            tabContent(.map) { MapView() }
            tabContent(.saved) { SavedView() }
            tabContent(.profile) { ProfileView() }
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

struct MapView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sBackground.ignoresSafeArea()
                Text("Map").font(.sHeadingM).foregroundStyle(Color.sTextPrimary)
            }
            .navigationTitle("Map")
        }
    }
}

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

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sBackground.ignoresSafeArea()
                Text("Profile").font(.sHeadingM).foregroundStyle(Color.sTextPrimary)
                SignedInPlaceholder()
            }
            .navigationTitle("Profile")
        }
    }
}

private struct SignedInPlaceholder: View {
    @Environment(AuthService.self) private var auth
    
    var body: some View {
        ZStack {
            Color.sBackground.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.sAccent)
                
                Text("Signed in as")
                    .font(.sBodyL)
                    .foregroundStyle(Color.sTextSecondary)
                
                Text(auth.currentUser?.email ?? auth.currentUser?.displayName ?? "Unknown")
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                
                SPrimaryButton(title: "Sign out") {
                    try? auth.signOut()
                }
                .padding(.top, Spacing.xl)
                .padding(.horizontal, Spacing.lg)
            }
        }
    }
}
