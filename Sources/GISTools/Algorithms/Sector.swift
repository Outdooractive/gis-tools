#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-sector

extension Coordinate3D {

    /// Calculates the sector polygon of a circle of the given radius and center
    /// point, between bearing1 and bearing2.
    ///
    /// 0 bearing is North of the center point, positive clockwise.
    ///
    /// - Parameter radius: The radius of the circle forming the sector, in meters
    /// - Parameter bearing1: The start bearing, in decimal degrees
    /// - Parameter bearing2: The end bearing, in decimal degrees
    /// - Parameter steps: The number of steps for the arc (default 64)
    ///
    /// - Returns: A `Polygon` representing the sector, or `nil` if `radius ≤ 0` or `steps ≤ 1`.
    public func sector(
        radius: CLLocationDistance,
        bearing1: CLLocationDegrees,
        bearing2: CLLocationDegrees,
        steps: Int = 64
    ) -> Polygon? {
        Point(self).sector(radius: radius, bearing1: bearing1, bearing2: bearing2, steps: steps)
    }

}

extension Point {

    /// Calculates the sector polygon of a circle of the given radius and center
    /// point, between bearing1 and bearing2.
    ///
    /// 0 bearing is North of the center point, positive clockwise.
    ///
    /// - Parameter radius: The radius of the circle forming the sector, in meters
    /// - Parameter bearing1: The start bearing, in decimal degrees
    /// - Parameter bearing2: The end bearing, in decimal degrees
    /// - Parameter steps: The number of steps for the arc (default 64)
    ///
    /// - Returns: A `Polygon` representing the sector, or `nil` if `radius ≤ 0` or `steps ≤ 1`.
    public func sector(
        radius: CLLocationDistance,
        bearing1: CLLocationDegrees,
        bearing2: CLLocationDegrees,
        steps: Int = 64
    ) -> Polygon? {
        guard radius > 0.0, steps > 1 else { return nil }

        let arc = self.lineArc(
            radius: radius,
            bearing1: bearing1,
            bearing2: bearing2,
            steps: steps)

        guard let arcCoordinates = arc?.coordinates else { return nil }

        var ring: [Coordinate3D] = [self.coordinate]
        ring.append(contentsOf: arcCoordinates)
        ring.append(self.coordinate)

        return Polygon([ring])
    }

}
