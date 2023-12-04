#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-transform-rotate

extension GeoJson {

    /// Rotates any geojson Feature or Geometry of a specified angle, around its centroid or a given pivot point.
    /// All rotations follow the right-hand rule: https://en.wikipedia.org/wiki/Right-hand_rule.
    ///
    /// - Parameters:
    ///    - angle: The angle of the rotation (along the vertical axis), from north in decimal degrees, negative clockwise
    ///    - pivot: The coordinate around which the rotation will be performed (defaults to the centroid)
    public func transformedRotate(
        angle: CLLocationDegrees,
        pivot: Coordinate3D? = nil)
        -> Self
    {
        guard angle != 0.0 else { return self }

        guard let pivot = pivot?.projected(to: projection) ?? centroid?.coordinate else { return self }

        return transformedCoordinates({ (coordinate) in
            let initialAngle = pivot.rhumbBearing(to: coordinate)
            let finalAngle = initialAngle + angle
            let distance = pivot.rhumbDistance(from: coordinate)

            var newCoordinate = pivot.rhumbDestination(distance: distance, bearing: finalAngle)
            newCoordinate.altitude = coordinate.altitude
            return newCoordinate
        })
    }

    /// Rotates any geojson Feature or Geometry of a specified angle, around its centroid or a given pivot point.
    /// All rotations follow the right-hand rule: https://en.wikipedia.org/wiki/Right-hand_rule.
    ///
    /// - Parameters:
    ///    - angle: The angle of the rotation (along the vertical axis), from north in decimal degrees, negative clockwise
    ///    - pivot: The point around which the rotation will be performed (defaults to the centroid)
    public func transformedRotate(
        angle: CLLocationDegrees,
        pivot: Point? = nil)
        -> Self
    {
        transformedRotate(angle: angle, pivot: pivot?.coordinate)
    }

    /// Rotates the receiver with a specified angle, around its centroid or a given pivot point.
    /// All rotations follow the right-hand rule: https://en.wikipedia.org/wiki/Right-hand_rule.
    ///
    /// - Parameters:
    ///    - angle: The angle of the rotation (along the vertical axis), from north in decimal degrees, negative clockwise
    ///    - pivot: The coordinate around which the rotation will be performed (defaults to the centroid)
    public mutating func transformRotate(
        angle: CLLocationDegrees,
        pivot: Coordinate3D? = nil)
    {
        self = transformedRotate(angle: angle, pivot: pivot)
    }

    /// Rotates the receiver with a specified angle, around its centroid or a given pivot point.
    /// All rotations follow the right-hand rule: https://en.wikipedia.org/wiki/Right-hand_rule.
    ///
    /// - Parameters:
    ///    - angle: The angle of the rotation (along the vertical axis), from north in decimal degrees, negative clockwise
    ///    - pivot: The point around which the rotation will be performed (defaults to the centroid)
    public mutating func transformRotate(
        angle: CLLocationDegrees,
        pivot: Point? = nil)
    {
        transformRotate(angle: angle, pivot: pivot?.coordinate)
    }

}
