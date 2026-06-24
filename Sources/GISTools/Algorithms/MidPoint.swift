#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-midpoint

extension Coordinate3D {

    /// Returns a coordinate midway between the receiver and the other coordinate.
    /// The midpoint is calculated geodesically, meaning the curvature of the earth
    /// is taken into account.
    ///
    /// When both coordinates have an ``altitude`` value, the result carries the
    /// arithmetic mean of the two altitudes. Otherwise the result has no altitude.
    ///
    /// - Parameter other: The other coordinate
    ///
    /// - Returns: The midpoint coordinate.
    public func midpoint(to other: Coordinate3D) -> Coordinate3D {
        let result: Coordinate3D
        switch projection {
        case .epsg4326:
            result = _midpoint(to: other.projected(to: .epsg4326))
        case .epsg3857:
            result = projected(to: .epsg4326)._midpoint(to: other.projected(to: .epsg4326)).projected(to: .epsg3857)
        case .epsg4978:
            result = projected(to: .epsg4326)._midpoint(to: other.projected(to: .epsg4326)).projected(to: .epsg4978)
        case .noSRID:
            result = Coordinate3D(
                x: longitude + ((other.longitude - longitude) / 2.0),
                y: latitude + ((other.latitude - latitude) / 2.0),
                z: self.altitude,
                m: self.m,
                projection: .noSRID)
        }
        // Override altitude with the arithmetic mean when both sides have one.
        if let a = self.altitude, let b = other.altitude {
            var copy = result
            copy.altitude = (a + b) / 2.0
            return copy
        }
        return result
    }

    private func _midpoint(to other: Coordinate3D) -> Coordinate3D {
        let distance = self.distance(from: other)
        let bearing = self.bearing(to: other)

        return destination(distance: distance / 2.0, bearing: bearing)
    }

}

extension Point {

    /// Returns a point midway between the receiver and the other *Point*.
    /// The midpoint is calculated geodesically, meaning the curvature of the earth
    /// is taken into account.
    ///
    /// When both points have an ``altitude`` value, the result carries the
    /// arithmetic mean of the two altitudes. Otherwise the result has no altitude.
    ///
    /// - Parameter other: The other point
    ///
    /// - Returns: The midpoint point.
    public func midpoint(to other: Point) -> Point {
        Point(self.coordinate.midpoint(to: other.coordinate))
    }

}
