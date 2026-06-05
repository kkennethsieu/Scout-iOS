import Foundation

/// User-tunable filters for the Explore feed.
///
/// Fields fall into two groups:
/// - **Backed by `SpotSummary`** (`times`, `minRating`, `minReviews`,
///   `permitNotRequired`, `droneAllowed`, `tripodAllowed`) — these actually
///   narrow the feed via `matches(_:)`.
/// - **Exploratory** (`maxMiles`) — surfaced in the sheet to gauge whether it's
///   worth keeping, but NOT present on the model yet, so it intentionally doesn't
///   filter anything. Promote it onto `SpotSummary` (and into `matches(_:)`) once
///   the backend exposes the data.
nonisolated struct SpotFilters: Equatable {
    // MARK: Backed by the model
    var times: Set<TimeOfDay> = []
    var minRating: Double? = nil
    var minReviews: Int? = nil
    var permitNotRequired = false
    var droneAllowed = false
    var tripodAllowed = false

    // MARK: Exploratory — UI only for now
    var maxMiles: Double? = nil

    // MARK: Option lists for the sheet
    static let ratingOptions: [Double] = [4.0, 4.5, 4.8]
    static let reviewOptions: [Int] = [10, 50, 100]
    static let distanceOptions: [Double] = [5, 10, 25, 50]

    /// True when any filter differs from the default (nothing selected).
    var isActive: Bool { self != SpotFilters() }

    /// Number of active filter groups — drives the badge on the filter button.
    var activeCount: Int {
        var n = 0
        if !times.isEmpty { n += 1 }
        if minRating != nil { n += 1 }
        if minReviews != nil { n += 1 }
        if permitNotRequired { n += 1 }
        if droneAllowed { n += 1 }
        if tripodAllowed { n += 1 }
        if maxMiles != nil { n += 1 }
        return n
    }

    /// Whether `spot` passes the model-backed filters. The exploratory `maxMiles`
    /// filter is intentionally ignored — no data yet.
    func matches(_ spot: SpotSummary) -> Bool {
        if !times.isEmpty, Set(spot.shootingTimes).isDisjoint(with: times) {
            return false
        }
        if let minRating, spot.avgRating < minRating { return false }
        if let minReviews, spot.reviewCount < minReviews { return false }
        if permitNotRequired, spot.modePermitRequired != false { return false }
        if droneAllowed, spot.modeDroneAllowed != true { return false }
        if tripodAllowed, spot.modeTripodAllowed != true { return false }
        return true
    }
}
