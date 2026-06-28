import SwiftUI
import Observation

/// The five navigable destinations. The center `.create` tab is a real, selectable
/// destination (it opens the full-page `ShareLocationScreen`), just rendered with a
/// prominent treatment in the bar.
enum MainTab: Hashable, CaseIterable {
    case explore, map, create, saved, profile

    var title: String {
        switch self {
        case .explore: "Explore"
        case .map:     "Map"
        case .create: "Create"
        case .saved:   "Saved"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .explore: "square.grid.2x2"
        case .map:     "map"
        case .create: "plus"
        case .saved:   "bookmark"
        case .profile: "person"
        }
    }
}

/// Shared switch that pushed screens (e.g. Spot Detail) flip to hide the tab bar
/// while they're on top — replacing the native `.toolbar(.hidden, for: .tabBar)`
/// behaviour we lose by not using `UITabBar`.
///
/// Backed by a *count* of hide requests rather than a single `Bool`: when one
/// hiding screen pushes another (e.g. a saved-list detail → spot detail), the
/// outgoing screen's `onDisappear` can fire after the incoming screen's
/// `onAppear`. A Bool would flip back to shown and leak the bar onto the child;
/// the counter stays positive as long as *any* hiding screen is on top.
@MainActor
@Observable
final class TabBarVisibility {
    private(set) var hideRequestCount = 0

    /// True while at least one pushed screen wants the tab bar hidden.
    var isHidden: Bool { hideRequestCount > 0 }

    /// Call from a screen's `onAppear` to hide the tab bar while it's on top.
    func requestHidden() { hideRequestCount += 1 }

    /// Call from the matching `onDisappear`. Clamped so unbalanced calls can't
    /// drive the count negative and wedge the bar hidden.
    func releaseHidden() { hideRequestCount = max(0, hideRequestCount - 1) }
}

/// Owns the selected tab so any screen can switch tabs programmatically (e.g. an
/// empty-state CTA that sends the user to Explore). Injected via `.environment`
/// by `MainTabView`, which also binds the tab bar to it.
@MainActor
@Observable
final class TabRouter {
    var selection: MainTab = .explore
    var scrollToTopTrigger = false
}

/// Custom bottom tab bar. Replaces SwiftUI's `TabView` bar (and its backing
/// `UITabBarController`) so all tabs stay instantiated and keep their state when
/// switching (the opacity-based persistence in `MainTabView`). The center
/// `.create` tab is selectable like the rest, just rendered prominently.
struct STabBar: View {
    @Binding var selection: MainTab
    @Environment(TabRouter.self) private var router

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            barItem(.explore)
            barItem(.map)
            barItem(.create)
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

    @ViewBuilder
    private func barItem(_ tab: MainTab) -> some View {
        Button {
            if selection == tab{
                router.scrollToTopTrigger.toggle()
            }
            selection = tab
        } label: {
            if tab == .create {
                createLabel(isActive: selection == tab)
            } else {
                label(icon: tab.icon, title: tab.title, isActive: selection == tab)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selection == tab)
    }

    /// The prominent center Create item: a filled accent symbol that pops out from
    /// the plain tab items, while still selecting the tab like any other.
    private func createLabel(isActive: Bool) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28, weight: .regular))
                .frame(height: 26)
                .foregroundStyle(Color.sAccent)
            Text(MainTab.create.title)
                .font(.sCaption)
                .foregroundStyle(isActive ? Color.sAccent : Color.sTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MainTab.create.title)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
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
                STabBar(selection: $selection)
            }
            .background(Color.sBackground)
        }
    }
    return Harness()
}
