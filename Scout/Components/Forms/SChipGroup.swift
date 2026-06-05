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

enum SSingleChipStyle {
    /// Form field where selection is optional. No "Any" chip, but allows deselecting to nil.
    case formOptional
    /// Form field where selection is strictly required. No "Any" chip, deselect is disabled.
    case formRequired
    /// Filter configuration. Includes a leading chip to clear the filter state.
    case filter(anyTitle: String = "Any")
}

/// Single-select chip group backed by an optional value.
struct SSingleChipGroup<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Option?
    
    var style: SSingleChipStyle = .formOptional
    var titleFont: Font = .sHeadingS
    var label: (Option) -> String

    // Helper properties to make the body clean
    private var includeAnyChip: Bool {
        if case .filter = style { return true }
        return false
    }
    
    private var anyTitle: String {
        if case .filter(let title) = style { return title }
        return "Any"
    }
    
    private var isRequired: Bool {
        if case .formRequired = style { return true }
        return false
    }

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
                        if selection == option {
                            if !isRequired { selection = nil }
                        } else {
                            selection = option
                        }
                    }
                }
            }
        }
    }
}

extension SSingleChipGroup {
    /// Convenience initializer for strictly required non-optional fields.
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
        self.style = .formRequired
        self.titleFont = titleFont
        self.label = label
    }
}
#Preview {
    PreviewContainer()
        .padding()
}

// MARK: - Mock Data Types
private enum Status: String, CaseIterable {
    case pending = "Pending"
    case active = "Active"
    case completed = "Completed"
}

private enum Diet: String, CaseIterable {
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case keto = "Keto"
}

private enum AccountType: String, CaseIterable {
    case personal = "Personal"
    case business = "Business"
}

private enum Interest: String, CaseIterable {
    case tech = "Technology"
    case design = "Design"
    case finance = "Finance"
    case health = "Health"
}

// MARK: - Preview Container View
private struct PreviewContainer: View {
    // Single Select States
    @State private var filterStatus: Status? = nil
    @State private var optionalDiet: Diet? = nil
    @State private var requiredAccount: AccountType = .personal // Non-optional!
    
    // Multi Select States
    @State private var optionalInterests: Set<Interest> = []
    @State private var requiredInterests: Set<Interest> = [.tech]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // ==========================================
                // SINGLE SELECT SCENARIOS
                // ==========================================
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Single Select Scenarios")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Divider()
                }
                
                // 1. Filter Style (With "Any" chip)
                SSingleChipGroup(
                    title: "Filter by Status (Filter Style)",
                    options: Status.allCases,
                    selection: $filterStatus,
                    style: .filter(anyTitle: "All Statuses"),
                    label: { $0.rawValue }
                )
                
                // 2. Form Optional Style (No "Any" chip, can deselect)
                SSingleChipGroup(
                    title: "Dietary Preference (Form Optional Style)",
                    options: Diet.allCases,
                    selection: $optionalDiet,
                    style: .formOptional,
                    label: { $0.rawValue }
                )
                
                // 3. Form Required Style (No "Any" chip, non-optional binding, cannot deselect)
                SSingleChipGroup(
                    title: "Account Type (Form Required - Non-Optional)",
                    options: AccountType.allCases,
                    selection: $requiredAccount, // Triggers extension init automatically
                    label: { $0.rawValue }
                )
                
                // ==========================================
                // MULTI SELECT SCENARIOS
                // ==========================================
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Multi Select Scenarios")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Divider()
                }
                
                // 4. Multi Select Optional
                SMultiChipGroup(
                    title: "Interests (Multi Select - Optional)",
                    options: Interest.allCases,
                    selection: $optionalInterests,
                    label: { $0.rawValue }
                )
                
                // 5. Multi Select Required (Cannot deselect the last remaining pill)
                SMultiChipGroup(
                    title: "Required Interests (Multi Select - Must keep 1+)",
                    options: Interest.allCases,
                    selection: $requiredInterests,
                    requiresSelection: true,
                    label: { $0.rawValue }
                )
            }
        }
    }
}
