#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-rhumb-destination

extension Coordinate3D {

    /// Returns the destination coordinate having travelled the given distance along a Rhumb line from the
    /// origin with the given bearing.
    ///
    /// - Parameters:
    ///    - distance: The distance from the receiver, in meters
    ///    - bearing: The direction, ranging from -180 to 180 degrees from north
    public func rhumbDestination(
        distance: CLLocationDistance,
        bearing: CLLocationDegrees)
        -> Coordinate3D
    {
        switch projection {
        case .epsg4326:
            return _rhumbDestination(distance: distance, bearing: bearing)
        case .epsg3857:
            return projected(to: .epsg4326)._rhumbDestination(distance: distance, bearing: bearing).projected(to: .epsg3857)
        case .noSRID:
            return self // Ignore
        }
    }

    private func _rhumbDestination(
        distance: CLLocationDistance,
        bearing: CLLocationDegrees)
        -> Coordinate3D
    {
        let destination = Coordinate3D.calculateRhumbDestination(from: self, distance: distance, bearing: bearing)

        // compensate the crossing of the 180th meridian (https://macwright.org/2016/09/26/the-180th-meridian.html)
        // solution from https://github.com/mapbox/mapbox-gl-js/issues/3250#issuecomment-294887678

        var longitude: CLLocationDegrees = destination.longitude

        if longitude - self.longitude > 180 {
            longitude -= 360.0
        }
        else if self.longitude - longitude > 180 {
            longitude += 360.0
        }

        return Coordinate3D(latitude: destination.latitude, longitude: longitude)
    }

    // Returns the destination point having travelled along a rhumb line from origin point the given
    // distance with the given bearing.
    // Adapted from Geodesy: http://www.movable-type.co.uk/scripts/latlong.html#rhumblines
    private static func calculateRhumbDestination(
        from: Coordinate3D,
        distance: CLLocationDistance,
        bearing: CLLocationDegrees)
        -> Coordinate3D
    {
        let radius: Double = GISTool.earthRadius

        let delta: CLLocationDistance = distance / radius
        let lambda1: CLLocationDegrees = from.longitude * .pi / 180.0
        let phi1: Double = from.latitude.degreesToRadians
        let theta: Double = bearing.degreesToRadians

        let deltaPhi: Double = delta * cos(theta)
        var phi2: Double = phi1 + deltaPhi

        // check for some daft bugger going past the pole, normalise latitude if so
        if abs(phi2) > .pi / 2.0 {
            if phi2 > 0 {
                phi2 = .pi - phi2
            }
            else {
                phi2 = -.pi - phi2
            }
        }

        let deltaPsi: Double = log(tan(phi2 / 2.0 + .pi / 4.0) / tan(phi1 / 2.0 + .pi / 4.0))

        // E-W course becomes ill-conditioned with 0/0
        let q: Double = (abs(deltaPsi) > 10e-12
            ? deltaPhi / deltaPsi
            : cos(phi1))

        let deltaLambda: Double = delta * sin(theta) / q
        let lambda2: Double = lambda1 + deltaLambda

        let latitude: CLLocationDegrees = phi2 * 180.0 / .pi
        let longitude: CLLocationDegrees = ((lambda2 * 180.0 / .pi) + 540.0).truncatingRemainder(dividingBy: 360.0) - 180.0

        return Coordinate3D(latitude: latitude, longitude: longitude)
    }

}

extension Point {

    /// Returns the destination coordinate having travelled the given distance along a Rhumb line from the
    /// origin with the given bearing.
    ///
    /// - Parameters:
    ///    - distance: The distance from the receiver, in meters
    ///    - bearing: The direction, ranging from -180 to 180 degrees from north
    public func rhumbDestination(
        distance: CLLocationDistance,
        bearing: CLLocationDegrees)
        -> Point
    {
        Point(coordinate.rhumbDestination(distance: distance, bearing: bearing))
    }

}
