#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-destination

extension Coordinate3D {

    /// Calculates the location of a destination coordinate given a
    /// distance in meters and a bearing in degrees.
    /// This uses the Haversine formula to account for global curvature.
    ///
    /// - Parameter distance: The distance from the receiver, in meters
    /// - Parameter bearing: The direction, ranging from -180 to 180
    ///
    /// - Returns: The destination coordinate.
    public func destination(
        distance: CLLocationDistance,
        bearing: CLLocationDegrees
    ) -> Coordinate3D {
        switch projection {
        case .epsg4326:
            return _destination(distance: distance, bearing: bearing)
        case .epsg3857:
            return projected(to: .epsg4326)._destination(distance: distance, bearing: bearing).projected(to: .epsg3857)
        case .epsg4978:
            return projected(to: .epsg4326)._destination(distance: distance, bearing: bearing).projected(to: .epsg4978)
        case .noSRID:
            return self // Ignore
        }
    }

    private func _destination(
        distance: CLLocationDistance,
        bearing: CLLocationDegrees
    ) -> Coordinate3D {
        guard let distanceRadians = distance.lengthToRadians(unit: .meters) else { return self }

        let longitude1 = longitude.degreesToRadians
        let latitude1 = latitude.degreesToRadians
        let bearingRadians = bearing.degreesToRadians

        let latitude2 = asin(sin(latitude1) * cos(distanceRadians) + cos(latitude1) * sin(distanceRadians) * cos(bearingRadians))
        let longitude2 = longitude1 + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(latitude1), cos(distanceRadians) - sin(latitude1) * sin(latitude2))

        var normalizedLatitude = latitude2.radiansToDegrees
        var normalizedLongitude = longitude2 * 180.0 / .pi

        // Keep longitudes in the [-180, 180] range
        if longitude2 < -.pi {
            normalizedLongitude += 360.0
        }
        else if longitude2 > .pi {
            normalizedLongitude -= 360.0
        }

        if latitude2 < -(.pi / 2.0) {
            normalizedLatitude -= 90.0
        }
        else if latitude2 > (.pi / 2.0) {
            normalizedLatitude += 90.0
        }

        return Coordinate3D(
            latitude: normalizedLatitude,
            longitude: normalizedLongitude,
            altitude: self.altitude,
            m: self.m)
    }

    /// Calculates the location of a coordinate on a straight line between
    /// this and another coordinate given a distance in meters.
    ///
    /// - Parameter target: The other coordinate
    /// - Parameter distance: The distance from the receiver, in meters
    ///
    /// - Returns: The coordinate at the given distance along the line to the target.
    public func coordinate(
        inDirectionOf target: Coordinate3D,
        distance: CLLocationDistance
    ) -> Coordinate3D {
        destination(distance: distance, bearing: bearing(to: target))
    }

}

extension Point {

    /// Calculates the location of a destination point given a distance
    /// in meters and a bearing in degrees.
    /// This uses the Haversine formula to account for global curvature.
    ///
    /// - Parameter distance: The distance from the receiver, in meters
    /// - Parameter bearing: The direction, ranging from -180 to 180
    ///
    /// - Returns: The destination point.
    public func destination(
        distance: CLLocationDistance,
        bearing: CLLocationDegrees
    ) -> Point {
        Point(coordinate.destination(distance: distance, bearing: bearing))
    }

    /// Calculates the location of a point on a straight line between
    /// this and another point given a distance in meters.
    ///
    /// - Parameter target: The other point
    /// - Parameter distance: The distance from the receiver, in meters
    ///
    /// - Returns: The point at the given distance along the line to the target.
    public func point(
        inDirectionOf target: Point,
        distance: CLLocationDistance
    ) -> Point {
        destination(distance: distance, bearing: bearing(to: target))
    }

}
