#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-destination

extension Coordinate3D {

    /// Calculates the location of a destination point given a distance in meters and a bearing in degrees.
    /// This uses the Haversine formula to account for global curvature.
    ///
    /// - Parameters:
    ///    - distance: The distance from the receiver, in meters
    ///    - bearing: The direction, ranging from -180 to 180
    public func destination(
        distance: CLLocationDistance,
        bearing: CLLocationDegrees)
        -> Coordinate3D
    {
        guard let distanceRadians = distance.lengthToRadians(unit: .meters) else { return self }

        let longitude1 = longitude.degreesToRadians()
        let latitude1 = latitude.degreesToRadians()
        let bearingRadians = bearing.degreesToRadians()

        let latitude2 = asin(sin(latitude1) * cos(distanceRadians) + cos(latitude1) * sin(distanceRadians) * cos(bearingRadians))
        let longitude2 = longitude1 + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(latitude1), cos(distanceRadians) - sin(latitude1) * sin(latitude2))

        return Coordinate3D(
            latitude: latitude2.radiansToDegrees(),
            longitude: longitude2.radiansToDegrees())
    }

}

extension Point {

    /// Calculates the location of a destination point given a distance in meters and a bearing in degrees.
    /// This uses the Haversine formula to account for global curvature.
    ///
    /// - Parameters:
    ///    - distance: The distance from the receiver, in meters
    ///    - bearing: The direction, ranging from -180 to 180
    public func destination(
        distance: CLLocationDistance,
        bearing: CLLocationDegrees)
        -> Point
    {
        return Point(coordinate.destination(distance: distance, bearing: bearing))
    }

}
