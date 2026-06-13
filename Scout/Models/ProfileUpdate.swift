import Foundation

/// A partial update to the signed-in user's profile, sent by Edit Profile's "Save"
/// (`PATCH /users/me`, multipart). Each text field is `nil` when unchanged; the
/// avatar carries the **raw** picked bytes — the Live service transcodes them to
/// JPEG (`Data.jpegForUpload()`) before upload.
nonisolated struct ProfileUpdate {
    var displayName: String?
    var homeCity: String?
    var homeCountry: String?
    var photoData: Data?

    /// True when nothing changed, so `save()` can short-circuit without a request.
    var isEmpty: Bool {
        displayName == nil && homeCity == nil && homeCountry == nil && photoData == nil
    }
}
