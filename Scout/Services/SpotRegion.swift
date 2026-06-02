import Foundation

/// A geographic query window for `/spots`: a center point plus a search radius.
///
/// Kept Foundation-only (no MapKit) so it can live in the service protocol.
/// `MapViewModel` converts an `MKCoordinateRegion` into one of these.
nonisolated struct SpotRegion: Equatable {
    var latitude: Double
    var longitude: Double
    var radiusKm: Double
}
