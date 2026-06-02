import SwiftUI

/// Shown after a photo upload: the backend matched a few candidate spots near
/// the photo's location and the user picks which one they shot. Falls through to
/// creating a brand-new spot if none fit. Presentation-only — `CreateSpotFlow`
/// owns the sheet chrome and navigation.
struct NearbySpotsSheet: View {
    var spots: [NearbySpot] = NearbySpot.samples
    var onSelect: (NearbySpot) -> Void = { _ in }
    var onCreateNew: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(spots) { spot in
                        NearbySpotRow(spot: spot) {
                            onSelect(spot)
                        }
                        if spot.id != spots.last?.id {
                            Divider().background(Color.sBorderSubtle)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }

            SPrimaryButton(title: "Can't find your spot? Create new") {
                onCreateNew()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sBackground)
        .navigationTitle("Nearby spots")
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Nearby spots")
                .font(.sHeadingL)
                .foregroundStyle(Color.sTextPrimary)

            Text("We found \(spots.count) spots near your photo — which one?")
                .font(.sBody)
                .foregroundStyle(Color.sTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.md)
    }
}

// MARK: - Presentation model

/// Display model for a nearby-spot candidate. Maps from a `SpotSummary` plus a
/// distance computed from the photo's coordinate (see `CreateSpotViewModel`).
/// `distanceMeters` is kept for sorting; `distance` is the formatted label.
nonisolated struct NearbySpot: Identifiable, Hashable {
    let id: String
    let name: String
    let thumbnailURL: URL?
    let distance: String
    let category: String
    var distanceMeters: Double = 0
}

extension NearbySpot {
    static let samples: [NearbySpot] = [
        NearbySpot(id: "1",
                   name: "The Emerald Basin",
                   thumbnailURL: URL(string: "https://picsum.photos/seed/emerald/200/200"),
                   distance: "45m away",
                   category: "Alpine",
                   distanceMeters: 45),
        NearbySpot(id: "2",
                   name: "Bixby Creek Bridge",
                   thumbnailURL: URL(string: "https://picsum.photos/seed/bixby/200/200"),
                   distance: "120m away",
                   category: "Coastal",
                   distanceMeters: 120),
        NearbySpot(id: "3",
                   name: "Muir Woods",
                   thumbnailURL: URL(string: "https://picsum.photos/seed/muir/200/200"),
                   distance: "1.2km away",
                   category: "Forest",
                   distanceMeters: 1200)
    ]
}

// MARK: - Preview

#Preview("Nearby Spots") {
    NavigationStack {
        NearbySpotsSheet()
    }
}

#Preview("Nearby Spots — Dark") {
    NavigationStack {
        NearbySpotsSheet()
    }
    .preferredColorScheme(.dark)
}
