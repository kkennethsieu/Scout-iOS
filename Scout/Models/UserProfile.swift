import Foundation

/// The signed-in user's backend profile (`GET /users/me`). Distinct from the
/// Firebase-mapped `User` in `AuthService` — this carries the backend-owned
/// aggregates (e.g. `reviewCount`) and display fields that drive the Profile
/// header. Fetched fresh on each Profile load rather than cached on auth.
nonisolated struct UserProfile: Decodable, Hashable, Identifiable {
    let id: String
    /// The Firebase Auth login identity — shown read-only on Edit Profile; not
    /// editable via `PATCH /users/me`.
    let email: String
    let displayName: String
    let homeCity: String?
    let homeCountry: String?
    let photoUrl: URL?
    /// `var` (not `let`) so the client can adjust it locally — e.g. decrement on a
    /// successful review delete — without refetching the whole profile.
    var reviewCount: Int
    /// Notification preferences (default on); toggled via `PATCH /users/me`.
    /// Default values so older payloads / constructions without them still decode.
    var emailNotifications: Bool = true
    var pushNotifications: Bool = true
}

// MARK: - Sample data

nonisolated extension UserProfile {
    static let sample = UserProfile(
        id: "u1",
        email: "marcus@example.com",
        displayName: "Marcus Chen",
        homeCity: "San Francisco",
        homeCountry: "CA",
        photoUrl: nil,
        reviewCount: 12
    )
}
