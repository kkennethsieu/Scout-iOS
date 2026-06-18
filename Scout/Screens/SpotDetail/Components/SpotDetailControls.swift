import SwiftUI

/// Floating back / share / save controls for the Spot Detail screen. The screen
/// overlays these pinned to the top, so they stay put while the page scrolls
/// beneath them. Share / save only appear once `shareURL` is available (i.e. the
/// spot has loaded); the back button is always shown.
struct SpotDetailControls: View {
    var isSaved: Bool
    /// A link to the spot (e.g. its public Maps location). `nil` while loading —
    /// the share / save controls stay hidden until it resolves.
    var shareURL: URL?
    var spotName: String
    var onBack: () -> Void
    var onTapSave: () -> Void = {}

    var body: some View {
        HStack {
            circleIcon("chevron.left", action: onBack)
            Spacer()
            if let shareURL {
                HStack(spacing: Spacing.md) {
                    ShareLink(item: shareURL,
                              subject: Text(spotName),
                              message: Text("Check out \(spotName) on Scout")) {
                        iconLabel("square.and.arrow.up")
                    }
                    .buttonStyle(.plain)
                    circleIcon(isSaved ? "bookmark.fill" : "bookmark", action: onTapSave)
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

    /// The floating-circle icon styling, shared by the buttons and the ShareLink.
    private func iconLabel(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.sTextPrimary)
            .frame(width: 40, height: 40)
            .background(Color.sSurface.opacity(0.92), in: Circle())
            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }
}
