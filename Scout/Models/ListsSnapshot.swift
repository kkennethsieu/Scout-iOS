import Foundation

/// Atomic snapshot of the user's saved state, returned by `GET /users/me/lists`
/// and `PATCH /users/me/spots/{spot_id}/lists`. `memberships` maps every list id
/// to its spot ids (empty lists → `[]`), so the app hydrates lists + bookmark /
/// checkbox state from one read.
///
/// Note: `JSONDecoder.scout` uses `convertFromSnakeCase`, which also rewrites
/// dictionary keys — so this assumes list ids contain no underscores.
nonisolated struct ListsSnapshot: Decodable {
    let lists: [SavedList]
    let memberships: [String: [String]]
}
