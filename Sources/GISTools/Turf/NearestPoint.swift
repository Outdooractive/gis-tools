#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-nearest-point

extension BoundingBox {

    /// Takes a reference coordinate and returns the coordinate from the reveiver closest to the reference.
    /// This calculation is geodesic.
    ///
    /// - Parameter other: The other coordinate
    public func nearestCoordinate(
        from other: Coordinate3D)
        -> (coordinate: Coordinate3D, distance: CLLocationDistance)?
    {
        self.boundingBoxPolygon.nearestCoordinate(from: other)
    }

    /// Takes a reference point and returns the point from the reveiver closest to the reference.
    /// This calculation is geodesic.
    ///
    /// - Parameter other: The other point
    public func nearestPoint(
        from other: Point)
        -> (point: Point, distance: CLLocationDistance)?
    {
        self.boundingBoxPolygon.nearestPoint(from: other)
    }

}

extension GeoJson {

    /// Takes a reference coordinate and returns the coordinate from the reveiver closest to the reference.
    /// This calculation is geodesic.
    ///
    /// - Parameter other: The other coordinate
    public func nearestCoordinate(
        from other: Coordinate3D)
        -> (coordinate: Coordinate3D, distance: CLLocationDistance)?
    {
        let other = other.projected(to: projection)

        let allCordinates = self.allCoordinates
        guard !allCordinates.isEmpty else { return nil }

        var bestCoordinate: Coordinate3D = allCordinates[0]
        var bestDistance: CLLocationDistance = bestCoordinate.distance(from: other)

        for coordinate in allCordinates {
            let distance = coordinate.distance(from: other)
            if distance < bestDistance {
                bestDistance = distance
                bestCoordinate = coordinate
            }
        }

        return (coordinate: bestCoordinate, distance: bestDistance)
    }

    /// Takes a reference point and returns the point from the reveiver closest to the reference.
    /// This calculation is geodesic.
    ///
    /// - Parameter other: The other point
    public func nearestPoint(
        from other: Point)
        -> (point: Point, distance: CLLocationDistance)?
    {
        if let nearest = nearestCoordinate(from: other.coordinate) {
            return (point: Point(nearest.coordinate), distance: nearest.distance)
        }

        return nil
    }

}
