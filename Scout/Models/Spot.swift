import Foundation

/// A single review photo attached to a spot. Mirrors the backend
/// `RecentReviewPhoto` schema.
nonisolated struct RecentReviewPhoto: Identifiable, Decodable, Hashable {
    let reviewId: String
    let photoUrl: URL?
    let createdAt: Date

    var id: String { reviewId }
}

/// Lightweight spot used by list/feed endpoints. Mirrors the backend
/// `SpotSummaryResponse` schema (snake_case keys decoded via
/// `JSONDecoder.scout`).
///
/// Note: `recent_review_photos` is included so the Explore card can present a
/// swipeable photo carousel. The backend must NOT exclude this field for that
/// to work (its summary schema currently has `exclude=True` — drop it).
nonisolated struct SpotSummary: Identifiable, Decodable, Hashable {
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
    let coverPhotoUrl: URL?
    let recentReviewPhotos: [RecentReviewPhoto]
    let bestTimes: [String]
    let modePermitRequired: Bool?
    let modeDroneAllowed: Bool?
    let modeTripodAllowed: Bool?

    /// Photos for the card carousel: server cover first (deduped), then the
    /// recent review photos. Falls back to whatever is available.
    var carouselPhotos: [URL] {
        var urls: [URL] = []
        if let cover = coverPhotoUrl { urls.append(cover) }
        for photo in recentReviewPhotos {
            if let url = photo.photoUrl, !urls.contains(url) {
                urls.append(url)
            }
        }
        return urls
    }

    /// Single cover image (first carousel photo), for compact contexts.
    var coverPhoto: URL? { carouselPhotos.first }

    var shootingTimes: [TimeOfDay] { bestTimes.compactMap(TimeOfDay.init(raw:)) }
}

// MARK: - Sample data

nonisolated extension SpotSummary {
    static func sample(
        id: String = "sample-1",
        name: String = "Cedar Cathedral",
        rating: Double = 4.9,
        reviewCount: Int = 128,
        seed: String = "cedar"
    ) -> SpotSummary {
        SpotSummary(
            id: id,
            name: name,
            publicLat: 45.51,
            publicLng: -122.68,
            city: "Portland",
            adminArea: "Oregon",
            country: "USA",
            createdAt: Date(),
            reviewCount: reviewCount,
            avgRating: rating,
            coverPhotoUrl: URL(string: "https://picsum.photos/seed/\(seed)/800/500"),
            recentReviewPhotos: [
                RecentReviewPhoto(reviewId: "\(id)-p2",
                                  photoUrl: URL(string: "https://picsum.photos/seed/\(seed)-2/800/500"),
                                  createdAt: Date()),
                RecentReviewPhoto(reviewId: "\(id)-p3",
                                  photoUrl: URL(string: "https://picsum.photos/seed/\(seed)-3/800/500"),
                                  createdAt: Date())
            ],
            bestTimes: ["GoldenHour", "Sunrise"],
            modePermitRequired: false,
            modeDroneAllowed: false,
            modeTripodAllowed: true
        )
    }

    static let samples: [SpotSummary] = [
        .sample(id: "1", name: "Cedar Cathedral", rating: 4.9, reviewCount: 128, seed: "cedar"),
        .sample(id: "2", name: "Mirror Reservoir", rating: 4.7, reviewCount: 342, seed: "reservoir"),
        .sample(id: "3", name: "Golden Valley Point", rating: 4.8, reviewCount: 57, seed: "valley"),
        .sample(id: "4", name: "Basalt Overlook", rating: 4.6, reviewCount: 9, seed: "basalt"),
        .sample(id: "5", name: "Tidewater Cliffs", rating: 4.5, reviewCount: 211, seed: "tidewater")
    ]
}
