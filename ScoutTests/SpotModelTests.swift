import Testing
import Foundation
@testable import Scout

/// Decoding + derived-property tests for the spot/review models. These mirror
/// the backend schemas (`SpotSummaryResponse`, `SpotResponse`, `ReviewResponse`)
/// and verify they decode through `JSONDecoder.scout` (snake_case + ISO-8601).
struct SpotModelTests {

    // MARK: - SpotSummary decoding

    @Test func decodesSpotSummaryFromBackendJSON() throws {
        let json = """
        {
            "id": "abc",
            "name": "Cedar Cathedral",
            "public_lat": 45.51,
            "public_lng": -122.68,
            "city": "Portland",
            "admin_area": "Oregon",
            "country": "USA",
            "created_at": "2026-05-01T12:00:00Z",
            "review_count": 128,
            "avg_rating": 4.9,
            "cover_photo_url": "https://example.com/cover.jpg",
            "recent_review_photos": [],
            "best_times": ["GoldenHour"],
            "mode_permit_required": false,
            "mode_drone_allowed": null,
            "mode_tripod_allowed": true
        }
        """.data(using: .utf8)!

        let spot = try JSONDecoder.scout.decode(SpotSummary.self, from: json)

        #expect(spot.id == "abc")
        #expect(spot.name == "Cedar Cathedral")
        #expect(spot.publicLat == 45.51)
        #expect(spot.adminArea == "Oregon")
        #expect(spot.reviewCount == 128)
        #expect(spot.avgRating == 4.9)
        #expect(spot.coverPhotoUrl?.absoluteString == "https://example.com/cover.jpg")
        #expect(spot.shootingTimes == [.goldenHour])
        #expect(spot.modePermitRequired == false)
        #expect(spot.modeDroneAllowed == nil)
        #expect(spot.modeTripodAllowed == true)
    }

    @Test func carouselPutsCoverFirstThenRecentPhotos() throws {
        let json = """
        {
            "id": "x", "name": "N",
            "public_lat": 0, "public_lng": 0,
            "city": "C", "admin_area": "A", "country": "U",
            "created_at": "2026-05-01T12:00:00Z",
            "review_count": 1, "avg_rating": 4.0,
            "cover_photo_url": "https://example.com/cover.jpg",
            "recent_review_photos": [
                {"review_id": "r1", "photo_url": "https://example.com/p1.jpg", "created_at": "2026-05-01T12:00:00Z"},
                {"review_id": "r2", "photo_url": "https://example.com/p2.jpg", "created_at": "2026-05-01T12:00:00Z"}
            ],
            "best_times": []
        }
        """.data(using: .utf8)!

        let spot = try JSONDecoder.scout.decode(SpotSummary.self, from: json)
        let urls = spot.carouselPhotos.map(\.absoluteString)

        #expect(urls == [
            "https://example.com/cover.jpg",
            "https://example.com/p1.jpg",
            "https://example.com/p2.jpg"
        ])
        #expect(spot.coverPhoto?.absoluteString == "https://example.com/cover.jpg")
    }

    @Test func carouselFallsBackToRecentPhotosWhenNoCover() {
        let bare = SpotSummary(
            id: "1", name: "N", publicLat: 0, publicLng: 0,
            city: "", adminArea: "", country: "",
            createdAt: Date(), reviewCount: 0, avgRating: 0,
            coverPhotoUrl: nil,
            recentReviewPhotos: [
                RecentReviewPhoto(reviewId: "r1",
                                  photoUrl: URL(string: "https://example.com/p1.jpg"),
                                  createdAt: Date())
            ],
            bestTimes: [],
            modePermitRequired: nil, modeDroneAllowed: nil, modeTripodAllowed: nil
        )
        #expect(bare.coverPhoto?.absoluteString == "https://example.com/p1.jpg")
        #expect(bare.carouselPhotos.count == 1)
    }

    // MARK: - SpotDetail

    @Test func spotDetailSubtitleCombinesEnvironmentAndLocality() {
        let detail = SpotDetail.sample
        #expect(detail.subtitle == "Mountain • Cascade Range, WA")
    }

    @Test func spotDetailDecodesFullBackendSchema() throws {
        let json = """
        {
            "id": "1", "name": "Basin",
            "public_lat": 1.0, "public_lng": 2.0,
            "city": "Town", "admin_area": "ST", "country": "US",
            "created_at": "2026-05-01T12:00:00Z",
            "review_count": 5, "avg_rating": 4.2,
            "recent_review_photos": [],
            "mode_access_level": "Moderate",
            "mode_entrance_fee": "Free",
            "mode_crowd_level": "Light",
            "mode_environment": "Mountain",
            "best_times": ["GoldenHour", "BlueHour"],
            "mode_permit_required": false,
            "mode_drone_allowed": false,
            "mode_tripod_allowed": true,
            "recent_gear_recommendations": ["Wide-angle lens", "ND filter"],
            "recent_composition_hints": ["Foreground rocks"]
        }
        """.data(using: .utf8)!

        let detail = try JSONDecoder.scout.decode(SpotDetail.self, from: json)

        #expect(detail.modeEnvironment == "Mountain")
        #expect(detail.shootingTimes == [.goldenHour, .blueHour])
        #expect(detail.modePermitRequired == false)
        #expect(detail.modeTripodAllowed == true)
        #expect(detail.recentGearRecommendations.count == 2)
        #expect(detail.recentCompositionHints == ["Foreground rocks"])
        #expect(detail.hasLogistics)
        #expect(detail.hasGearOrComposition)
    }

    @Test func spotDetailDecodesWithMissingOptionalAggregates() throws {
        // best_times / gear / composition default to []; mode_* booleans to nil.
        let json = """
        {
            "id": "1", "name": "Basin",
            "public_lat": 1.0, "public_lng": 2.0,
            "city": "Town", "admin_area": "ST", "country": "US",
            "created_at": "2026-05-01T12:00:00Z",
            "review_count": 5, "avg_rating": 4.2,
            "recent_review_photos": [],
            "mode_access_level": "Moderate",
            "mode_entrance_fee": "Free",
            "mode_crowd_level": "Light",
            "mode_environment": "Mountain",
            "best_times": [],
            "recent_gear_recommendations": [],
            "recent_composition_hints": []
        }
        """.data(using: .utf8)!

        let detail = try JSONDecoder.scout.decode(SpotDetail.self, from: json)

        #expect(detail.modePermitRequired == nil)
        #expect(!detail.hasLogistics)
        #expect(!detail.hasGearOrComposition)
        #expect(detail.shootingTimes.isEmpty)
    }

    // MARK: - Review decoding

    @Test func decodesReviewWithLogisticsAndOptionalText() throws {
        let json = """
        {
            "id": "r1", "spot_id": "s1", "user_id": "u1",
            "photo_urls": ["https://example.com/a.jpg"],
            "overall_rating": 5,
            "notes": "Great spot",
            "best_time_of_day": ["GoldenHour"],
            "access_level": "Moderate",
            "entrance_fee": "Free",
            "crowd_level": "Light",
            "environment": "Mountain",
            "gear_recommendations": "Wide-angle",
            "composition_hints": "",
            "permit_required": false,
            "drone_allowed": true,
            "tripod_allowed": true,
            "created_at": "2026-05-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let review = try JSONDecoder.scout.decode(Review.self, from: json)

        #expect(review.overallRating == 5)
        #expect(review.times == [.goldenHour])
        #expect(review.gearRecommendations == "Wide-angle")
        #expect(review.droneAllowed == true)
        #expect(review.permitRequired == false)
    }

    // MARK: - TimeOfDay

    @Test func timeOfDayParsesBackendLiterals() {
        // Canonical PascalCase (matches backend BestTimeOfDay).
        #expect(TimeOfDay(raw: "GoldenHour") == .goldenHour)
        #expect(TimeOfDay(raw: "BlueHour") == .blueHour)
        #expect(TimeOfDay(raw: "Sunrise") == .sunrise)
        #expect(TimeOfDay(raw: "Midday") == .midday)
        #expect(TimeOfDay(raw: "Night") == .night)
        // Tolerant variants.
        #expect(TimeOfDay(raw: "golden_hour") == .goldenHour)
        #expect(TimeOfDay(raw: "Blue Hour") == .blueHour)
        #expect(TimeOfDay(raw: "nonsense") == nil)
    }

    @Test func reviewTimesDropsUnknownValues() {
        let review = Review(
            id: "r", spotId: "s", userId: "u", photoUrls: [],
            overallRating: 5, notes: "",
            bestTimeOfDay: ["Sunrise", "garbage", "BlueHour"],
            accessLevel: "", entranceFee: "", crowdLevel: "", environment: "",
            gearRecommendations: nil, compositionHints: nil,
            permitRequired: false, droneAllowed: false, tripodAllowed: false,
            createdAt: Date()
        )
        #expect(review.times == [.sunrise, .blueHour])
    }
}
