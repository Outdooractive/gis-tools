#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-circle

extension Point {

    /// Calculates the circle polygon around a point.
    ///
    /// - Parameters:
    ///    - radius: The radius of the circle, in meters
    ///    - steps: The number of steps (default 64)
    public func circle(
        radius: CLLocationDistance,
        steps: Int = 64)
        -> Polygon?
    {
        guard radius > 0.0, steps > 1 else { return nil }

        let center = self.coordinate
        var coordinates: [Coordinate3D] = []
        for i in 0 ..< steps {
            coordinates.append(center.destination(distance: radius, bearing: Double(i) * -360.0 / Double(steps)))
        }
        coordinates.append(coordinates[0])

        return Polygon([coordinates])
    }

}
