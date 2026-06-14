#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-transform-rotate

extension GeoJson {

    /// Rotates any geojson Feature or Geometry of a specified angle, around its centroid or a given pivot point.
    /// All rotations follow the right-hand rule: https://en.wikipedia.org/wiki/Right-hand_rule.
    ///
    /// - Parameter angle: The angle of the rotation (along the vertical axis), from north in decimal degrees, negative clockwise
    /// - Parameter pivot: The coordinate around which the rotation will be performed (defaults to the centroid)
    /// - Returns: The rotated geometry.
    public func rotated(
        angle: CLLocationDegrees,
        pivot: Coordinate3D? = nil
    ) -> Self {
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
    /// - Parameter angle: The angle of the rotation (along the vertical axis), from north in decimal degrees, negative clockwise
    /// - Parameter pivot: The coordinate around which the rotation will be performed (defaults to the centroid)
    /// - Returns: The rotated geometry.
    public func rotated(
        angle: CLLocationDegrees,
        pivot: Point? = nil
    ) -> Self {
        rotated(angle: angle, pivot: pivot?.coordinate)
    }

    /// Rotates the receiver with a specified angle, around its centroid or a given pivot point.
    /// All rotations follow the right-hand rule: https://en.wikipedia.org/wiki/Right-hand_rule.
    ///
    /// - Parameter angle: The angle of the rotation (along the vertical axis), from north in decimal degrees, negative clockwise
    /// - Parameter pivot: The coordinate around which the rotation will be performed (defaults to the centroid)
    public mutating func rotate(
        angle: CLLocationDegrees,
        pivot: Coordinate3D? = nil
    ) {
        self = rotated(angle: angle, pivot: pivot)
    }

    /// Rotates the receiver with a specified angle, around its centroid or a given pivot point.
    /// All rotations follow the right-hand rule: https://en.wikipedia.org/wiki/Right-hand_rule.
    ///
    /// - Parameter angle: The angle of the rotation (along the vertical axis), from north in decimal degrees, negative clockwise
    /// - Parameter pivot: The point around which the rotation will be performed (defaults to the centroid)
    public mutating func rotate(
        angle: CLLocationDegrees,
        pivot: Point? = nil
    ) {
        rotate(angle: angle, pivot: pivot?.coordinate)
    }

    @available(*, deprecated, renamed: "rotated(angle:pivot:)")
    public func transformedRotate(
        angle: CLLocationDegrees,
        pivot: Coordinate3D? = nil
    ) -> Self {
        rotated(angle: angle, pivot: pivot)
    }

    @available(*, deprecated, renamed: "rotated(angle:pivot:)")
    public func transformedRotate(
        angle: CLLocationDegrees,
        pivot: Point? = nil
    ) -> Self {
        rotated(angle: angle, pivot: pivot)
    }

    @available(*, deprecated, renamed: "rotate(angle:pivot:)")
    public mutating func transformRotate(
        angle: CLLocationDegrees,
        pivot: Coordinate3D? = nil
    ) {
        rotate(angle: angle, pivot: pivot)
    }

    @available(*, deprecated, renamed: "rotate(angle:pivot:)")
    public mutating func transformRotate(
        angle: CLLocationDegrees,
        pivot: Point? = nil
    ) {
        rotate(angle: angle, pivot: pivot)
    }

}
