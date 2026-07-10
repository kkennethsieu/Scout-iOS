import SwiftUI
import MapKit

/// Search field that jumps a map camera to a place. Reused by any map surface:
/// wraps the shared `SSearchBar` plus a live suggestions dropdown (MapKit place
/// autocomplete via `PlaceSearch`), and hands the resolved place back through
/// `onSelect` — the parent decides how to move its own camera.
///
/// Scope matches the Explore/Search tab: cities, regions, and countries only.
///
/// The Create map passes its photo thumbnail as the `trailing` accessory; the Map
/// tab omits it (defaults to nothing).
struct PlaceSearchField<Trailing: View>: View {
    var placeholder: String = "Search for a place"
    /// Biases suggestion relevance toward this coordinate (nearest same-named
    /// place first). Usually the device location.
    var bias: CLLocationCoordinate2D?
    /// Called with the resolved place after the user taps a suggestion.
    var onSelect: (ResolvedPlace) -> Void
    /// Optional accessory shown to the right of the field (e.g. a photo thumbnail).
    @ViewBuilder var trailing: () -> Trailing

    @State private var search = PlaceSearch()
    @State private var query = ""
    @State private var isResolving = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                SSearchBar(text: $query,
                           placeholder: placeholder,
                           showsFilter: false,
                           showsClearButton: true,
                           focus: $focused)

                trailing()
            }

            if !search.completions.isEmpty {
                resultsCard
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.25), value: search.completions.isEmpty)
        .disabled(isResolving)
        .onChange(of: query) { _, newValue in
            search.updateQuery(newValue)
        }
        .onChange(of: bias?.latitude) { _, _ in applyBias() }
        .onChange(of: bias?.longitude) { _, _ in applyBias() }
        .onAppear(perform: applyBias)
    }

    // MARK: - Results

    private var resultsCard: some View {
        VStack(spacing: 0) {
            ForEach(search.completions, id: \.self) { completion in
                Button {
                    select(completion)
                } label: {
                    PlaceResultRow(completion: completion)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.sSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.sBorderDefault, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func applyBias() {
        if let bias { search.bias(around: bias) }
    }

    /// Resolves the tapped suggestion to a place, clears the field + keyboard, and
    /// hands it to the parent to move its camera.
    private func select(_ completion: MKLocalSearchCompletion) {
        guard !isResolving else { return }
        isResolving = true
        focused = false
        Task {
            defer { isResolving = false }
            guard let place = try? await search.resolve(completion) else { return }
            query = ""            // clears the field + dismisses the dropdown
            onSelect(place)
        }
    }
}

// MARK: - Trailing-less convenience

extension PlaceSearchField where Trailing == EmptyView {
    init(placeholder: String = "Search for a place",
         bias: CLLocationCoordinate2D?,
         onSelect: @escaping (ResolvedPlace) -> Void) {
        self.init(placeholder: placeholder,
                  bias: bias,
                  onSelect: onSelect,
                  trailing: { EmptyView() })
    }
}
