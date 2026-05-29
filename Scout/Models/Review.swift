import Foundation

/// A single user review. Mirrors the backend `ReviewResponse` schema.
nonisolated struct Review: Identifiable, Decodable, Hashable {
    let id: String
    let spotId: String
    let userId: String
    let photoUrls: [URL]
    let overallRating: Int
    let notes: String
    let bestTimeOfDay: [String]
    let accessLevel: String
    let entranceFee: String
    let crowdLevel: String
    let environment: String
    let gearRecommendations: String?
    let compositionHints: String?
    let permitRequired: Bool
    let droneAllowed: Bool
    let tripodAllowed: Bool
    let createdAt: Date

    /// Time-of-day values resolved to display models (unknown values dropped).
    var times: [TimeOfDay] { bestTimeOfDay.compactMap(TimeOfDay.init(raw:)) }
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

// MARK: - Time of day

/// Canonical shooting-time buckets with display label + SF Symbol. Raw values
/// match the backend `BestTimeOfDay` literals exactly (PascalCase).
nonisolated enum TimeOfDay: String, CaseIterable, Hashable {
    case sunrise = "Sunrise"
    case goldenHour = "GoldenHour"
    case blueHour = "BlueHour"
    case midday = "Midday"
    case night = "Night"

    /// Tolerant parse: matches the canonical PascalCase value but also accepts
    /// snake_case / spaced / lower-case variants ("golden_hour", "Golden Hour").
    init?(raw: String) {
        if let exact = TimeOfDay(rawValue: raw) {
            self = exact
            return
        }
        let key = raw.lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
        switch key {
        case "sunrise":    self = .sunrise
        case "goldenhour": self = .goldenHour
        case "bluehour":   self = .blueHour
        case "midday":     self = .midday
        case "night":      self = .night
        default:           return nil
        }
    }

    var label: String {
        switch self {
        case .sunrise:    return "Sunrise"
        case .goldenHour: return "Golden Hour"
        case .blueHour:   return "Blue Hour"
        case .midday:     return "Midday"
        case .night:      return "Night"
        }
    }

    var icon: String {
        switch self {
        case .sunrise:    return "sunrise"
        case .goldenHour: return "sun.max"
        case .blueHour:   return "moon.haze"
        case .midday:     return "sun.max.fill"
        case .night:      return "moon.stars"
        }
    }
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
            accessLevel: "Moderate",
            entranceFee: "Free",
            crowdLevel: "Moderate",
            environment: "Mountain",
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
            accessLevel: "Difficult",
            entranceFee: "Free",
            crowdLevel: "Light",
            environment: "Mountain",
            gearRecommendations: nil,
            compositionHints: nil,
            permitRequired: false,
            droneAllowed: false,
            tripodAllowed: true,
            createdAt: Date().addingTimeInterval(-26 * 3600)
        )
    ]
}
