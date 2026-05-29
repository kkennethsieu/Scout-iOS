import SwiftUI

/// Multi-select chip group backed by a `Set`. Tapping a chip toggles membership.
/// Built on `SFilterChip` + `FlowLayout`; reusable anywhere a "pick any" set of
/// pills is needed (filter sheet, review-post form, …).
struct SMultiChipGroup<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Set<Option>
    var titleFont: Font = .sHeadingS
    var label: (Option) -> String

    var body: some View {
        SSection(title: title, titleFont: titleFont) {
            FlowLayout(spacing: Spacing.sm) {
                ForEach(options, id: \.self) { option in
                    SFilterChip(title: label(option), isSelected: selection.contains(option)) {
                        toggle(option)
                    }
                }
            }
        }
    }

    private func toggle(_ option: Option) {
        if selection.contains(option) {
            selection.remove(option)
        } else {
            selection.insert(option)
        }
    }
}

/// Single-select chip group backed by an optional value, prefixed with an "Any"
/// chip that clears the selection. Tapping the active chip also clears it.
struct SSingleChipGroup<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Option?
    var anyTitle: String = "Any"
    var titleFont: Font = .sHeadingS
    var label: (Option) -> String

    var body: some View {
        SSection(title: title, titleFont: titleFont) {
            FlowLayout(spacing: Spacing.sm) {
                SFilterChip(title: anyTitle, isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(options, id: \.self) { option in
                    SFilterChip(title: label(option), isSelected: selection == option) {
                        selection = selection == option ? nil : option
                    }
                }
            }
        }
    }
}
