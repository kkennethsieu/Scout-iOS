import Foundation

/// A single user review. Mirrors the backend `ReviewResponse` schema.
nonisolated struct Review: Identifiable, Decodable, Hashable {
    // Server-generated identity / timestamp — always present.
    let id: String
    let spotId: String
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
    let entranceFee: String?
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

// MARK: - Pagination

/// A page of reviews. Mirrors the backend `PaginatedReviews` schema
/// (`/spots/{id}/reviews`). `nextCursor` (from `next_cursor`) is non-nil when
/// more pages are available — pass it back as `cursor` to fetch the next page.
nonisolated struct PaginatedReviews: Decodable {
    let items: [Review]
    let limit: Int
    let nextCursor: String?
}

// MARK: - Sample data

nonisolated extension Review {
    static let samples: [Review] = [
        Review(
            id: "r1",
            spotId: "1",
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
            entranceFee: "Free",
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
            userId: "u2",
            photoUrls: [URL(string: "https://picsum.photos/seed/review-c/600/600")!],
            overallRating: 4,
            notes: "Stunning spot but the trail in was steeper than expected. Worth it for the symmetry of the reflection at blue hour.",
            bestTimeOfDay: ["BlueHour"],
            bestSeason: ["Winter"],
            accessLevel: "Difficult",
            entranceFee: "Free",
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
