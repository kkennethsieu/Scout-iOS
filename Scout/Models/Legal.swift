import Foundation

/// Links to the hosted legal documents (`GET /legal`). Keys are lowercase-`url`
/// to match the `.convertFromSnakeCase` decoder (e.g. `privacy_policy_url` →
/// `privacyPolicyUrl`), like `UserProfile.photoUrl`. The backend's `updated_at`
/// is intentionally ignored here.
nonisolated struct LegalResponse: Decodable {
    let privacyPolicyUrl: String
    let termsOfServiceUrl: String
}
