#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-along

extension LineString {

    /// Returns a coordinate at a specified distance along the line.
    ///
    /// - Parameter distance: The distance along the line, in meters.
    ///
    /// - Returns: A *Coordinate3D* *distance* meters along the line.
    public func coordinateAlong(distance: CLLocationDistance) -> Coordinate3D {
        var travelled: CLLocationDistance = 0.0

        for (index, coordinate) in coordinates.enumerated() {
            if distance >= travelled, index == coordinates.count - 1 {
                break
            }

            if travelled >= distance {
                let overshot: CLLocationDistance = distance - travelled
                if overshot == 0.0 {
                    return coordinate
                }

                let direction: CLLocationDirection = coordinate.bearing(to: coordinates[index - 1]) - 180.0
                let interpolated: Coordinate3D = coordinate.destination(distance: overshot, bearing: direction)
                return interpolated
            }
            else {
                travelled += coordinate.distance(from: coordinates[index + 1])
            }
        }

        return coordinates[coordinates.count - 1]
    }

    /// Returns a `Point` at a specified distance along the line.
    ///
    /// - Parameter distance: The distance along the line, in meters
    ///
    /// - Returns: A *Point* *distance* meters along the line.
    public func pointAlong(distance: CLLocationDistance) -> Point {
        Point(coordinateAlong(distance: distance))
    }

    /// Returns the distance in meters from the start of the line to the nearest
    /// point on the line from the given coordinate.
    ///
    /// - Parameter coordinate: A coordinate near the line
    /// - Parameter tolerance: Maximum distance from the line in meters (default `1.0`).
    /// - Returns: The distance along the line in meters, or `nil` if the coordinate
    ///   is further than `tolerance` from the line.
    public func distanceAlong(
        to coordinate: Coordinate3D,
        tolerance: CLLocationDistance = 1.0
    ) -> CLLocationDistance? {
        guard coordinates.count >= 2 else { return nil }

        let projected = coordinate.projected(to: projection)
        var bestDistance = Double.greatestFiniteMagnitude
        var bestSegment: (index: Int, foot: Coordinate3D)? = nil

        for (i, segment) in lineSegments.enumerated() {
            guard let foot = segment.perpendicularFoot(from: projected, clampToEnds: true) else { continue }
            let d = projected.distance(from: foot)
            if d < bestDistance {
                bestDistance = d
                bestSegment = (i, foot)
            }
        }

        guard let (segIndex, foot) = bestSegment,
              bestDistance < tolerance
        else { return nil }

        var travelled: CLLocationDistance = 0.0
        for i in 0..<segIndex {
            travelled += coordinates[i].distance(from: coordinates[i + 1])
        }

        travelled += coordinates[segIndex].distance(from: foot)
        return travelled
    }

}
