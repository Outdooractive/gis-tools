#if !os(Linux)
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
    /// - Parameter distance: The distance along the line
    ///
    /// - Returns: A *Point* *distance* meters along the line.
    public func pointAlong(distance: CLLocationDistance) -> Point {
        Point(coordinateAlong(distance: distance))
    }

}
