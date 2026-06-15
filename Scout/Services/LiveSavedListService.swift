import Foundation

/// `BackendClient`-backed `SavedListService`.
///
/// Backend routes:
/// - `GET /users/me/lists` → `[ListResponse]` (Favorites first; created if missing)
/// - `GET /users/me/lists/{list_id}/spots` → `PaginatedSpots` (cursor-paginated, newest first)
nonisolated struct LiveSavedListService: SavedListService {
    var client = BackendClient()

    func fetchSnapshot() async throws -> ListsSnapshot {
        try await client.get("users/me/lists")
    }

    func setSpotMembership(spotID: String, listIDs: [String]) async throws -> ListsSnapshot {
        try await client.patch("users/me/spots/\(spotID)/lists",
                               body: MembershipBody(listIds: listIDs))
    }

    func fetchListSpots(listID: String, limit: Int, cursor: String?) async throws -> PaginatedSpots {
        var query = ["limit": "\(limit)"]
        if let cursor { query["cursor"] = cursor }
        return try await client.get("users/me/lists/\(listID)/spots", query: query)
    }

    func createList(name: String, description: String?) async throws -> SavedList {
        try await client.post("users/me/lists", body: CreateBody(name: name, description: description))
    }

    func updateList(id: String, name: String?, description: String?) async throws -> SavedList {
        // Only set fields are sent (optionals omit via `encodeIfPresent`), matching
        // the endpoint's `exclude_unset` semantics.
        try await client.patch("users/me/lists/\(id)", body: UpdateBody(name: name, description: description))
    }

    func deleteList(id: String) async throws {
        try await client.delete("users/me/lists/\(id)")
    }

    // MARK: - Request bodies

    private nonisolated struct CreateBody: Encodable {
        let name: String
        let description: String?
    }

    private nonisolated struct UpdateBody: Encodable {
        let name: String?
        let description: String?
    }

    private nonisolated struct MembershipBody: Encodable {
        let listIds: [String]   // encodes as list_ids
    }
}
