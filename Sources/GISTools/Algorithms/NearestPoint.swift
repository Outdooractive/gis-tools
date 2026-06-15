#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-nearest-point

extension BoundingBox {

    /// Takes a reference coordinate and returns the coordinate from the receiver closest to the reference.
    /// This calculation is geodesic.
    ///
    /// - Parameter other: The other coordinate
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    ///
    /// - Returns: The nearest coordinate and distance, or `nil`.
    public func nearestCoordinate(
        from other: Coordinate3D,
        gridSize: Double? = nil
    ) -> (coordinate: Coordinate3D, distance: CLLocationDistance)? {
        let snappedGeometry = gridSize.map { self.boundingBoxGeometry.snappedToGrid(tolerance: $0) } ?? self.boundingBoxGeometry
        let other = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        return snappedGeometry.nearestCoordinate(from: other)
    }

    /// Takes a reference point and returns the point from the receiver closest to the reference.
    /// This calculation is geodesic.
    ///
    /// - Parameter other: The other point
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    ///
    /// - Returns: The nearest point and distance, or `nil`.
    public func nearestPoint(
        from other: Point,
        gridSize: Double? = nil
    ) -> (point: Point, distance: CLLocationDistance)? {
        self.nearestCoordinate(from: other.coordinate, gridSize: gridSize).map {
            (point: Point($0.coordinate), distance: $0.distance)
        }
    }

}

extension GeoJson {

    /// Takes a reference coordinate and returns the coordinate from the receiver closest to the reference.
    /// This calculation is geodesic.
    ///
    /// - Parameter other: The other coordinate
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    ///
    /// - Returns: The nearest coordinate and distance, or `nil`.
    public func nearestCoordinate(
        from other: Coordinate3D,
        gridSize: Double? = nil
    ) -> (coordinate: Coordinate3D, distance: CLLocationDistance)? {
        let geoJson = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let other = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let otherProjected = other.projected(to: geoJson.projection)

        let allCoordinates = geoJson.allCoordinates
        guard !allCoordinates.isEmpty else { return nil }

        var bestCoordinate: Coordinate3D = allCoordinates[0]
        var bestDistance: CLLocationDistance = bestCoordinate.distance(from: otherProjected)

        for coordinate in allCoordinates {
            let distance = coordinate.distance(from: otherProjected)
            if distance < bestDistance {
                bestDistance = distance
                bestCoordinate = coordinate
            }
        }

        return (coordinate: bestCoordinate, distance: bestDistance)
    }

    /// Takes a reference point and returns the point from the receiver closest to the reference.
    /// This calculation is geodesic.
    ///
    /// - Parameter other: The other point
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    ///
    /// - Returns: The nearest point and distance, or `nil`.
    public func nearestPoint(
        from other: Point,
        gridSize: Double? = nil
    ) -> (point: Point, distance: CLLocationDistance)? {
        if let nearest = nearestCoordinate(from: other.coordinate, gridSize: gridSize) {
            return (point: Point(nearest.coordinate), distance: nearest.distance)
        }

        return nil
    }

}
