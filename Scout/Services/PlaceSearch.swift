import MapKit
import Observation

/// A place resolved from an autocomplete suggestion: its display name and the
/// `SpotRegion` query window to drive `GET /spots`.
nonisolated struct ResolvedPlace: Equatable {
    let name: String
    let region: SpotRegion
}

/// Native place autocomplete for the search screen. Wraps `MKLocalSearchCompleter`
/// for live suggestions as the user types, and `MKLocalSearch` to resolve a tapped
/// suggestion into coordinates + a bounding region. No backend, no API key.
///
/// Mirrors `LocationManager`: an `@Observable @MainActor` delegate wrapper whose
/// callbacks arrive on the main thread and hop back on to mutate observable state.
@Observable
@MainActor
final class PlaceSearch: NSObject, MKLocalSearchCompleterDelegate {
    private(set) var completions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    /// Cap suggestions to the most relevant few — MapKit returns dozens of
    /// same-named places worldwide; if the top hits aren't it, the user refines.
    private let maxResults = 5

    /// Width of the relevance-bias region around the user (~500 km), wide enough
    /// to favor the user's country/area without hiding distant matches.
    private let biasSpanMeters: CLLocationDistance = 500_000

    override init() {
        super.init()
        completer.delegate = self
        // Cities, admin areas (states/provinces), and countries only — no POIs,
        // street addresses, neighborhoods, or postal codes.
        completer.resultTypes = [.address]
        completer.addressFilter = MKAddressFilter(
            including: [.locality, .administrativeArea, .country]
        )
    }

    /// Biases suggestion relevance toward the user's location so the nearest
    /// same-named place (e.g. San Francisco, CA) ranks above distant ones. This
    /// is a soft hint — distant places are still findable by typing more.
    func bias(around coordinate: CLLocationCoordinate2D) {
        completer.region = MKCoordinateRegion(center: coordinate,
                                              latitudinalMeters: biasSpanMeters,
                                              longitudinalMeters: biasSpanMeters)
    }

    /// Feeds the current query to the completer. Blank input clears results.
    func updateQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completions = []
            completer.queryFragment = ""
            return
        }
        completer.queryFragment = trimmed
    }

    /// Resolves a suggestion to a concrete place (coordinate → bounding region).
    func resolve(_ completion: MKLocalSearchCompletion) async throws -> ResolvedPlace {
        let request = MKLocalSearch.Request(completion: completion)
        let response = try await MKLocalSearch(request: request).start()
        return ResolvedPlace(name: completion.title,
                             region: response.boundingRegion.spotRegion)
    }

    // MARK: - MKLocalSearchCompleterDelegate

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            completions = Array(completer.results.prefix(maxResults))
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            completions = []
        }
    }
}
