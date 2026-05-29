import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreScreen()
                .tabItem {
                    Label("Explore", systemImage: "square.grid.2x2")
                }
                .tag(0)
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(1)
            
            CreateView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(4)
        }
        .tint(Color.sAccent)
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

struct CreateView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sBackground.ignoresSafeArea()
                Text("Create").font(.sHeadingM).foregroundStyle(Color.sTextPrimary)
            }
            .navigationTitle("Create")
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
