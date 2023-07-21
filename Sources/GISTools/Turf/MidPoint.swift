#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-midpoint

extension Coordinate3D {

    /// Returns a coordinate midway between the receiver and the other coordinate.
    /// The midpoint is calculated geodesically, meaning the curvature of the earth is taken into account.
    ///
    /// - Parameter other: The other coordinate
    public func midpoint(to other: Coordinate3D) -> Coordinate3D {
        switch projection {
        case .epsg4326:
            return _midpoint(to: other.projected(to: .epsg4326))
        case .epsg3857:
            return projected(to: .epsg4326)._midpoint(to: other.projected(to: .epsg4326)).projected(to: .epsg3857)
        case .noSRID:
            return Coordinate3D(
                x: longitude + ((other.longitude - longitude) / 2.0),
                y: latitude + ((other.latitude - latitude) / 2.0),
                projection: .noSRID)
        }
    }

    private func _midpoint(to other: Coordinate3D) -> Coordinate3D {
        let distance = self.distance(from: other)
        let bearing = self.bearing(to: other)

        return destination(distance: distance / 2.0, bearing: bearing)
    }

}

extension Point {

    /// Returns a point midway between the receiver and the other *Point*.
    /// The midpoint is calculated geodesically, meaning the curvature of the earth is taken into account.
    ///
    /// - Parameter other: The other point
    public func midpoint(to other: Point) -> Point {
        Point(self.coordinate.midpoint(to: other.coordinate))
    }

}
