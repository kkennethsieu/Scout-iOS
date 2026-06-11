import SwiftUI

/// Pill search field with an optional trailing filter button. Shared across the
/// app — Explore (with the filter button + active count) and the Map tab
/// (without). Pass `placeholder` to fit the context.
///
/// Two presentations from one component:
/// - **Editable** (default): a live `TextField`. Set `autoFocus` to open with the
///   keyboard up; set `showsClearButton` to add a trailing clear (×) when filled.
/// - **Tap-to-navigate**: pass `onTap` to render the field read-only — the whole
///   pill becomes a button (Explore uses this to push the SearchScreen instead of
///   editing inline).
///
/// Set `showsBackButton` to swap the leading magnifying glass for a back chevron
/// (the active SearchScreen header).
struct SSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search destinations..."
    var showsFilter: Bool = true
    var activeFilterCount: Int = 0
    var onTapFilter: () -> Void = {}

    /// When set, the field is read-only and the whole pill is a button calling this.
    var onTap: (() -> Void)? = nil
    /// Swaps the leading magnifying glass for a back chevron button.
    var showsBackButton: Bool = false
    var onBack: () -> Void = {}
    /// Shows a trailing clear (×) button while `text` is non-empty.
    var showsClearButton: Bool = false
    /// Focuses the field when the bar appears (editable mode only).
    var autoFocus: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            field

            if showsFilter {
                filterButton
            }
        }
    }

    // MARK: - Field

    private var field: some View {
        HStack(spacing: Spacing.sm) {
            leading

            content

            if showsClearButton, !text.isEmpty {
                Button {
                    text = ""
                    isFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.sTextTertiary)
                }
                .buttonStyle(.plain)
            }
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
        // In read-only mode the whole pill is the tap target.
        .contentShape(Rectangle())
        .modifier(TapToNavigate(onTap: onTap))
    }

    @ViewBuilder
    private var leading: some View {
        if showsBackButton {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.sTextPrimary)
            }
            .buttonStyle(.plain)
        } else {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17))
                .foregroundStyle(Color.sTextSecondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        if onTap != nil {
            // Read-only: show the value if present, otherwise the placeholder.
            Text(text.isEmpty ? placeholder : text)
                .font(.sBodyL)
                .foregroundStyle(text.isEmpty ? Color.sTextSecondary : Color.sTextPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            TextField(placeholder, text: $text)
                .font(.sBodyL)
                .foregroundStyle(Color.sTextPrimary)
                .tint(Color.sAccent)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .onAppear { if autoFocus { isFocused = true } }
        }
    }

    private var filterButton: some View {
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

/// Wraps the pill in a `Button` only when an `onTap` is supplied, so the editable
/// presentation keeps its native `TextField` interaction.
private struct TapToNavigate: ViewModifier {
    let onTap: (() -> Void)?

    func body(content: Content) -> some View {
        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview("Search Bar") {
    struct Harness: View {
        @State private var text = ""
        @State private var active = "Yosemite"
        var body: some View {
            VStack(spacing: Spacing.lg) {
                SSearchBar(text: $text, activeFilterCount: 2) {}
                SSearchBar(text: $text, placeholder: "Map area", showsFilter: false)
                SSearchBar(text: .constant(""),
                           placeholder: "Search destinations...",
                           showsFilter: false,
                           onTap: {})
                SSearchBar(text: $active,
                           showsFilter: false,
                           showsBackButton: true,
                           showsClearButton: true)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sBackground)
        }
    }
    return Harness()
}
