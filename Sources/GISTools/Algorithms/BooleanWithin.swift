#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    /// Returns `true` if the receiver is within the given distance of `other`.
    ///
    /// This is OGC `ST_DWithin`. The distance follows the same unit semantics
    /// as ``Coordinate3D/distance(to:)``: meters for geographic projections,
    /// native units for planar and noSRID coordinates.
    ///
    /// - Parameters:
    ///   - other: The other geometry
    ///   - distance: The maximum distance
    /// - Returns: `true` if the minimum distance is at most `distance`
    public func dWithin(_ other: GeoJson, distance: CLLocationDistance) -> Bool {
        guard distance >= 0.0 else { return false }
        guard let closest = closestPoint(to: other) else { return false }

        let target = other.projected(to: projection)
        guard let nearest = target.nearestCoordinateOnFeature(from: closest.coordinate) else {
            return false
        }

        return closest.coordinate.distance(to: nearest.coordinate) <= distance
    }

}
