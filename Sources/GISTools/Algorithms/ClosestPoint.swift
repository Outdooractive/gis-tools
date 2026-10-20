#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - Closest point

extension GeoJson {

    /// Returns the point on the receiver closest to the other geometry.
    ///
    /// This follows OGC/PostGIS `ST_ClosestPoint`: the result is a point on the
    /// receiver, not necessarily a vertex. If the geometries intersect, any
    /// intersection point is returned. The result is expressed in the
    /// receiver's projection.
    ///
    /// - Parameter other: The geometry to find the closest point to
    /// - Returns: A point on the receiver, or `nil` if either geometry has no
    ///   coordinates
    public func closestPoint(to other: GeoJson) -> Point? {
        // An intersection is always at distance zero and is a valid closest
        // point for both geometries.
        if let intersection = intersections(with: other).first {
            return intersection
        }

        let target = other.projected(to: projection)
        let targetCoordinates = target.allCoordinates
        guard targetCoordinates.isNotEmpty else { return nil }

        var candidates = allCoordinates

        // Project every target vertex onto the receiver. This covers the case
        // where the closest point is in the interior of a receiver segment.
        for coordinate in targetCoordinates {
            if let nearest = nearestCoordinateOnFeature(from: coordinate) {
                candidates.append(nearest.coordinate)
            }
        }

        var bestCoordinate: Coordinate3D?
        var bestDistance: CLLocationDistance = .greatestFiniteMagnitude

        // Receiver vertices are candidates too: the closest pair of two
        // non-intersecting segments includes an endpoint of one of them.
        for candidate in candidates {
            guard let nearest = target.nearestCoordinateOnFeature(from: candidate) else {
                continue
            }

            let distance = candidate.distance(from: nearest.coordinate)
            if distance < bestDistance {
                bestDistance = distance
                bestCoordinate = candidate
            }
        }

        guard let bestCoordinate else { return nil }
        return Point(bestCoordinate)
    }

}
