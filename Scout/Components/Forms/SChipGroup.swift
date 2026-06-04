import SwiftUI

/// Multi-select chip group backed by a `Set`. Tapping a chip toggles membership.
/// Built on `SFilterChip` + `FlowLayout`; reusable anywhere a "pick any" set of
/// pills is needed (filter sheet, review-post form, …).
struct SMultiChipGroup<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Set<Option>
    /// When true, at least one option must stay selected — tapping the last
    /// remaining chip is a no-op. You can still switch freely; you just can't
    /// clear the set to empty. Off by default (optional, like a filter).
    var requiresSelection: Bool = false
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
            // Keep at least one selected when this group is required.
            guard !(requiresSelection && selection.count == 1) else { return }
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
    /// Whether to show the leading "Any" chip that clears the selection. Off for
    /// required fields that must always have exactly one option selected.
    var includeAnyChip: Bool = true
    /// Whether tapping the active chip clears the selection back to `nil`. Off for
    /// required fields.
    var allowsDeselect: Bool = true
    var titleFont: Font = .sHeadingS
    var label: (Option) -> String

    var body: some View {
        SSection(title: title, titleFont: titleFont) {
            FlowLayout(spacing: Spacing.sm) {
                if includeAnyChip {
                    SFilterChip(title: anyTitle, isSelected: selection == nil) {
                        selection = nil
                    }
                }
                ForEach(options, id: \.self) { option in
                    SFilterChip(title: label(option), isSelected: selection == option) {
                        selection = allowsDeselect ? (selection == option ? nil : option) : option
                    }
                }
            }
        }
    }
}

extension SSingleChipGroup {
    /// Required single-select: exactly one option is always selected — no "Any"
    /// chip, no deselect. Bridges a non-optional binding to the internal optional
    /// one (ignoring `nil` writes), so form fields like Access Level can reuse the
    /// shared component instead of a hand-rolled chip row.
    init(title: String,
         options: [Option],
         selection: Binding<Option>,
         titleFont: Font = .sHeadingS,
         label: @escaping (Option) -> String) {
        self.title = title
        self.options = options
        self._selection = Binding(
            get: { selection.wrappedValue },
            set: { if let new = $0 { selection.wrappedValue = new } }
        )
        self.includeAnyChip = false
        self.allowsDeselect = false
        self.titleFont = titleFont
        self.label = label
    }
}
