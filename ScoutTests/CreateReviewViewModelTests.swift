import Testing
import CoreLocation
import Foundation
@testable import Scout

/// Covers `CreateReviewViewModel`: spot-identity resolution, the submit-gate
/// validation (mirroring the endpoint's constraints), the photo cap, and the
/// payload mapping onto the multipart create endpoint.
@MainActor
struct CreateReviewViewModelTests {

    private let coordinate = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)

    private func makeVM(target: CreateReviewViewModel.Target = .newSpot(name: "Emerald Basin"),
                        photoData: Data? = nil) -> CreateReviewViewModel {
        CreateReviewViewModel(target: target, coordinate: coordinate,
                              regionText: "Portland, USA", photoData: photoData)
    }

    // MARK: - Target / identity

    @Test func spotNameResolvesFromTarget() {
        #expect(makeVM(target: .newSpot(name: "Emerald Basin")).spotName == "Emerald Basin")
        #expect(makeVM(target: .existingSpot(id: "1", name: "Cedar Cathedral")).spotName == "Cedar Cathedral")
    }

    @Test func isNewSpotReflectsTarget() {
        #expect(makeVM(target: .newSpot(name: "X")).isNewSpot)
        #expect(makeVM(target: .existingSpot(id: "1", name: "X")).isNewSpot == false)
    }

    @Test func setNewSpotNameUpdatesTargetAndName() {
        let vm = makeVM(target: .newSpot(name: ""))
        vm.setNewSpotName("Bixby Creek Bridge")
        #expect(vm.spotName == "Bixby Creek Bridge")
        #expect(vm.isNewSpot)
    }

    @Test func reviewExistingSwitchesTarget() {
        let vm = makeVM(target: .newSpot(name: ""))
        vm.reviewExisting(id: "42", name: "Cedar Cathedral")
        #expect(vm.isNewSpot == false)
        #expect(vm.spotName == "Cedar Cathedral")
        #expect(vm.target == .existingSpot(id: "42", name: "Cedar Cathedral"))
    }

    @Test func placeUpdatesCoordinateAndRegion() {
        let vm = CreateReviewViewModel(target: .newSpot(name: "X"), coordinate: nil)
        #expect(vm.coordinate == nil)
        let pin = CLLocationCoordinate2D(latitude: 46.5572, longitude: 8.5614)
        vm.place(coordinate: pin, regionText: "Andermatt, Switzerland")
        #expect(vm.coordinate?.latitude == pin.latitude)
        #expect(vm.coordinate?.longitude == pin.longitude)
        #expect(vm.regionText == "Andermatt, Switzerland")
        #expect(vm.makePayload().lat == pin.latitude)   // now flows into the payload
    }

    // MARK: - Submit gate

    @Test func canSubmitTrueWhenComplete() {
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "Emerald Basin",
                                                notes: "Lovely light", hasLocation: true))
    }

    @Test func canSubmitFalseOnEmptyOrWhitespace() {
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "  ", notes: "x", hasLocation: true) == false)
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "X", notes: "  ", hasLocation: true) == false)
    }

    @Test func canSubmitFalseOnRatingOutOfRange() {
        #expect(CreateReviewViewModel.canSubmit(rating: 0, name: "X", notes: "x", hasLocation: true) == false)
        #expect(CreateReviewViewModel.canSubmit(rating: 6, name: "X", notes: "x", hasLocation: true) == false)
    }

    @Test func canSubmitFalseWithoutLocation() {
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "X", notes: "x", hasLocation: false) == false)
    }

    @Test func canSubmitFalseWhenTextExceedsCaps() {
        let longName = String(repeating: "a", count: CreateReviewViewModel.maxNameLength + 1)
        let longNotes = String(repeating: "a", count: CreateReviewViewModel.maxNotesLength + 1)
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: longName, notes: "x", hasLocation: true) == false)
        #expect(CreateReviewViewModel.canSubmit(rating: 4, name: "X", notes: longNotes, hasLocation: true) == false)
    }

    @Test func instanceCanSubmitRequiresValidCoordinate() {
        let vm = CreateReviewViewModel(target: .newSpot(name: "Emerald Basin"), coordinate: nil)
        vm.notes = "Lovely light"
        #expect(vm.canSubmit == false)        // no coordinate → can't create the spot

        let placed = makeVM(target: .newSpot(name: "Emerald Basin"))
        placed.notes = "Lovely light"
        #expect(placed.canSubmit)
    }

    // MARK: - Environment collapse

    @Test func primaryEnvironmentPicksFirstInCanonicalOrder() {
        // "Forest" precedes "Water" in the option list regardless of set order.
        #expect(CreateReviewViewModel.primaryEnvironment(from: ["Water", "Forest"]) == "Forest")
        #expect(CreateReviewViewModel.primaryEnvironment(from: []) == "")
    }

    // MARK: - Photos (capped, seeded)

    @Test func photosSeedFromUploadedPhoto() {
        let vm = makeVM(photoData: Data([0x1]))
        #expect(vm.photos.count == 1)
    }

    @Test func addPhotoStopsAtCap() {
        let vm = makeVM()
        for i in 0..<(CreateReviewViewModel.maxPhotos + 2) {
            vm.addPhoto(Data([UInt8(i)]))
        }
        #expect(vm.photos.count == CreateReviewViewModel.maxPhotos)
        #expect(vm.canAddPhoto == false)
    }

    @Test func removePhotoDropsAtIndex() {
        let vm = makeVM()
        vm.addPhoto(Data([0x1]))
        vm.addPhoto(Data([0x2]))
        vm.removePhoto(at: 0)
        #expect(vm.photos == [Data([0x2])])
        #expect(vm.canAddPhoto)
        vm.removePhoto(at: 5)   // out of range → no-op
        #expect(vm.photos.count == 1)
    }

    // MARK: - Payload mapping

    @Test func payloadMapsFieldsAndLocation() {
        let vm = makeVM(target: .newSpot(name: "  Emerald Basin  "), photoData: Data([0x9]))
        vm.rating = 5
        vm.notes = "Lovely light"
        vm.times = [.sunrise, .goldenHour]      // out of canonical order on purpose
        vm.environments = ["Water", "Forest"]
        vm.gear = ""
        vm.compositionHint = ""

        let payload = vm.makePayload()
        #expect(payload.name == "Emerald Basin")                 // trimmed
        #expect(payload.lat == coordinate.latitude)
        #expect(payload.lng == coordinate.longitude)
        #expect(payload.overallRating == 5)
        #expect(payload.bestTimeOfDay == ["GoldenHour", "Sunrise"])  // canonical order, raw values
        #expect(payload.environment == "Forest")
        #expect(payload.gearRecommendations == "")               // default, not nil
        #expect(payload.compositionHints == "")
        #expect(payload.photos.count == 1)
    }

    // MARK: - Submit lifecycle

    @Test func submitSucceedsWhenValid() async {
        let vm = makeVM()
        vm.notes = "Lovely light"
        await vm.submit()
        #expect(vm.phase == .success)
    }

    @Test func submitIsNoOpWhenInvalid() async {
        let vm = makeVM()
        // notes empty → can't submit
        await vm.submit()
        #expect(vm.phase == .idle)
    }
}
