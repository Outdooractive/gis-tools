#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-ellipse

extension Coordinate3D {

    /// Calculates an elliptical polygon around a coordinate.
    ///
    /// - Parameter xSemiAxis: The semi-axis length along the x-axis (east-west direction) in meters.
    /// - Parameter ySemiAxis: The semi-axis length along the y-axis (north-south direction) in meters.
    /// - Parameter steps: The number of steps (default `64`).
    /// - Parameter angle: The rotation angle of the ellipse in degrees (default `0.0`).
    ///
    /// - Returns: The ellipse as a ``Polygon``, or `nil` if either semi-axis is zero or steps is less than 2.
    public func ellipse(
        xSemiAxis: CLLocationDistance,
        ySemiAxis: CLLocationDistance,
        steps: Int = 64,
        angle: CLLocationDegrees = 0.0
    ) -> Polygon? {
        guard xSemiAxis > 0.0,
              ySemiAxis > 0.0,
              steps > 1
        else { return nil }

        let angleRad = angle.degreesToRadians
        var coordinates: [Coordinate3D] = []

        for i in 0 ..< steps {
            let stepAngle = Double(i) * -2.0 * .pi / Double(steps)
            let x = xSemiAxis * cos(stepAngle)
            let y = ySemiAxis * sin(stepAngle)

            let xrot = x * cos(angleRad) - y * sin(angleRad)
            let yrot = x * sin(angleRad) + y * cos(angleRad)

            let bearing = atan2(xrot, yrot).radiansToDegrees
            let distance = sqrt(xrot * xrot + yrot * yrot)

            coordinates.append(destination(distance: distance, bearing: bearing))
        }
        coordinates.append(coordinates[0])

        return Polygon([coordinates])
    }

}

extension Point {

    /// Calculates an elliptical polygon around a point.
    ///
    /// - Parameter xSemiAxis: The semi-axis length along the x-axis (east-west direction) in meters.
    /// - Parameter ySemiAxis: The semi-axis length along the y-axis (north-south direction) in meters.
    /// - Parameter steps: The number of steps (default `64`).
    /// - Parameter angle: The rotation angle of the ellipse in degrees (default `0.0`).
    ///
    /// - Returns: The ellipse as a ``Polygon``, or `nil` if either semi-axis is zero or steps is less than 2.
    public func ellipse(
        xSemiAxis: CLLocationDistance,
        ySemiAxis: CLLocationDistance,
        steps: Int = 64,
        angle: CLLocationDegrees = 0.0
    ) -> Polygon? {
        coordinate.ellipse(
            xSemiAxis: xSemiAxis,
            ySemiAxis: ySemiAxis,
            steps: steps,
            angle: angle)
    }

}
