import SwiftUI

/// A reusable "choose a sort order" bottom sheet. Generic over any identifiable
/// option that can supply a label + SF Symbol. Tapping an option applies it
/// immediately and dismisses; swiping down cancels. Used by the Explore feed
/// (`SpotSort`) and the Saved list detail (`SavedSpotSort`).
struct SSortSheet<Option: Identifiable & Hashable>: View {
    var title: String = "Sort"
    let options: [Option]
    @Binding var selection: Option
    var label: (Option) -> String
    var icon: (Option) -> String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SSheetHeader(title: title) {
                dismiss()
            }

            VStack(spacing: Spacing.md) {
                ForEach(options) { option in
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

    private func optionRow(_ option: Option) -> some View {
        let isSelected = selection == option
        return Button {
            selection = option
            dismiss()
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon(option))
                    .font(.system(size: 18))
                    .foregroundStyle(Color.sTextPrimary)
                    .frame(width: 28)
                Text(label(option))
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
