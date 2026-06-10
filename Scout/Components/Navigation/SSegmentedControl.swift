import SwiftUI

/// Underline-style segmented control. Generic over a `Hashable` option, mirroring
/// `SSingleChipGroup`'s API (options + binding + label closure). The active
/// segment is marked by an animated accent underline that slides between
/// segments. Reusable anywhere a "switch between N views" tab strip is needed
/// (Profile Photos/Reviews, future detail sub-tabs, …).
struct SSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    var label: (Option) -> String

    @Namespace private var underline
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    segment(option)
                }
            }
            Divider().background(Color.sBorderSubtle)
        }
    }

    private func segment(_ option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            select(option)
        } label: {
            VStack(spacing: Spacing.sm) {
                Text(label(option))
                    .font(.sHeadingM)
                    .foregroundStyle(isSelected ? Color.sTextPrimary : Color.sTextSecondary)
                    .frame(maxWidth: .infinity)

                // 2pt baseline; the accent strip is matched-geometry so it slides
                // to the active segment. A clear strip holds the layout otherwise.
                ZStack {
                    Color.clear.frame(height: 2)
                    if isSelected {
                        Color.sAccent
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "underline", in: underline)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label(option))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func select(_ option: Option) {
        guard option != selection else { return }
        if reduceMotion {
            selection = option
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { selection = option }
        }
    }
}

// MARK: - Preview

#Preview("SSegmentedControl") {
    struct Demo: View {
        enum Tab: String, CaseIterable { case photos = "Photos", reviews = "Reviews" }
        @State private var tab: Tab = .reviews
        var body: some View {
            VStack(spacing: Spacing.xl) {
                SSegmentedControl(options: Tab.allCases, selection: $tab) { $0.rawValue }
                Text("Selected: \(tab.rawValue)")
                    .font(.sBody)
                    .foregroundStyle(Color.sTextSecondary)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sBackground)
        }
    }
    return Demo()
}
