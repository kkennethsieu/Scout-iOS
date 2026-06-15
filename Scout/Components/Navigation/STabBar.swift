import SwiftUI
import Observation

/// The four navigable destinations. The center "Post" action is intentionally
/// *not* a case here — it's a button, not a destination.
enum MainTab: Hashable, CaseIterable {
    case explore, map, saved, profile

    var title: String {
        switch self {
        case .explore: "Explore"
        case .map:     "Map"
        case .saved:   "Saved"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .explore: "square.grid.2x2"
        case .map:     "map"
        case .saved:   "bookmark"
        case .profile: "person"
        }
    }
}

/// Shared switch that pushed screens (e.g. Spot Detail) flip to hide the tab bar
/// while they're on top — replacing the native `.toolbar(.hidden, for: .tabBar)`
/// behaviour we lose by not using `UITabBar`.
@MainActor
@Observable
final class TabBarVisibility {
    var isHidden = false
}

/// Owns the selected tab so any screen can switch tabs programmatically (e.g. an
/// empty-state CTA that sends the user to Explore). Injected via `.environment`
/// by `MainTabView`, which also binds the tab bar to it.
@MainActor
@Observable
final class TabRouter {
    var selection: MainTab = .explore
}

/// Custom bottom tab bar. Replaces SwiftUI's `TabView` bar (and its backing
/// `UITabBarController`) so the center "+" can present a sheet without the tab
/// bar ever committing a selection change — which is what caused the one-frame
/// blink with the native bar.
struct STabBar: View {
    @Binding var selection: MainTab
    var onPost: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            barItem(.explore)
            barItem(.map)
            postItem
            barItem(.saved)
            barItem(.profile)
        }
        .padding(.top, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background {
            Color.sBackground
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.sBorderSubtle)
                        .frame(height: 0.5)
                }
        }
    }

    // MARK: - Items

    private func barItem(_ tab: MainTab) -> some View {
        Button {
            selection = tab
        } label: {
            label(icon: tab.icon, title: tab.title, isActive: selection == tab)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selection == tab)
    }

    private var postItem: some View {
        Button(action: onPost) {
            label(icon: "plus.circle.fill", title: "Post", isActive: false)
        }
        .buttonStyle(.plain)
    }

    private func label(icon: String, title: String, isActive: Bool) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .frame(height: 26)
            Text(title)
                .font(.sCaption)
        }
        .foregroundStyle(isActive ? Color.sAccent : Color.sTextTertiary)
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview("Tab Bar") {
    struct Harness: View {
        @State private var selection: MainTab = .explore
        var body: some View {
            VStack {
                Spacer()
                STabBar(selection: $selection) {}
            }
            .background(Color.sBackground)
        }
    }
    return Harness()
}
