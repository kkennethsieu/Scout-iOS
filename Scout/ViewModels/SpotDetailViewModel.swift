import SwiftUI
import Observation

@Observable
@MainActor
final class SpotDetailViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - State

    let spotID: String
    private(set) var detail: SpotDetail?
    private(set) var reviews: [Review] = []
    private(set) var state: LoadState = .idle

    // MARK: - Dependencies

    private let service: SpotService

    init(spotID: String, service: SpotService = AppServices.spot) {
        self.spotID = spotID
        self.service = service
    }

    // MARK: - Actions

    func load() async {
        state = .loading
        do {
            async let detailTask = service.fetchSpotDetail(id: spotID)
            async let reviewsTask = service.fetchReviews(spotID: spotID)
            detail = try await detailTask
            reviews = try await reviewsTask
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Placeholder distance until CoreLocation is wired.
    var distanceText: String {
        guard let detail else { return "" }
        let miles = Double((abs(detail.id.hashValue) % 50) + 1) / 10.0
        return "\(miles.formatted(.number.precision(.fractionLength(1)))) mi"
    }

    var reviewCountText: String {
        guard let detail else { return "" }
        return "\(detail.reviewCount) people shared their view"
    }
}
