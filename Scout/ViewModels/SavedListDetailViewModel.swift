import SwiftUI

/// Loads a single saved list's spots from the backend, cursor-paginated, newest
/// first. Mirrors `ExploreViewModel`'s load/loadMore shape.
@Observable
@MainActor
final class SavedListDetailViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var spots: [SpotSummary] = []
    private(set) var state: LoadState = .idle
    private(set) var hasMore = false
    private(set) var isLoadingMore = false

    let listID: String
    private let service: SavedListService
    private let pageSize = 30
    private var cursor: String?

    init(listID: String, service: SavedListService = AppServices.savedLists) {
        self.listID = listID
        self.service = service
    }

    func load() async {
        state = .loading
        cursor = nil
        do {
            let page = try await service.fetchListSpots(listID: listID, limit: pageSize, cursor: nil)
            spots = page.items
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func loadMore() async {
        guard state == .loaded, hasMore, !isLoadingMore, let cursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.fetchListSpots(listID: listID, limit: pageSize, cursor: cursor)
            spots.append(contentsOf: page.items)
            self.cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            // Keep what's loaded; a later scroll trigger will retry this page.
        }
    }
}
