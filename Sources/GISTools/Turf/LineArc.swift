#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-line-arc

extension Point {

    /// Creates a circular arc, of a circle of the given radius and center point,
    /// between bearing1 and bearing2.
    /// 0 bearing is North of center point, positive clockwise.
    ///
    /// - Parameters:
    ///    - radius: The radius of the circle forming the arc, in meters
    ///    - bearing1: The angle of the first radius of the arc, in decimal degrees
    ///    - bearing2: The angle of the second radius of the arc, in decimal degrees
    ///    - steps: The number of steps (default 64)
    public func lineArc(
        radius: CLLocationDistance,
        bearing1: CLLocationDegrees,
        bearing2: CLLocationDegrees,
        steps: Int = 64)
        -> LineString?
    {
        guard radius > 0.0, steps > 1 else { return nil }

        let angle1 = Point.normalizeAngle(alfa: bearing1)
        let angle2 = Point.normalizeAngle(alfa: bearing2)

        if angle1 == angle2 {
            guard let polygon = circle(radius: radius, steps: steps),
                  let coordinates = polygon.coordinates.first
            else { return nil }
            return LineString(coordinates)
        }

        let arcStartDegree = angle1
        let arcEndDegree = (angle1 < angle2
            ? angle2
            : angle2 + 360.0)

        let center = self.coordinate
        var coordinates: [Coordinate3D] = []
        var index: Int = 0

        var alfa = arcStartDegree
        while alfa < arcEndDegree {
            coordinates.append(center.destination(distance: radius, bearing: alfa))
            index += 1
            alfa = arcStartDegree + Double(index) * 360.0 / Double(steps)
        }
        if (alfa > arcEndDegree) {
            coordinates.append(center.destination(distance: radius, bearing: arcEndDegree))
        }

        return LineString(coordinates)
    }

    private static func normalizeAngle(alfa: CLLocationDegrees) -> CLLocationDegrees {
        var beta = alfa.remainder(dividingBy: 360.0)
        if beta < 0.0 {
            beta += 360.0
        }
        return beta
    }

}
