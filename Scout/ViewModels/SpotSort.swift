nonisolated enum SpotSort: String, CaseIterable, Identifiable {
    case scout
    case mostPopular
    case highestRated
    case closest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .scout:        return "Scout Sort"
        case .mostPopular:  return "Most popular"
        case .highestRated: return "Highest rated"
        case .closest:      return "Closest"
        }
    }

    var icon: String {
        switch self {
        case .scout:        return "sparkles"
        case .mostPopular:  return "flame"
        case .highestRated: return "star.fill"
        case .closest:      return "ruler"
        }
    }

    func sorted(_ spots: [SpotSummary], distance: (SpotSummary) -> Double) -> [SpotSummary] {
        switch self {
        case .scout:
            return spots
        case .mostPopular:
            return spots.sorted { $0.reviewCount > $1.reviewCount }
        case .highestRated:
            return spots.sorted { $0.avgRating > $1.avgRating }
        case .closest:
            return spots.sorted { distance($0) < distance($1) }
        }
    }
}
