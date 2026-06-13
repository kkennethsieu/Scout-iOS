import SwiftUI

/// A tappable list row: an optional leading icon, a title, an optional trailing
/// gray value, and a trailing chevron. The shared base for grouped lists
/// (Settings, future account/profile screens). Pair with `SListGroup` to stack
/// rows with automatic dividers.
///
/// Promoted from the Settings-local `SettingsRow`; generalized with an optional
/// leading icon and a `showsChevron` toggle so non-navigating rows can opt out.
struct SListRow: View {
    let title: String
    var icon: String? = nil
    /// Optional trailing value (e.g. "English", "Not connected").
    var value: String? = nil
    /// Renders the title (and icon) in `sError` — e.g. "Delete account".
    var isDestructive: Bool = false
    /// Trailing disclosure chevron. On by default; off for terminal actions.
    var showsChevron: Bool = true
    let action: () -> Void

    private var titleColor: Color { isDestructive ? Color.sError : Color.sTextPrimary }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(titleColor)
                        .frame(width: 24)
                }

                Text(title)
                    .font(.sBody)
                    .foregroundStyle(titleColor)

                Spacer()

                if let value {
                    Text(value)
                        .font(.sBody)
                        .foregroundStyle(Color.sTextSecondary)
                }

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.sTextTertiary)
                }
            }
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableRowStyle())
    }
}

// MARK: - Press feedback

/// Subtle fade + scale on press so a tap reads as responsive (e.g. before a
/// confirmation dialog slides up) instead of feeling instant.
private struct PressableRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("SListRow") {
    SListGroup {
        SListRow(title: "Push notifications") {}
        SListRow(title: "Language", value: "English") {}
        SListRow(title: "Privacy Policy", icon: "lock") {}
        SListRow(title: "Log out", showsChevron: false) {}
        SListRow(title: "Delete account", isDestructive: true, showsChevron: false) {}
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.sBackground)
}
