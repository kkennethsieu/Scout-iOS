import Foundation

/// Full spot detail. Mirrors the backend `SpotResponse` schema, including the
/// v2 aggregate fields (`best_times`, `mode_permit_required`,
/// `recent_gear_recommendations`, etc.).
nonisolated struct SpotDetail: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let publicLat: Double
    let publicLng: Double
    let city: String
    let adminArea: String
    let country: String
    let createdAt: Date
    let reviewCount: Int
    let avgRating: Double
    let recentReviewPhotos: [RecentReviewPhoto]
    let modeAccessLevel: String?
    let avgEntranceFee: Double?
    let modeCrowdLevel: String?
    let bestTimes: [String]
    let bestSeasons: [String]
    let modePermitRequired: Bool?
    let modeDroneAllowed: Bool?
    let modeTripodAllowed: Bool?
    let recentGearRecommendations: [String]
    let recentCompositionHints: [String]

    // MARK: Derived

    var locality: String {
        [city, adminArea].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// Locality subtitle, e.g. "Cascade Range, WA".
    var subtitle: String { locality }

    var shootingTimes: [TimeOfDay] {
        bestTimes.compactMap(TimeOfDay.init(raw:))
    }

    var seasons: [Season] {
        bestSeasons.compactMap(Season.init(raw:))
    }

    /// Average entrance fee for the Quick Facts pill: "—" when unknown, "Free"
    /// when 0, otherwise a dollar amount.
    var entranceFeeText: String {
        guard let fee = avgEntranceFee else { return "—" }
        return fee == 0 ? "Free" : String(format: "$%.2f", fee)
    }

    var heroPhotos: [URL] {
        recentReviewPhotos.compactMap(\.photoUrl)
    }

    var hasLogistics: Bool {
        modePermitRequired != nil || modeDroneAllowed != nil || modeTripodAllowed != nil
    }

    var hasGearOrComposition: Bool {
        !recentGearRecommendations.isEmpty || !recentCompositionHints.isEmpty
    }
}

// MARK: - Sample data

nonisolated extension SpotDetail {
    static let sample = SpotDetail(
        id: "1",
        name: "The Emerald Basin",
        publicLat: 47.62,
        publicLng: -121.42,
        city: "Cascade Range",
        adminArea: "WA",
        country: "USA",
        createdAt: Date().addingTimeInterval(-90 * 86400),
        reviewCount: 128,
        avgRating: 4.9,
        recentReviewPhotos: [
            RecentReviewPhoto(reviewId: "r1",
                              photoUrl: URL(string: "https://picsum.photos/seed/emerald-1/1000/700"),
                              createdAt: Date()),
            RecentReviewPhoto(reviewId: "r2",
                              photoUrl: URL(string: "https://picsum.photos/seed/emerald-2/1000/700"),
                              createdAt: Date()),
            RecentReviewPhoto(reviewId: "r3",
                              photoUrl: URL(string: "https://picsum.photos/seed/emerald-3/1000/700"),
                              createdAt: Date())
        ],
        modeAccessLevel: "Moderate",
        avgEntranceFee: 0,
        modeCrowdLevel: "Moderate",
        bestTimes: ["GoldenHour", "BlueHour", "Sunrise"],
        bestSeasons: ["Spring", "Fall"],
        modePermitRequired: false,
        modeDroneAllowed: false,
        modeTripodAllowed: true,
        recentGearRecommendations: [
            "Wide-angle lens (16-35mm) for expansive basin views.",
            "ND filters (6-stop or 10-stop) for smooth water reflections."
        ],
        recentCompositionHints: [
            "Use the jagged rocks in the foreground for depth.",
            "Aim for perfect symmetry with the mountain reflection during still mornings."
        ]
    )
}
