import Foundation

/// How a spot's reviews are ordered. Drives the shared `SSortSheet` and maps to
/// the backend's `sort` query value. Mirrors `SpotSort`'s shape (label + icon),
/// but the ordering itself happens server-side, so there's no client `sorted`.
nonisolated enum ReviewSort: String, CaseIterable, Identifiable {
    case scout
    case newest
    case highestRated
    case lowestRated

    var id: String { rawValue }

    var label: String {
        switch self {
        case .scout:        return "Scout Sort"
        case .newest:       return "Newest"
        case .highestRated: return "Highest rated"
        case .lowestRated:  return "Lowest rated"
        }
    }

    var icon: String {
        switch self {
        case .scout:        return "sparkles"
        case .newest:       return "clock"
        case .highestRated: return "star.fill"
        case .lowestRated:  return "star"
        }
    }

    /// The backend `sort` string (`ReviewSort` literal on the API).
    var apiValue: String {
        switch self {
        case .scout:        return "scout"
        case .newest:       return "newest"
        case .highestRated: return "highest_rated"
        case .lowestRated:  return "lowest_rated"
        }
    }
}
