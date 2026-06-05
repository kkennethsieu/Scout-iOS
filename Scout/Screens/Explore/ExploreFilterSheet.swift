import SwiftUI

/// Bottom sheet for narrowing the Explore feed. Edits a local `draft` so the
/// user can cancel by swiping down; changes only commit on "Show results".
///
/// The controls are shared primitives (`SSection`, `SMultiChipGroup`,
/// `SSingleChipGroup`) plus the local `FilterToggleRow`; this view just composes
/// them and owns the header/footer chrome.
struct ExploreFilterSheet: View {
    @Binding var filters: SpotFilters
    /// Live count of spots matching a candidate filter set (search included).
    var resultCount: (SpotFilters) -> Int

    @Environment(\.dismiss) private var dismiss
    @State private var draft: SpotFilters

    init(filters: Binding<SpotFilters>, resultCount: @escaping (SpotFilters) -> Int) {
        _filters = filters
        self.resultCount = resultCount
        _draft = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            SSheetHeader(title: "Filters"){
                dismiss()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    SMultiChipGroup(
                        title: "Best time of day",
                        options: TimeOfDay.allCases,
                        selection: $draft.times
                    ) { $0.label }

                    SSingleChipGroup(
                        title: "Minimum rating",
                        options: SpotFilters.ratingOptions,
                        selection: $draft.minRating
                    ) { "\($0.formatted(.number.precision(.fractionLength(1))))★ +" }

                    SSingleChipGroup(
                        title: "Minimum reviews",
                        options: SpotFilters.reviewOptions,
                        selection: $draft.minReviews
                    ) { "\($0)+" }

                    SSection(title: "Logistics", titleFont: .sHeadingS) {
                        VStack(spacing: Spacing.xs) {
                            FilterToggleRow(title: "No permit required", icon: "doc.text", isOn: $draft.permitNotRequired)
                            FilterToggleRow(title: "Drone allowed", icon: "airplane", isOn: $draft.droneAllowed)
                            FilterToggleRow(title: "Tripod allowed", icon: "camera", isOn: $draft.tripodAllowed)
                        }
                    }

                    SSingleChipGroup(
                        title: "Distance",
                        options: SpotFilters.distanceOptions,
                        selection: $draft.maxMiles
                    ) { "Within \($0.formatted(.number.precision(.fractionLength(0)))) mi" }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }

            footer
        }
        .background(Color.sBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.xl)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: Spacing.md) {
                Button("Reset") {
                    withAnimation(.easeOut(duration: 0.15)) { draft = SpotFilters() }
                }
                .font(.sBody)
                .foregroundStyle(draft.isActive ? Color.sAccent : Color.sTextTertiary)
                .disabled(!draft.isActive)

                Spacer()

                SPrimaryButton(title: footerTitle) {
                    filters = draft
                    dismiss()
                }
                .disabled(resultCount(draft) == 0)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
        }
        .background(.ultraThinMaterial)
    }

    private var footerTitle: String {
        switch resultCount(draft) {
        case 0:  return "No matching spots"
        case 1:  return "Show 1 spot"
        case let n: return "Show \(n) spots"
        }
    }
}

// MARK: - Preview

#Preview("Filter Sheet") {
    struct Harness: View {
        @State private var filters = SpotFilters()
        var body: some View {
            Color.sBackground
                .sheet(isPresented: .constant(true)) {
                    ExploreFilterSheet(filters: $filters) { _ in 42 }
                }
        }
    }
    return Harness()
}
