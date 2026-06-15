#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Uses a different algorithm than https://github.com/Turfjs/turf/tree/master/packages/turf-nearest-point-on-line

extension LineSegment {

    /// Returns the foot of the perpendicular of the coordinate to the segment.
    public func perpendicularFoot(
        from coordinate: Coordinate3D,
        clampToEnds: Bool = false
    ) -> Coordinate3D? {
        let coordinate = coordinate.projected(to: projection)

        let squareLineDistance: Double = pow(first.latitude - second.latitude, 2) + pow(first.longitude - second.longitude, 2)

        // Numerical stability: avoid division by a near-zero squared distance.
        // Use the geodesic distance (always in meters) for a projection-independent
        // threshold. Segments shorter than 1 m are degenerate for perpendicular projection.
        if squareLineDistance <= 0.0 || first.distance(from: second) < 1.0 {
            return first
        }

        let weight = ((coordinate.latitude - first.latitude) * (second.latitude - first.latitude)
            + (coordinate.longitude - first.longitude) * (second.longitude - first.longitude))
            / squareLineDistance

        if weight <= 0.0 {
            return clampToEnds ? first : nil
        }

        if weight >= 1.0 {
            return clampToEnds ? second : nil
        }

        let latitude: CLLocationDegrees = first.latitude + weight * (second.latitude - first.latitude)
        let longitude: CLLocationDegrees = first.longitude + weight * (second.longitude - first.longitude)

        var altitude: CLLocationDistance?
        if let firstAltitude = first.altitude, let secondAltitude = second.altitude {
            altitude = firstAltitude + weight * (secondAltitude - firstAltitude)
        }

        return Coordinate3D(
            x: longitude,
            y: latitude,
            z: altitude,
            projection: projection)
    }

}

extension LineSegment {

    /// Calculates the closest coordinate on the segment.
    /// - Parameter from: The reference coordinate
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func nearestCoordinateOnSegment(
        from other: Coordinate3D,
        gridSize: Double? = nil
    ) -> (coordinate: Coordinate3D, distance: CLLocationDistance) {
        let segment = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let other = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other

        guard let foot: Coordinate3D = segment.perpendicularFoot(from: other, clampToEnds: true) else {
            return (coordinate: segment.first, distance: 0.0)
        }
        let footDistance: CLLocationDistance = other.distance(from: foot)

        return (coordinate: foot, distance: footDistance)
    }

}

extension LineString {

    /// Calculates the closest coordinate on the line.
    /// - Parameter from: The reference coordinate
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func nearestCoordinateOnLine(
        from other: Coordinate3D,
        gridSize: Double? = nil
    ) -> (coordinate: Coordinate3D, index: Int, distance: CLLocationDistance)? {
        let lineString = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let other = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other

        guard lineString.coordinates.count >= 2 else { return nil }

        let otherProjected = other.projected(to: lineString.projection)

        var bestCoordinate: Coordinate3D = lineString.coordinates[0]
        var bestDistance: CLLocationDistance = .greatestFiniteMagnitude
        var bestIndex: Int = -1

        for (index, segment) in lineString.lineSegments.enumerated() {
            guard let foot: Coordinate3D = segment.perpendicularFoot(from: otherProjected, clampToEnds: true) else {
                continue
            }
            let footDistance: CLLocationDistance = otherProjected.distance(from: foot)

            if footDistance < bestDistance {
                bestCoordinate = foot
                bestDistance = footDistance
                bestIndex = index
            }
        }

        if let lastCoordinate = lineString.lastCoordinate {
            let lastDistance = lastCoordinate.distance(from: otherProjected)

            if lastDistance <= bestDistance {
                bestCoordinate = lastCoordinate
                bestDistance = lastDistance
                bestIndex = lineString.coordinates.count - 1
            }
        }

        return (coordinate: bestCoordinate, index: bestIndex, distance: bestDistance)
    }

    /// Calculates the closest *Point* on the line.
    /// - Parameter from: The reference point
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func nearestPointOnLine(
        from other: Point,
        gridSize: Double? = nil
    ) -> (point: Point, index: Int, distance: CLLocationDistance)? {
        guard let result = nearestCoordinateOnLine(from: other.coordinate, gridSize: gridSize) else { return nil }
        return (point: Point(result.coordinate), index: result.index, distance: result.distance)
    }

}

extension Feature {

    /// Calculates the closest coordinate on the line.
    /// - Parameter from: The reference coordinate
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func nearestCoordinateOnLine(
        from other: Coordinate3D,
        gridSize: Double? = nil
    ) -> (coordinate: Coordinate3D, index: Int, distance: CLLocationDistance)? {
        let feature = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let other = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        guard let lineString = feature.geometry as? LineString else { return nil }
        return lineString.nearestCoordinateOnLine(from: other, gridSize: nil)
    }

    /// Calculates the closest *Point* on the line.
    /// - Parameter from: The reference point
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func nearestPointOnLine(
        from other: Point,
        gridSize: Double? = nil
    ) -> (point: Point, index: Int, distance: CLLocationDistance)? {
        guard let lineString = geometry as? LineString else { return nil }
        return lineString.nearestPointOnLine(from: other, gridSize: gridSize)
    }

}
