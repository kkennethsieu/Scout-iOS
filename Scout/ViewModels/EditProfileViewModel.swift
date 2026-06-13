import SwiftUI
import Observation

/// Drives `EditProfileScreen`. Seeded from the current `UserProfile`, it tracks the
/// editable fields (display name + home city/country) and a locally-picked avatar,
/// then persists only what changed via `UserService.updateProfile` (`PATCH /users/me`).
/// Email is not here — it's owned by Firebase Auth and shown read-only by the screen.
@Observable
@MainActor
final class EditProfileViewModel {
    // MARK: - Editable fields (seeded from `original`)

    var displayName: String
    var homeCity: String
    var homeCountry: String

    // MARK: - Avatar

    /// Local preview of a just-picked photo; `nil` until the user picks one (the
    /// screen falls back to `currentPhotoURL`).
    private(set) var avatarPreview: Image?
    /// Raw picked bytes, uploaded on save (the Live service transcodes to JPEG).
    private var pickedPhotoData: Data?

    /// The existing avatar to show when no new photo has been picked.
    var currentPhotoURL: URL? { original.photoUrl }

    /// The read-only login email (Firebase identity), shown but not editable.
    var email: String { original.email }

    // MARK: - Save state

    private(set) var isSaving = false
    private(set) var saveError: String?

    // MARK: - Dependencies

    private let original: UserProfile
    private let userService: UserService
    private let onSaved: (UserProfile) -> Void

    init(profile: UserProfile,
         userService: UserService = AppServices.user,
         onSaved: @escaping (UserProfile) -> Void) {
        self.original = profile
        self.displayName = profile.displayName
        self.homeCity = profile.homeCity ?? ""
        self.homeCountry = profile.homeCountry ?? ""
        self.userService = userService
        self.onSaved = onSaved
    }

    // MARK: - Actions

    /// Adopts a newly picked avatar: keeps the raw bytes for upload and updates the
    /// on-screen preview.
    func pickedPhoto(_ data: Data) {
        pickedPhotoData = data
        avatarPreview = Image(data: data)
    }

    /// Persists the changed fields. Returns `true` on success (the screen dismisses);
    /// an unchanged form is a no-op success. On failure, surfaces `saveError` and
    /// returns `false` so the screen stays open.
    func save() async -> Bool {
        let update = buildUpdate()
        guard !update.isEmpty else { return true }

        isSaving = true
        defer { isSaving = false }
        do {
            let updated = try await userService.updateProfile(update)
            onSaved(updated)
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func dismissSaveError() { saveError = nil }

    // MARK: - Helpers

    /// Builds an update carrying only the fields that actually changed (trimmed),
    /// plus the picked photo if any.
    private func buildUpdate() -> ProfileUpdate {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = homeCity.trimmingCharacters(in: .whitespacesAndNewlines)
        let country = homeCountry.trimmingCharacters(in: .whitespacesAndNewlines)
        return ProfileUpdate(
            displayName: name != original.displayName ? name : nil,
            homeCity: city != (original.homeCity ?? "") ? city : nil,
            homeCountry: country != (original.homeCountry ?? "") ? country : nil,
            photoData: pickedPhotoData
        )
    }
}
