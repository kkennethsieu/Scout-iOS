import Foundation

/// How a saved list's spots are ordered. Mirrors `SpotSort`'s shape (label +
/// icon + pure `sorted`) so it can drive the shared `SSortSheet`.
nonisolated enum SavedSpotSort: String, CaseIterable, Identifiable {
    case recentlyAdded
    case name

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recentlyAdded: return "Recently Added"
        case .name:          return "Name"
        }
    }

    var icon: String {
        switch self {
        case .recentlyAdded: return "clock"
        case .name:          return "textformat"
        }
    }

    /// `spots` is stored most-recently-added first, so Recently Added is the
    /// identity order; Name sorts alphabetically (case/diacritic-insensitive).
    func sorted(_ spots: [SpotSummary]) -> [SpotSummary] {
        switch self {
        case .recentlyAdded:
            return spots
        case .name:
            return spots.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }
}
