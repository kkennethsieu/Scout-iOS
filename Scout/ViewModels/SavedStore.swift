import SwiftUI

/// App-wide source of truth for the user's saved lists and spot→list membership.
/// Hydrated once at launch from a single `ListsSnapshot` and replaced wholesale
/// after every membership edit, so the bookmark (spot in *any* list) and the
/// "Save to a list" checkboxes (lists containing the spot) are cheap derivations
/// that never drift. Injected via `.environment` from `MainTabView`.
@Observable
@MainActor
final class SavedStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var lists: [SavedList] = []
    /// list id → spot ids in that list.
    private(set) var memberships: [String: Set<String>] = [:]
    private(set) var state: LoadState = .idle

    private let service: SavedListService

    init(service: SavedListService = AppServices.savedLists) {
        self.service = service
    }

    // MARK: - Derivations

    /// True when the spot is in at least one list.
    func isSaved(_ spotID: String) -> Bool {
        memberships.values.contains { $0.contains(spotID) }
    }

    /// The ids of the lists that currently contain the spot.
    func listIDs(containingSpot spotID: String) -> Set<String> {
        var result: Set<String> = []
        for (listID, spotIDs) in memberships where spotIDs.contains(spotID) {
            result.insert(listID)
        }
        return result
    }

    // MARK: - Loading

    func load() async {
        state = .loading
        await hydrate()
    }

    /// Silent re-fetch (pull-to-refresh / returning to the tab): no loading flash,
    /// and a failure keeps the data already on screen.
    func refresh() async {
        await hydrate()
    }

    private func hydrate() async {
        do {
            apply(try await service.fetchSnapshot())
            state = .loaded
        } catch {
            if lists.isEmpty { state = .failed(error.localizedDescription) }
        }
    }

    private func apply(_ snapshot: ListsSnapshot) {
        lists = snapshot.lists
        memberships = snapshot.memberships.mapValues(Set.init)
    }

    // MARK: - Membership

    /// Sets the exact set of lists the spot belongs to, then replaces local state
    /// from the returned snapshot.
    func setMembership(spotID: String, listIDs: [String]) async throws {
        apply(try await service.setSpotMembership(spotID: spotID, listIDs: listIDs))
    }

    // MARK: - List mutations

    func createList(name: String, description: String) async throws {
        let created = try await service.createList(
            name: name,
            description: description.isEmpty ? nil : description
        )
        lists.append(created)
        memberships[created.id] = []
    }

    func updateList(id: String, name: String, description: String) async throws {
        guard let index = lists.firstIndex(where: { $0.id == id }),
              !lists[index].isSystem else { return }
        lists[index] = try await service.updateList(
            id: id,
            name: name,
            description: description.isEmpty ? nil : description
        )
    }

    func deleteList(id: String) async throws {
        guard let index = lists.firstIndex(where: { $0.id == id }),
              !lists[index].isSystem else { return }
        try await service.deleteList(id: id)
        lists.remove(at: index)
        memberships[id] = nil
    }
}
