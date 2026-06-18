import SwiftUI

/// Floating back / sort / more controls for the Saved-list detail screen. The
/// screen overlays these pinned to the top so they stay put while the list
/// scrolls beneath them — the same format as `SpotDetailControls`.
///
/// The overflow menu (edit / delete) is hidden for system lists like Favorites,
/// which can't be edited or deleted.
struct SavedListControls: View {
    var showsMenu: Bool
    var onBack: () -> Void
    var onSort: () -> Void
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        HStack {
            circleIcon("chevron.left", action: onBack)
                .accessibilityLabel("Back")

            Spacer()

            HStack(spacing: Spacing.md) {
                circleIcon("arrow.up.arrow.down", action: onSort)
                    .accessibilityLabel("Sort")

                if showsMenu {
                    Menu {
                        Button { onEdit() } label: {
                            Label("Edit list", systemImage: "pencil")
                        }
                        Button(role: .destructive) { onDelete() } label: {
                            Label("Delete list", systemImage: "trash")
                        }
                    } label: {
                        iconLabel("ellipsis")
                    }
                    .accessibilityLabel("More")
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func circleIcon(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            iconLabel(symbol)
        }
        .buttonStyle(.plain)
    }

    /// The floating-circle icon styling, shared by the buttons and the menu label.
    private func iconLabel(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.sTextPrimary)
            .frame(width: 40, height: 40)
            .background(Color.sSurface.opacity(0.92), in: Circle())
            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }
}

// MARK: - Preview

#Preview("Saved List Controls") {
    ZStack(alignment: .top) {
        Color.sBackground.ignoresSafeArea()
        VStack(spacing: Spacing.lg) {
            SavedListControls(showsMenu: true, onBack: {}, onSort: {})
            SavedListControls(showsMenu: false, onBack: {}, onSort: {})
        }
        .padding(.top, Spacing.xxl)
    }
}
