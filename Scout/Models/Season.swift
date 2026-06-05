import Foundation

/// Canonical shooting-season buckets with display label + SF Symbol. Raw values
/// match the backend `Season` literals exactly (PascalCase). Parallels
/// `TimeOfDay` (in `Review.swift`) — `best_season` is list-shaped just like
/// `best_time_of_day`.
nonisolated enum Season: String, CaseIterable, Hashable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    case yearRound = "YearRound"

    /// Tolerant parse: matches the canonical PascalCase value but also accepts
    /// snake_case / spaced / lower-case variants ("year_round", "Year Round").
    init?(raw: String) {
        if let exact = Season(rawValue: raw) {
            self = exact
            return
        }
        let key = raw.lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
        switch key {
        case "spring":    self = .spring
        case "summer":    self = .summer
        case "fall", "autumn": self = .fall
        case "winter":    self = .winter
        case "yearround": self = .yearRound
        default:          return nil
        }
    }

    var label: String {
        switch self {
        case .spring:    return "Spring"
        case .summer:    return "Summer"
        case .fall:      return "Fall"
        case .winter:    return "Winter"
        case .yearRound: return "Year-Round"
        }
    }

    var icon: String {
        switch self {
        case .spring:    return "leaf"
        case .summer:    return "sun.max"
        case .fall:      return "wind"
        case .winter:    return "snowflake"
        case .yearRound: return "calendar"
        }
    }
}
