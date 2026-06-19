import SwiftUI

/// The bottom-anchored preview card shown when a map pin is selected: a
/// `MapSpotPreview` that navigates to the spot's detail, sliding up from the
/// bottom. Reused by the Map tab and the saved-list map.
///
/// Drop it into a map screen's `ZStack`. Pass the currently-selected spot (`nil`
/// hides the card). Requires a `navigationDestination(for: SpotSummary.self)`
/// registered on the enclosing `NavigationStack` (both map screens have one).
struct SpotPreviewOverlay: View {
    /// The selected spot, or `nil` when nothing is selected.
    let spot: SpotSummary?
    /// Optional distance string (e.g. "4.2 mi") shown in the card.
    var distance: String? = nil
    /// Space below the card — larger on the Map tab to clear the tab bar.
    var bottomPadding: CGFloat = Spacing.xl

    var body: some View {
        VStack {
            Spacer()
            if let spot {
                NavigationLink(value: spot) {
                    MapSpotPreview(spot: spot, distance: distance)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, bottomPadding)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: spot?.id)
    }
}
