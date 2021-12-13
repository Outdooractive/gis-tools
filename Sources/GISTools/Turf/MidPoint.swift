#if !os(Linux)
import CoreLocation
#endif

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-midpoint

extension Coordinate3D {

    /// Returns a coordinate midway between the receiver and the other coordinate.
    /// The midpoint is calculated geodesically, meaning the curvature of the earth is taken into account.
    ///
    /// - Parameter other: The other coordinate
    public func midpoint(to other: Coordinate3D) -> Coordinate3D {
        let distance = self.distance(from: other)
        let bearing = self.bearing(to: other)

        return destination(distance: distance / 2.0, bearing: bearing)
    }

}

extension Point {

    /// Returns a point midway between the receiver and the other *Point*.
    /// The midpoint is calculated geodesically, meaning the curvature of the earth is taken into account.
    ///
    /// - Parameter other: The other point
    public func midpoint(to other: Point) -> Point {
        Point(self.coordinate.midpoint(to: other.coordinate))
    }

}
