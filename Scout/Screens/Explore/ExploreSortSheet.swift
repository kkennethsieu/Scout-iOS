import SwiftUI

/// Bottom sheet for choosing how the Explore feed is ordered. Thin wrapper over
/// the shared `SSortSheet`, binding it to `SpotSort`.
struct ExploreSortSheet: View {
    @Binding var selection: SpotSort

    var body: some View {
        SSortSheet(
            options: SpotSort.allCases,
            selection: $selection,
            label: \.label,
            icon: \.icon
        )
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
