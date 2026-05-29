import SwiftUI

/// Bottom sheet for choosing how the Explore feed is ordered. Tapping an option
/// applies it immediately and dismisses; swiping down cancels.
struct ExploreSortSheet: View {
    @Binding var selection: SpotSort
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SSheetHeader(title: "Sort") {
                dismiss()
            }

            VStack(spacing: Spacing.md) {
                ForEach(SpotSort.allCases) { option in
                    optionRow(option)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.xl)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func optionRow(_ option: SpotSort) -> some View {
        let isSelected = selection == option
        return Button {
            selection = option
            dismiss()
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: option.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.sTextPrimary)
                    .frame(width: 28)
                Text(option.label)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: 60)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(Color.sSurface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(isSelected ? Color.sAccent : Color.sBorderDefault,
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Sort Sheet") {
    struct Harness: View {
        @State private var sort: SpotSort = .scout
        var body: some View {
            Color.sBackground
                .sheet(isPresented: .constant(true)) {
                    ExploreSortSheet(selection: $sort)
                }
        }
    }
    return Harness()
}
