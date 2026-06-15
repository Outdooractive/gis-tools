#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-line-arc

extension Coordinate3D {

    /// Creates a circular arc, of a circle of the given radius and center point,
    /// between bearing1 and bearing2.
    /// 0 bearing is North of center point, positive clockwise.
    ///
    /// - Parameter radius: The radius of the circle forming the arc, in meters
    /// - Parameter bearing1: The angle of the first radius of the arc, in decimal degrees
    /// - Parameter bearing2: The angle of the second radius of the arc, in decimal degrees
    /// - Parameter steps: The number of steps (default 64)
    ///
    /// - Returns: A `LineString` representing the arc, or `nil` if `radius ≤ 0` or `steps ≤ 1`.
    public func lineArc(
        radius: CLLocationDistance,
        bearing1: CLLocationDegrees,
        bearing2: CLLocationDegrees,
        steps: Int = 64
    ) -> LineString? {
        guard radius > 0.0, steps > 1 else { return nil }

        let angle1 = normalizeAngle(bearing1)
        let angle2 = normalizeAngle(bearing2)

        if angle1 == angle2 {
            guard let polygon = self.circle(radius: radius, steps: steps),
                  let coordinates = polygon.coordinates.first
            else { return nil }
            return LineString(coordinates)
        }

        let arcStartDegree = angle1
        let arcEndDegree = (angle1 < angle2
            ? angle2
            : angle2 + 360.0)

        let delta = 360.0 / Double(steps)
        var coordinates: [Coordinate3D] = []

        var bearing = arcStartDegree
        while bearing < arcEndDegree {
            coordinates.append(self.destination(distance: radius, bearing: bearing))
            bearing += delta
        }
        if bearing > arcEndDegree {
            coordinates.append(self.destination(distance: radius, bearing: arcEndDegree))
        }

        return LineString(coordinates)
    }

    /// Normalizes an angle to the range 0..<360 degrees.
    private func normalizeAngle(_ alpha: CLLocationDegrees) -> CLLocationDegrees {
        var beta = alpha.remainder(dividingBy: 360.0)
        if beta < 0.0 {
            beta += 360.0
        }
        return beta
    }

}

extension Point {

    /// Creates a circular arc, of a circle of the given radius and center point,
    /// between bearing1 and bearing2.
    /// 0 bearing is North of center point, positive clockwise.
    ///
    /// - Parameter radius: The radius of the circle forming the arc, in meters
    /// - Parameter bearing1: The angle of the first radius of the arc, in decimal degrees
    /// - Parameter bearing2: The angle of the second radius of the arc, in decimal degrees
    /// - Parameter steps: The number of steps (default 64)
    ///
    /// - Returns: A `LineString` representing the arc, or `nil` if `radius ≤ 0` or `steps ≤ 1`.
    public func lineArc(
        radius: CLLocationDistance,
        bearing1: CLLocationDegrees,
        bearing2: CLLocationDegrees,
        steps: Int = 64
    ) -> LineString? {
        coordinate.lineArc(radius: radius, bearing1: bearing1, bearing2: bearing2, steps: steps)
    }

}
