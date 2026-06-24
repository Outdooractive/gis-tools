#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-nearest-point-to-line

extension LineString {

    /// Returns the closest coordinate out of a collection of coordinates to a line.
    /// The returned coordinate has a distance property indicating its distance to the line.
    ///
    /// - Parameter coordinates: The coordinates to search.
    /// - Returns: The nearest coordinate and its distance to the line, or `nil` if empty.
    public func nearestCoordinate(
        from coordinates: [Coordinate3D]
    ) -> (coordinate: Coordinate3D, distance: CLLocationDistance)? {
        guard coordinates.isNotEmpty else { return nil }

        var bestDistance: CLLocationDistance = .greatestFiniteMagnitude
        var bestCoordinate: Coordinate3D = coordinates[0]

        for coordinate in coordinates {
            let distance = distanceFrom(coordinate: coordinate)

            if distance < bestDistance {
                bestDistance = distance
                bestCoordinate = coordinate
            }
        }

        return (coordinate: bestCoordinate, distance: bestDistance)
    }

    /// Returns the closest point out of a collection of points to a line.
    /// The returned point has a distance property indicating its distance to the line.
    ///
    /// - Parameter points: The points to search.
    /// - Returns: The nearest point and its distance to the line, or `nil` if empty.
    public func nearestPointAndDistance(
        from points: [Point]
    ) -> (point: Point, distance: CLLocationDistance)? {
        guard let bestCoordinateAndDistance = nearestCoordinate(from: points.map({ $0.coordinate })) else { return nil }
        return (point: Point(bestCoordinateAndDistance.coordinate), distance: bestCoordinateAndDistance.distance)
    }

}
