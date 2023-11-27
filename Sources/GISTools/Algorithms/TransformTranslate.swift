#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-transform-translate

extension GeoJson {

    /// Moves the receiver for a specified distance along a Rhumb line on the provided direction angle.
    ///
    /// - Parameters:
    ///    - distance: The length of the motion, in meters
    ///    - direction: The direction of the motion, in decimal degrees from north, positive clockwise.
    ///    - zTranslation: The length of the vertical motion, in meters (defaults to 0.0)
    public func transformedTranslate(
        distance: CLLocationDistance,
        direction: CLLocationDegrees,
        zTranslation: CLLocationDistance = 0.0)
        -> Self
    {
        guard distance != 0.0 || zTranslation != 0.0 else { return self }

        let distance = abs(distance)
        let direction = abs(direction)

        return transformedCoordinates({ (coordinate) in
            var newCoordinate = coordinate.rhumbDestination(distance: distance, bearing: direction)

            if zTranslation != 0.0, let altitude = coordinate.altitude {
                newCoordinate.altitude = altitude + zTranslation
            }

            return newCoordinate
        })
    }

    /// Moves the receiver for a specified distance along a Rhumb line on the provided direction angle.
    ///
    /// - Parameters:
    ///    - distance: The length of the motion, in meters
    ///    - direction: The direction of the motion, in decimal degrees from north, positive clockwise.
    ///    - zTranslation: The length of the vertical motion, in meters (defaults to 0.0)
    public mutating func transformTranslate(
        distance: CLLocationDistance,
        direction: CLLocationDegrees,
        zTranslation: CLLocationDistance = 0.0)
    {
        self = transformedTranslate(
            distance: distance,
            direction: direction,
            zTranslation: zTranslation)
    }

}
