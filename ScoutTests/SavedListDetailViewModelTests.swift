import Testing
import Foundation
@testable import Scout

/// Covers `SavedListDetailViewModel` pagination and `SavedList` decoding.
@MainActor
struct SavedListDetailViewModelTests {

    @Test func loadPopulatesFirstPageAndFlagsMore() async {
        let vm = SavedListDetailViewModel(listID: "l1", service: twoPageService)
        await vm.load()
        #expect(vm.state == .loaded)
        #expect(vm.spots.map(\.id) == ["1", "2"])
        #expect(vm.hasMore)
    }

    @Test func loadMoreAppendsAndEnds() async {
        let vm = SavedListDetailViewModel(listID: "l1", service: twoPageService)
        await vm.load()
        await vm.loadMore()
        #expect(vm.spots.map(\.id) == ["1", "2", "3"])
        #expect(!vm.hasMore)
    }

    @Test func loadSurfacesFailures() async {
        let vm = SavedListDetailViewModel(listID: "l1", service: FailingSpotsService())
        await vm.load()
        #expect(vm.state == .failed("boom"))
        #expect(vm.spots.isEmpty)
    }

    @Test func decodesSavedListFromBackendJSON() throws {
        let json = Data("""
        {
          "id": "abc",
          "name": "Coast",
          "description": null,
          "spot_count": 3,
          "cover_photo_url": "https://example.com/y.jpg",
          "created_at": "2024-01-02T03:04:05Z",
          "updated_at": "2024-02-03T04:05:06Z",
          "is_system": true
        }
        """.utf8)

        let list = try JSONDecoder.scout.decode(SavedList.self, from: json)
        #expect(list.id == "abc")
        #expect(list.name == "Coast")
        #expect(list.description == nil)
        #expect(list.spotCount == 3)
        #expect(list.coverPhotoUrl?.absoluteString == "https://example.com/y.jpg")
        #expect(list.isSystem == true)
        #expect(list.spotCountLabel == "3 spots")
    }

    // MARK: - Stubs

    private var twoPageService: TwoPageSpotsService {
        TwoPageSpotsService(
            page1: [.sample(id: "1"), .sample(id: "2")],
            page2: [.sample(id: "3")]
        )
    }
}

/// Returns two fixed pages: page one (cursor `nil`) hands back `"p2"`; page two ends.
private struct TwoPageSpotsService: SavedListService {
    let page1: [SpotSummary]
    let page2: [SpotSummary]
    func fetchSnapshot() async throws -> ListsSnapshot { ListsSnapshot(lists: [], memberships: [:]) }
    func setSpotMembership(spotID: String, listIDs: [String]) async throws -> ListsSnapshot {
        ListsSnapshot(lists: [], memberships: [:])
    }
    func fetchListSpots(listID: String, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        switch cursor {
        case nil: return PaginatedSpots(items: page1, limit: limit, nextCursor: "p2")
        default:  return PaginatedSpots(items: page2, limit: limit, nextCursor: nil)
        }
    }
    func createList(name: String, description: String?) async throws -> SavedList { SavedList.samples[0] }
    func updateList(id: String, name: String?, description: String?) async throws -> SavedList { SavedList.samples[0] }
    func deleteList(id: String) async throws {}
}

private struct FailingSpotsService: SavedListService {
    struct Boom: Error, LocalizedError { var errorDescription: String? { "boom" } }
    func fetchSnapshot() async throws -> ListsSnapshot { throw Boom() }
    func setSpotMembership(spotID: String, listIDs: [String]) async throws -> ListsSnapshot { throw Boom() }
    func fetchListSpots(listID: String, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        throw Boom()
    }
    func createList(name: String, description: String?) async throws -> SavedList { throw Boom() }
    func updateList(id: String, name: String?, description: String?) async throws -> SavedList { throw Boom() }
    func deleteList(id: String) async throws { throw Boom() }
}
