#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Uses a different algorithm than https://github.com/Turfjs/turf/tree/master/packages/turf-nearest-point-on-line

extension LineSegment {

    /// Returns the foot of the perpendicular of the coordinate to the segment.
    public func perpendicularFoot(
        coordinate: Coordinate3D,
        clampToEnds: Bool = false)
        -> Coordinate3D?
    {
        let coordinate = coordinate.projected(to: projection)

        let squareLineDistance: Double = pow(first.latitude - second.latitude, 2) + pow(first.longitude - second.longitude, 2)

        // avoid inaccuracy for too short distances, as the square line distance is taken as divisor
        if squareLineDistance == 0.0
            || first.distance(from: second) < 1.0
        {
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
    public func nearestCoordinateOnSegment(
        from other: Coordinate3D)
        -> (coordinate: Coordinate3D, distance: CLLocationDistance)
    {
        guard let foot: Coordinate3D = perpendicularFoot(coordinate: other, clampToEnds: true) else {
            return (coordinate: first, distance: 0.0)
        }
        let footDistance: CLLocationDistance = other.distance(from: foot)

        return (coordinate: foot, distance: footDistance)
    }

}

extension LineString {

    /// Calculates the closest coordinate on the line.
    public func nearestCoordinateOnLine(
        from other: Coordinate3D)
        -> (coordinate: Coordinate3D, index: Int, distance: CLLocationDistance)?
    {
        guard coordinates.count >= 2 else { return nil }

        let other = other.projected(to: projection)

        var bestCoordinate: Coordinate3D = coordinates[0]
        var bestDistance: CLLocationDistance = .greatestFiniteMagnitude
        var bestIndex: Int = -1

        for (index, segment) in lineSegments.enumerated() {
            guard let foot: Coordinate3D = segment.perpendicularFoot(coordinate: other, clampToEnds: true) else {
                continue
            }
            let footDistance: CLLocationDistance = other.distance(from: foot)

            if footDistance < bestDistance {
                bestCoordinate = foot
                bestDistance = footDistance
                bestIndex = index
            }

            // TODO: Good enough? Might not be accurate enough for all use cases
            if bestDistance < 1.0 {
                break
            }
        }

        if let lastCoordinate = lastCoordinate {
            let lastDistance = lastCoordinate.distance(from: other)

            if lastDistance <= bestDistance {
                bestCoordinate = lastCoordinate
                bestDistance = lastDistance
                bestIndex = coordinates.count - 1
            }
        }

        return (coordinate: bestCoordinate, index: bestIndex, distance: bestDistance)
    }

    /// Calculates the closest *Point* on the line.
    public func nearestPointOnLine(
        from other: Point)
        -> (point: Point, index: Int, distance: CLLocationDistance)?
    {
        guard let result = nearestCoordinateOnLine(from: other.coordinate) else { return nil }
        return (point: Point(result.coordinate), index: result.index, distance: result.distance)
    }

}

extension Feature {

    /// Calculates the closest coordinate on the line.
    public func nearestCoordinateOnLine(
        from other: Coordinate3D)
        -> (coordinate: Coordinate3D, index: Int, distance: CLLocationDistance)?
    {
        guard let lineString = geometry as? LineString else { return nil }
        return lineString.nearestCoordinateOnLine(from: other)
    }

    /// Calculates the closest *Point* on the line.
    public func nearestPointOnLine(
        from other: Point)
        -> (point: Point, index: Int, distance: CLLocationDistance)?
    {
        guard let lineString = geometry as? LineString else { return nil }
        return lineString.nearestPointOnLine(from: other)
    }

}
