import SwiftUI

/// Single-select tristate control bound to `Bool?`: **Yes** (`true`), **No**
/// (`false`), or **Unknown** (`nil`). Used where "not answered" is a distinct
/// answer from "No" — e.g. the review form's permit / drone / tripod logistics,
/// which the backend stores as tristate `Optional[bool]`.
struct SYesNoUnknownPicker: View {
    @Binding var value: Bool?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            pill("Yes", isSelected: value == true, selectedColor: .sSuccess) { value = true }
            pill("No", isSelected: value == false, selectedColor: .sError) { value = false }
            pill("Unknown", isSelected: value == nil, selectedColor: .sTextSecondary) { value = nil }
        }
        .sensoryFeedback(.selection, trigger: value)
    }

    private func pill(
        _ title: String,
        isSelected: Bool,
        selectedColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sHeadingS)
                .foregroundStyle(isSelected ? .white : Color.sTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .fill(isSelected ? selectedColor : Color.sSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .stroke(Color.sBorderDefault, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview("SYesNoUnknownPicker") {
    struct Demo: View {
        @State private var permit: Bool? = nil
        @State private var drone: Bool? = true
        @State private var tripod: Bool? = false
        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SYesNoUnknownPicker(value: $permit)
                SYesNoUnknownPicker(value: $drone)
                SYesNoUnknownPicker(value: $tripod)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sBackground)
        }
    }
    return Demo()
}
