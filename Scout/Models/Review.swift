import Foundation

/// A single user review. Mirrors the backend `ReviewResponse` schema.
nonisolated struct Review: Identifiable, Decodable, Hashable {
    // Server-generated identity / timestamp — always present.
    let id: String
    let spotId: String
    /// Denormalized from the spot at create time so a fetched review carries its
    /// spot's name without a second lookup. Present on the profile "my reviews"
    /// endpoint; absent on a spot's own reviews list, where the spot is already
    /// known. Optional for legacy docs predating this field.
    let spotName: String?
    /// Obfuscated/public coordinates + place names denormalized from the spot
    /// (the exact location is never exposed). Always returned by the backend.
    let publicLat: Double
    let publicLng: Double
    let city: String
    let adminArea: String
    let userId: String
    let photoUrls: [URL]
    // Only required review content.
    let overallRating: Int
    // Optional content — the submitter may not have answered. Tristate bools
    // distinguish "No" (`false`) from "not answered" (`nil`).
    let notes: String?
    let bestTimeOfDay: [String]
    let bestSeason: [String]
    let accessLevel: String?
    let entranceFee: Double?
    let crowdLevel: String?
    let gearRecommendations: String?
    let compositionHints: String?
    let permitRequired: Bool?
    let droneAllowed: Bool?
    let tripodAllowed: Bool?
    let createdAt: Date

    /// Time-of-day values resolved to display models (unknown values dropped).
    var times: [TimeOfDay] { bestTimeOfDay.compactMap(TimeOfDay.init(raw:)) }

    /// Season values resolved to display models (unknown values dropped).
    var seasons: [Season] { bestSeason.compactMap(Season.init(raw:)) }
}

// MARK: - Sample data

nonisolated extension Review {
    static let samples: [Review] = [
        Review(
            id: "r1",
            spotId: "1",
            spotName: "Emerald Basin Ridge",
            publicLat: 47.6062,
            publicLng: -122.3321,
            city: "Seattle",
            adminArea: "WA",
            userId: "u1",
            photoUrls: [
                URL(string: "https://picsum.photos/seed/review-a/600/600")!,
                URL(string: "https://picsum.photos/seed/review-b/600/600")!
            ],
            overallRating: 5,
            notes: "Caught the first light hitting the basin around 6am. The reflection on the water is absolutely pristine this time of year. Be sure to bring a wide-angle lens for the full scope.",
            bestTimeOfDay: ["GoldenHour", "Sunrise"],
            bestSeason: ["Spring", "Fall"],
            accessLevel: "Moderate",
            entranceFee: 0,
            crowdLevel: "Moderate",
            gearRecommendations: "Wide-angle lens (16-35mm). ND filters for the water.",
            compositionHints: "Use the foreground rocks for depth.",
            permitRequired: false,
            droneAllowed: false,
            tripodAllowed: true,
            createdAt: Date().addingTimeInterval(-2 * 3600)
        ),
        Review(
            id: "r2",
            spotId: "1",
            spotName: "Cedar Cathedral",
            publicLat: 45.5152,
            publicLng: -122.6784,
            city: "Portland",
            adminArea: "OR",
            userId: "u2",
            photoUrls: [URL(string: "https://picsum.photos/seed/review-c/600/600")!],
            overallRating: 4,
            notes: "Stunning spot but the trail in was steeper than expected. Worth it for the symmetry of the reflection at blue hour.",
            bestTimeOfDay: ["BlueHour"],
            bestSeason: ["Winter"],
            accessLevel: "Difficult",
            entranceFee: 0,
            crowdLevel: "Light",
            gearRecommendations: nil,
            compositionHints: nil,
            permitRequired: nil,
            droneAllowed: nil,
            tripodAllowed: true,
            createdAt: Date().addingTimeInterval(-26 * 3600)
        )
    ]
}
