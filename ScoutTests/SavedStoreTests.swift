import Testing
import Foundation
@testable import Scout

/// Covers `SavedStore`: hydrating lists + memberships from one snapshot, the
/// derived saved/membership lookups, membership commits, and local list edits
/// (with Favorites protection).
@MainActor
struct SavedStoreTests {

    private func loadedStore() async -> SavedStore {
        let store = SavedStore(service: MockSavedListService(delay: .zero))
        await store.load()
        return store
    }

    @Test func loadHydratesListsAndMemberships() async {
        let store = await loadedStore()
        #expect(store.state == .loaded)
        #expect(store.lists.map(\.name).contains("Favorites"))
        #expect(!store.memberships.isEmpty)
    }

    @Test func isSavedAndListIDsDeriveFromMemberships() async {
        let store = await loadedStore()
        // From MockSavedListService.sampleMemberships: favorites → first 3 spots.
        let favSpot = SpotSummary.samples[0].id
        #expect(store.isSaved(favSpot))
        #expect(store.listIDs(containingSpot: favSpot).contains("favorites"))

        let unsaved = "not-in-any-list"
        #expect(!store.isSaved(unsaved))
        #expect(store.listIDs(containingSpot: unsaved).isEmpty)
    }

    @Test func setMembershipReplacesFromSnapshot() async throws {
        let store = await loadedStore()
        let spot = SpotSummary.samples[4].id  // not in the sample memberships
        #expect(!store.isSaved(spot))

        try await store.setMembership(spotID: spot, listIDs: ["favorites"])
        #expect(store.isSaved(spot))
        #expect(store.listIDs(containingSpot: spot) == ["favorites"])
    }

    @Test func loadSurfacesFailures() async {
        let store = SavedStore(service: FailingSnapshotService())
        await store.load()
        #expect(store.state == .failed("boom"))
        #expect(store.lists.isEmpty)
    }

    @Test func createListAppendsWithEmptyMembership() async throws {
        let store = await loadedStore()
        let before = store.lists.count
        try await store.createList(name: "Weekend", description: "")
        #expect(store.lists.count == before + 1)
        let created = store.lists.last!
        #expect(store.memberships[created.id] == [])
    }

    @Test func deleteRemovesListAndMembership() async throws {
        let store = await loadedStore()
        let target = store.lists.first { $0.name == "my hikes" }!
        try await store.deleteList(id: target.id)
        #expect(!store.lists.contains { $0.id == target.id })
        #expect(store.memberships[target.id] == nil)
    }

    @Test func favoritesIsProtected() async throws {
        let store = await loadedStore()
        #expect(store.lists.first { $0.name == "Favorites" }?.isSystem == true)
        try await store.updateList(id: "favorites", name: "Renamed", description: "")
        try await store.deleteList(id: "favorites")
        #expect(store.lists.contains { $0.id == "favorites" && $0.name == "Favorites" })
    }

    @Test func decodesSnapshotFromBackendJSON() throws {
        let json = Data("""
        {
          "lists": [
            { "id": "abc", "name": "Coast", "description": null, "spot_count": 1,
              "cover_photo_url": null, "created_at": "2024-01-02T03:04:05Z",
              "updated_at": "2024-01-02T03:04:05Z", "is_system": false }
          ],
          "memberships": { "abc": ["spot-1"], "def": [] }
        }
        """.utf8)
        let snapshot = try JSONDecoder.scout.decode(ListsSnapshot.self, from: json)
        #expect(snapshot.lists.first?.id == "abc")
        #expect(snapshot.memberships["abc"] == ["spot-1"])
        #expect(snapshot.memberships["def"] == [])
    }
}

private struct FailingSnapshotService: SavedListService {
    struct Boom: Error, LocalizedError { var errorDescription: String? { "boom" } }
    func fetchSnapshot() async throws -> ListsSnapshot { throw Boom() }
    func setSpotMembership(spotID: String, listIDs: [String]) async throws -> ListsSnapshot { throw Boom() }
    func fetchListSpots(listID: String, limit: Int, cursor: String?) async throws -> PaginatedSpots { throw Boom() }
    func createList(name: String, description: String?) async throws -> SavedList { throw Boom() }
    func updateList(id: String, name: String?, description: String?) async throws -> SavedList { throw Boom() }
    func deleteList(id: String) async throws { throw Boom() }
}
