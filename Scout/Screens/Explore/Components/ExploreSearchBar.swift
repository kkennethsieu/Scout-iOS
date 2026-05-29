import SwiftUI

/// Pill search field with a trailing filter button, for the top of Explore.
struct ExploreSearchBar: View {
    @Binding var text: String
    var onTapFilter: () -> Void = {}

    var body: some View {
        HStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.sTextSecondary)

                TextField("Search destinations...", text: $text)
                    .font(.sBodyL)
                    .foregroundStyle(Color.sTextPrimary)
                    .tint(Color.sAccent)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.pill)
                    .fill(Color.sSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.pill)
                    .stroke(Color.sBorderDefault, lineWidth: 1)
            )

            Button(action: onTapFilter) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.sTextPrimary)
                    .frame(width: 44, height: 44)
            }
        }
    }
}
