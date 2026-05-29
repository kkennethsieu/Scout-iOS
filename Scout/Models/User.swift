import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let createdAt: Date
    
    // V2: bio, follower count, etc.
}
