import Foundation

/// The signed-in user's backend profile (`GET /users/me`). Distinct from the
/// Firebase-mapped `User` in `AuthService` — this carries the backend-owned
/// aggregates (e.g. `reviewCount`) and display fields that drive the Profile
/// header. Fetched fresh on each Profile load rather than cached on auth.
nonisolated struct UserProfile: Decodable, Hashable, Identifiable {
    let id: String
    let displayName: String
    let homeCity: String?
    let homeCountry: String?
    let photoUrl: URL?
    /// `var` (not `let`) so the client can adjust it locally — e.g. decrement on a
    /// successful review delete — without refetching the whole profile.
    var reviewCount: Int
}

// MARK: - Sample data

nonisolated extension UserProfile {
    static let sample = UserProfile(
        id: "u1",
        displayName: "Marcus Chen",
        homeCity: "San Francisco",
        homeCountry: "CA",
        photoUrl: nil,
        reviewCount: 12
    )
}
