#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-rhumb-distance

extension Coordinate3D {

    /// Calculates the distance along a rhumb line between two coordinates, in meters.
    ///
    /// - Parameter other: The other coordinate
    public func rhumbDistance(from other: Coordinate3D) -> CLLocationDistance {
        switch projection {
        case .epsg4326:
            return _rhumbDistance(from: other.projected(to: .epsg4326))
        case .epsg3857:
            // TODO: This can be improved
            return projected(to: .epsg4326)._rhumbDistance(from: other.projected(to: .epsg4326))
        case .noSRID:
            // TODO
            return Double.infinity
        }
    }

    private func _rhumbDistance(from other: Coordinate3D) -> CLLocationDistance {
        var otherLongitude = other.longitude

        // compensate the crossing of the 180th meridian (https://macwright.org/2016/09/26/the-180th-meridian.html)
        // solution from https://github.com/mapbox/mapbox-gl-js/issues/3250#issuecomment-294887678
        if longitude - self.longitude > 180 {
            otherLongitude -= 360.0
        }
        else if self.longitude - longitude > 180.0 {
            otherLongitude += 360.0
        }

        return Coordinate3D.calculateRhumbDistance(
            from: self,
            to: Coordinate3D(latitude: other.latitude, longitude: otherLongitude))
    }

    // Returns the distance travelling from ‘this’ point to destination point along a rhumb line.
    // Adapted from Geodesy: https://github.com/chrisveness/geodesy/blob/master/latlon-spherical.js
    private static func calculateRhumbDistance(
        from: Coordinate3D,
        to: Coordinate3D)
        -> CLLocationDistance
    {
        let radius: Double = GISTool.earthRadius

        let phi1: Double = from.latitude * .pi / 180.0
        let phi2: Double = to.latitude * .pi / 180
        let deltaPhi: Double = phi2 - phi1
        var deltaLambda: Double = abs(to.longitude - from.longitude) * .pi / 180.0

        // If dLon over 180° take shorter rhumb line across the anti-meridian
        if deltaLambda > .pi {
            deltaLambda -= 2.0 * .pi
        }

        // on Mercator projection, longitude distances shrink by latitude; q is the 'stretch factor'
        // q becomes ill-conditioned along E-W line (0/0); use empirical tolerance to avoid it
        let deltaPsi: Double = log(tan(phi2 / 2.0 + .pi / 4.0) / tan(phi1 / 2.0 + .pi / 4.0))
        let q: Double = (abs(deltaPsi) > 10e-12
            ? deltaPhi / deltaPsi
            : cos(phi1))

        // distance is pythagoras on 'stretched' Mercator projection
        let delta: Double = sqrt(deltaPhi * deltaPhi + q * q * deltaLambda * deltaLambda) // angular distance in radians
        let distance: CLLocationDistance = delta * radius

        return distance
    }

}

extension Point {

    /// Calculates the distance between two points, in meters.
    ///
    /// - Parameter other: The other point
    public func rhumbDistance(from other: Point) -> CLLocationDistance {
        coordinate.rhumbDistance(from: other.coordinate)
    }

}
