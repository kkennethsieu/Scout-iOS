import Foundation

/// The signed-in user's saved lists. Owns the `/users/me/lists/*` read endpoints.
/// View models depend on this protocol, not a concrete networking type.
nonisolated protocol SavedListService {
    /// The caller's full saved snapshot — lists (Favorites first) + the
    /// list→spots membership map (`GET /users/me/lists`).
    func fetchSnapshot() async throws -> ListsSnapshot
    /// Sets the exact set of lists a spot belongs to in one transaction
    /// (`PATCH /users/me/spots/{spot_id}/lists`). Returns the refreshed snapshot.
    func setSpotMembership(spotID: String, listIDs: [String]) async throws -> ListsSnapshot
    /// A list's spots, newest first, cursor-paginated
    /// (`GET /users/me/lists/{list_id}/spots`). Pass the previous page's
    /// `nextCursor` to fetch the next page (`nil` for page one).
    func fetchListSpots(listID: String, limit: Int, cursor: String?) async throws -> PaginatedSpots

    /// Creates a new list (`POST /users/me/lists`). Returns the created list.
    func createList(name: String, description: String?) async throws -> SavedList
    /// Edits a list's name and/or description (`PATCH /users/me/lists/{id}`).
    /// Returns the updated list. The backend rejects edits to Favorites.
    func updateList(id: String, name: String?, description: String?) async throws -> SavedList
    /// Deletes a list (`DELETE /users/me/lists/{id}`). The backend rejects
    /// deleting Favorites.
    func deleteList(id: String) async throws
}

/// Hardcoded data for development / previews / real-device fallback.
nonisolated struct MockSavedListService: SavedListService {
    var delay: Duration = .milliseconds(400)
    /// The spots a list returns; override (e.g. `[]`) to preview empty lists.
    var listSpots: [SpotSummary] = SpotSummary.samples

    func fetchSnapshot() async throws -> ListsSnapshot {
        try await Task.sleep(for: delay)
        return Self.sampleSnapshot
    }

    func setSpotMembership(spotID: String, listIDs: [String]) async throws -> ListsSnapshot {
        try await Task.sleep(for: delay)
        // Apply the requested set for this spot on top of the sample map.
        var map = Self.sampleMemberships
        for id in map.keys {
            map[id]?.removeAll { $0 == spotID }
        }
        for id in listIDs {
            map[id, default: []].append(spotID)
        }
        return ListsSnapshot(lists: SavedList.samples, memberships: map)
    }

    static let sampleMemberships: [String: [String]] = [
        "favorites": SpotSummary.samples.prefix(3).map(\.id),
        "my-hikes": SpotSummary.samples.prefix(2).map(\.id)
    ]

    static let sampleSnapshot = ListsSnapshot(lists: SavedList.samples,
                                              memberships: sampleMemberships)

    /// Fakes pagination via an integer-offset "cursor" over `listSpots`.
    func fetchListSpots(listID: String, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        try await Task.sleep(for: delay)
        let start = cursor.flatMap(Int.init) ?? 0
        let slice = Array(listSpots.dropFirst(start).prefix(limit))
        let end = start + slice.count
        let next = end < listSpots.count ? String(end) : nil
        return PaginatedSpots(items: slice, limit: limit, nextCursor: next)
    }

    func createList(name: String, description: String?) async throws -> SavedList {
        try await Task.sleep(for: delay)
        let now = Date()
        return SavedList(id: UUID().uuidString, name: name, description: description,
                         spotCount: 0, coverPhotoUrl: nil, createdAt: now, updatedAt: now)
    }

    func updateList(id: String, name: String?, description: String?) async throws -> SavedList {
        try await Task.sleep(for: delay)
        return SavedList(id: id, name: name ?? "Untitled", description: description,
                         spotCount: 0, coverPhotoUrl: nil, createdAt: Date(), updatedAt: Date())
    }

    func deleteList(id: String) async throws {
        try await Task.sleep(for: delay)
    }
}
