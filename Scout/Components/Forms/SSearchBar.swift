import SwiftUI

/// Pill search field with an optional trailing filter button. Shared across the
/// app — Explore (with the filter button + active count) and the Map tab
/// (without). Pass `placeholder` to fit the context.
struct SSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search destinations..."
    var showsFilter: Bool = true
    var activeFilterCount: Int = 0
    var onTapFilter: () -> Void = {}

    var body: some View {
        HStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.sTextSecondary)

                TextField(placeholder, text: $text)
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

            if showsFilter {
                Button(action: onTapFilter) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.sTextPrimary)
                        .frame(width: 44, height: 44)
                        .overlay(alignment: .topTrailing) {
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.sCaption)
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(Circle().fill(Color.sAccent))
                                    .offset(x: -2, y: 4)
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Search Bar") {
    struct Harness: View {
        @State private var text = ""
        var body: some View {
            VStack(spacing: Spacing.lg) {
                SSearchBar(text: $text, activeFilterCount: 2) {}
                SSearchBar(text: $text, placeholder: "Map area", showsFilter: false)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sBackground)
        }
    }
    return Harness()
}
