#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-rhumb-bearing

extension Coordinate3D {

    /// Finds the bearing angle between the receiver and another coordinate along a Rhumb line,
    /// i.e. the angle measured in degrees start the north line (0 degrees).
    ///
    /// - Parameters:
    ///    - other: The other coordinate
    ///    - final: Calculated the final bearing if *true* (default *false*)
    public func rhumbBearing(
        to other: Coordinate3D,
        final: Bool = false)
        -> CLLocationDegrees
    {
        switch projection {
        case .epsg4326:
            return _rhumbBearing(to: other.projected(to: .epsg4326), final: final)
        case .epsg3857:
            return projected(to: .epsg4326)._rhumbBearing(to: other.projected(to: .epsg4326), final: final)
        case .noSRID:
            // TODO
            return Double.infinity
        }
    }

    private func _rhumbBearing(
        to other: Coordinate3D,
        final: Bool = false)
        -> CLLocationDegrees
    {
        var bearing: CLLocationDegrees
        if final {
            bearing = Coordinate3D.calculateFinalRhumbBearing(from: other, to: self)
        }
        else {
            bearing = Coordinate3D.calculateFinalRhumbBearing(from: self, to: other)
        }

        return bearing > 180.0
            ? -(360.0 - bearing)
            : bearing
    }

    private static func calculateFinalRhumbBearing(
        from: Coordinate3D,
        to: Coordinate3D)
        -> CLLocationDegrees
    {
        let phi1 = from.latitude.degreesToRadians
        let phi2 = to.latitude.degreesToRadians
        var deltaLambda = (to.longitude - from.longitude).degreesToRadians

        // If deltaLambda is over 180° take shorter rhumb line across the anti-meridian
        if deltaLambda > .pi {
            deltaLambda -= (2.0 * .pi)
        }
        if deltaLambda < -.pi {
            deltaLambda += (2.0 * .pi)
        }

        let deltaPsi = log(tan(phi2 / 2.0 + .pi / 4.0) / tan(phi1 / 2.0 + .pi / 4.0))
        let theta = atan2(deltaLambda, deltaPsi)

        return (theta.radiansToDegrees + 360.0).truncatingRemainder(dividingBy: 360.0)
    }

}

extension Point {

    /// Finds the bearing angle between the receiver and another coordinate along a Rhumb line,
    /// i.e. the angle measured in degrees start the north line (0 degrees).
    ///
    /// - Parameters:
    ///    - other: The other coordinate
    ///    - final: Calculated the final bearing if *true* (default *false*)
    public func rhumbBearing(
        to other: Point,
        final: Bool = false)
        -> CLLocationDegrees
    {
        self.coordinate.rhumbBearing(to: other.coordinate, final: final)
    }

}
