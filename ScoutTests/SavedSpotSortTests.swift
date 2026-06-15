import Testing
@testable import Scout

/// Covers `SavedSpotSort`'s pure ordering: Recently Added preserves the list's
/// added order; Name sorts alphabetically (case-insensitive).
struct SavedSpotSortTests {

    private let spots: [SpotSummary] = [
        .sample(id: "1", name: "Zephyr Ridge"),
        .sample(id: "2", name: "alpine Basin"),
        .sample(id: "3", name: "Mirror Lake")
    ]

    @Test func recentlyAddedPreservesOrder() {
        let result = SavedSpotSort.recentlyAdded.sorted(spots)
        #expect(result.map(\.id) == ["1", "2", "3"])
    }

    @Test func nameSortsAlphabeticallyCaseInsensitive() {
        let result = SavedSpotSort.name.sorted(spots)
        #expect(result.map(\.name) == ["alpine Basin", "Mirror Lake", "Zephyr Ridge"])
    }

    @Test func sortingEmptyIsEmpty() {
        #expect(SavedSpotSort.name.sorted([]).isEmpty)
        #expect(SavedSpotSort.recentlyAdded.sorted([]).isEmpty)
    }
}
