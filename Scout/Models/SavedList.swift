import Foundation

/// A saved list overview, mirroring the backend `ListResponse`. The list's spots
/// are NOT embedded here — they're paged separately via the list-spots endpoint
/// (see `SavedListService.fetchListSpots`). `samples` is fake data for
/// previews/tests/mocks only.
nonisolated struct SavedList: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let description: String?
    let spotCount: Int
    let coverPhotoUrl: URL?
    let createdAt: Date
    let updatedAt: Date
    /// App-managed list (the always-present "Favorites"). System lists can't be
    /// edited or deleted — a user-created list merely *named* "favorites" is a
    /// normal, separate list with `isSystem == false`.
    var isSystem: Bool = false

    var spotCountLabel: String { "\(spotCount) spot\(spotCount == 1 ? "" : "s")" }
}

// MARK: - Fake data

nonisolated extension SavedList {
    /// Two hard-coded lists mirroring the reference: an app-managed "Favorites"
    /// and a photo-thumbnail "my hikes".
    static let samples: [SavedList] = [
        SavedList(
            id: "favorites",
            name: "Favorites",
            description: "Spots I keep coming back to.",
            spotCount: 7,
            coverPhotoUrl: nil,
            createdAt: Date(timeIntervalSinceNow: -86_400 * 30),
            updatedAt: Date(timeIntervalSinceNow: -86_400),
            isSystem: true
        ),
        SavedList(
            id: "my-hikes",
            name: "my hikes",
            description: "test description",
            spotCount: 2,
            coverPhotoUrl: URL(string: "https://picsum.photos/seed/favorite-1/800/500"),
            createdAt: Date(timeIntervalSinceNow: -86_400 * 5),
            updatedAt: Date(timeIntervalSinceNow: -3_600),
            isSystem: false
        )
    ]
}
