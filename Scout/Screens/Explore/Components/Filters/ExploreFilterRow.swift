import SwiftUI

/// Horizontally scrolling row of category filter chips.
struct ExploreFilterRow: View {
    let filters: [String]
    let selected: String
    var onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(filters, id: \.self) { filter in
                    SFilterChip(title: filter, isSelected: selected == filter) {
                        onSelect(filter)
                    }
                }
            }
        }
        .scrollClipDisabled()
    }
}
