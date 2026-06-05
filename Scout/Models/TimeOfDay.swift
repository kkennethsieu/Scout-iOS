import Foundation
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
