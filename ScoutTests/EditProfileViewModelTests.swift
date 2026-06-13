import Testing
import Foundation
@testable import Scout

/// Reference-type stub that records the `ProfileUpdate` passed to `updateProfile`
/// and how many times it ran, so we can assert what Save sends (and that an
/// unchanged form sends nothing). Optionally throws to exercise the error path.
private final class RecordingUserService: UserService, @unchecked Sendable {
    private(set) var lastUpdate: ProfileUpdate?
    private(set) var updateCount = 0
    var shouldThrow = false
    var returned: UserProfile = .sample

    func updateProfile(_ update: ProfileUpdate) async throws -> UserProfile {
        lastUpdate = update
        updateCount += 1
        if shouldThrow { throw SpotServiceError.http(status: 500) }
        return returned
    }

    func fetchCurrentUser() async throws -> UserProfile { .sample }
    func fetchMyReviews(limit: Int, cursor: String?) async throws -> PaginatedReviews {
        PaginatedReviews(items: [], limit: limit, nextCursor: nil)
    }
    func deleteReview(id: String) async throws {}
    func deleteAccount() async throws {}
}

@MainActor
struct EditProfileViewModelTests {

    @Test func savingAChangedFieldSendsItAndReportsSuccess() async {
        let service = RecordingUserService()
        let updated = UserProfile(id: "u1", email: "u@example.com", displayName: "New Name",
                                  homeCity: "Seattle", homeCountry: "US",
                                  photoUrl: nil, reviewCount: 3)
        service.returned = updated

        var savedProfile: UserProfile?
        let vm = EditProfileViewModel(profile: .sample, userService: service) { savedProfile = $0 }
        vm.displayName = "New Name"

        let ok = await vm.save()

        #expect(ok)
        #expect(service.updateCount == 1)
        #expect(service.lastUpdate?.displayName == "New Name")
        #expect(savedProfile == updated)
    }

    @Test func unchangedFormIsANoOpSuccess() async {
        let service = RecordingUserService()
        let vm = EditProfileViewModel(profile: .sample, userService: service) { _ in }

        let ok = await vm.save()

        #expect(ok)
        #expect(service.updateCount == 0)   // nothing changed → no request
    }

    @Test func failedSaveSurfacesErrorAndReportsFailure() async {
        let service = RecordingUserService()
        service.shouldThrow = true
        var savedProfile: UserProfile?
        let vm = EditProfileViewModel(profile: .sample, userService: service) { savedProfile = $0 }
        vm.displayName = "Changed"

        let ok = await vm.save()

        #expect(!ok)
        #expect(vm.saveError != nil)
        #expect(savedProfile == nil)
    }

    @Test func pickedPhotoIsIncludedInTheUpdate() async {
        let service = RecordingUserService()
        let vm = EditProfileViewModel(profile: .sample, userService: service) { _ in }
        vm.pickedPhoto(Data([0x01, 0x02, 0x03]))

        _ = await vm.save()

        #expect(service.updateCount == 1)            // a picked photo alone is a change
        #expect(service.lastUpdate?.photoData != nil)
    }
}
