#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-distance

extension Coordinate3D {

    /// Calculates the distance between two coordinates, in meters.
    /// This uses the Haversine formula to account for global curvature.
    ///
    /// - Parameter other: The other coordinate
    public func distance(from other: Coordinate3D) -> CLLocationDistance {
        switch projection {
        case .epsg4326:
            return _distance(from: other.projected(to: .epsg4326))
        case .epsg3857:
            // TODO: This can be improved
            return projected(to: .epsg4326)._distance(from: other.projected(to: .epsg4326))
        case .noSRID:
            // TODO
            return Double.infinity
        }
    }

    private func _distance(from other: Coordinate3D) -> CLLocationDistance {
        let dLatitude = (other.latitude - latitude).degreesToRadians
        let dLongitude = (other.longitude - longitude).degreesToRadians

        let latitude1 = latitude.degreesToRadians
        let latitude2 = other.latitude.degreesToRadians

        let a = pow(sin(dLatitude / 2.0), 2.0) + pow(sin(dLongitude / 2.0), 2.0) * cos(latitude1) * cos(latitude2)

        return (2.0 * atan2(sqrt(a), sqrt(1 - a))) * GISTool.earthRadius
    }

}

extension Point {

    /// Calculates the distance between two points, in meters.
    /// This uses the Haversine formula to account for global curvature.
    ///
    /// - Parameter other: The other point
    public func distance(from other: Point) -> CLLocationDistance {
        coordinate.distance(from: other.coordinate)
    }

}
