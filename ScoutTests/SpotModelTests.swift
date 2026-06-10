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

    @Test func spotDetailSubtitleIsLocality() {
        let detail = SpotDetail.sample
        #expect(detail.subtitle == "Cascade Range, WA")
        #expect(detail.seasonsText == "Spring, Fall")
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
            "avg_entrance_fee": 7.5,
            "mode_crowd_level": "Light",
            "best_times": ["GoldenHour", "BlueHour"],
            "best_seasons": ["Spring", "Fall"],
            "mode_permit_required": false,
            "mode_drone_allowed": false,
            "mode_tripod_allowed": true,
            "recent_gear_recommendations": ["Wide-angle lens", "ND filter"],
            "recent_composition_hints": ["Foreground rocks"]
        }
        """.data(using: .utf8)!

        let detail = try JSONDecoder.scout.decode(SpotDetail.self, from: json)

        #expect(detail.modeAccessLevel == "Moderate")
        #expect(detail.avgEntranceFee == 7.5)
        #expect(detail.entranceFeeText == "$7.50")
        #expect(detail.seasons == [.spring, .fall])
        #expect(detail.shootingTimes == [.goldenHour, .blueHour])
        #expect(detail.modePermitRequired == false)
        #expect(detail.modeTripodAllowed == true)
        #expect(detail.recentGearRecommendations.count == 2)
        #expect(detail.recentCompositionHints == ["Foreground rocks"])
        #expect(detail.hasLogistics)
        #expect(detail.hasGearOrComposition)
    }

    @Test func spotDetailDecodesWithMissingOptionalAggregates() throws {
        // best_times/best_seasons/gear/composition default to []; mode_* strings
        // and booleans to nil.
        let json = """
        {
            "id": "1", "name": "Basin",
            "public_lat": 1.0, "public_lng": 2.0,
            "city": "Town", "admin_area": "ST", "country": "US",
            "created_at": "2026-05-01T12:00:00Z",
            "review_count": 5, "avg_rating": 4.2,
            "recent_review_photos": [],
            "best_times": [],
            "best_seasons": [],
            "recent_gear_recommendations": [],
            "recent_composition_hints": []
        }
        """.data(using: .utf8)!

        let detail = try JSONDecoder.scout.decode(SpotDetail.self, from: json)

        #expect(detail.modeAccessLevel == nil)
        #expect(detail.avgEntranceFee == nil)
        #expect(detail.entranceFeeText == "—")
        #expect(detail.modeCrowdLevel == nil)
        #expect(detail.modePermitRequired == nil)
        #expect(!detail.hasLogistics)
        #expect(!detail.hasGearOrComposition)
        #expect(detail.shootingTimes.isEmpty)
        #expect(detail.seasonsText == "—")
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
            "best_season": ["Spring", "Fall"],
            "access_level": "Moderate",
            "entrance_fee": 0,
            "crowd_level": "Light",
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
        #expect(review.entranceFee == 0)
        #expect(review.times == [.goldenHour])
        #expect(review.seasons == [.spring, .fall])
        #expect(review.gearRecommendations == "Wide-angle")
        #expect(review.droneAllowed == true)
        #expect(review.permitRequired == false)
    }

    @Test func decodesReviewWithOnlyRequiredFields() throws {
        // Backend always emits the list defaults ([]); everything else may be
        // absent → optionals decode as nil.
        let json = """
        {
            "id": "r1", "spot_id": "s1", "user_id": "u1",
            "photo_urls": ["https://example.com/a.jpg"],
            "overall_rating": 3,
            "best_time_of_day": [],
            "best_season": [],
            "created_at": "2026-05-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let review = try JSONDecoder.scout.decode(Review.self, from: json)

        #expect(review.overallRating == 3)
        #expect(review.notes == nil)
        #expect(review.accessLevel == nil)
        #expect(review.permitRequired == nil)
        #expect(review.droneAllowed == nil)
        #expect(review.tripodAllowed == nil)
        #expect(review.times.isEmpty)
        #expect(review.seasons.isEmpty)
    }

    @Test func decodesPaginatedReviewsEnvelope() throws {
        let json = """
        {
            "items": [
                {
                    "id": "r1", "spot_id": "s1", "user_id": "u1",
                    "photo_urls": [],
                    "overall_rating": 4,
                    "notes": "Nice",
                    "best_time_of_day": ["Sunrise"],
                    "best_season": ["Summer"],
                    "access_level": "Easy",
                    "entrance_fee": 12.5,
                    "crowd_level": "Light",
                    "gear_recommendations": null,
                    "composition_hints": null,
                    "permit_required": false,
                    "drone_allowed": false,
                    "tripod_allowed": true,
                    "created_at": "2026-05-01T12:00:00Z"
                }
            ],
            "limit": 20,
            "next_cursor": "eyJpZCI6InIxIn0="
        }
        """.data(using: .utf8)!

        let page = try JSONDecoder.scout.decode(PaginatedReviews.self, from: json)

        #expect(page.items.count == 1)
        #expect(page.items.first?.id == "r1")
        #expect(page.limit == 20)
        #expect(page.nextCursor == "eyJpZCI6InIxIn0=")
    }

    @Test func decodesPaginatedReviewsWithNullCursor() throws {
        let json = """
        { "items": [], "limit": 20, "next_cursor": null }
        """.data(using: .utf8)!

        let page = try JSONDecoder.scout.decode(PaginatedReviews.self, from: json)

        #expect(page.items.isEmpty)
        #expect(page.nextCursor == nil)
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

    // MARK: - Season

    @Test func seasonParsesBackendLiterals() {
        // Canonical PascalCase (matches backend Season).
        #expect(Season(raw: "Spring") == .spring)
        #expect(Season(raw: "Summer") == .summer)
        #expect(Season(raw: "Fall") == .fall)
        #expect(Season(raw: "Winter") == .winter)
        #expect(Season(raw: "YearRound") == .yearRound)
        // Tolerant variants.
        #expect(Season(raw: "year_round") == .yearRound)
        #expect(Season(raw: "autumn") == .fall)
        #expect(Season(raw: "nonsense") == nil)
    }

    @Test func reviewTimesDropsUnknownValues() {
        let review = Review(
            id: "r", spotId: "s", spotName: nil, userId: "u", photoUrls: [],
            overallRating: 5, notes: nil,
            bestTimeOfDay: ["Sunrise", "garbage", "BlueHour"],
            bestSeason: ["Spring", "garbage", "YearRound"],
            accessLevel: nil, entranceFee: nil, crowdLevel: nil,
            gearRecommendations: nil, compositionHints: nil,
            permitRequired: nil, droneAllowed: nil, tripodAllowed: nil,
            createdAt: Date()
        )
        #expect(review.times == [.sunrise, .blueHour])
        #expect(review.seasons == [.spring, .yearRound])
    }
}
