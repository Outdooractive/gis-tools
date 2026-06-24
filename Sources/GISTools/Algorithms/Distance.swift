#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-distance

extension Coordinate3D {

    /// Calculates the distance between two coordinates, in meters.
    ///
    /// The formula used depends on the receiver's projection:
    /// - ``Projection/epsg4326``: Haversine (geodesic great‑circle distance).
    /// - ``Projection/epsg3857``, ``Projection/noSRID``: 2‑D Euclidean
    ///   ``sqrt(dx² + dy²)``.
    /// - ``Projection/epsg4978`` (ECEF): 3‑D Euclidean
    ///   ``sqrt(dx² + dy² + dz²)``.
    ///
    /// - Parameter other: The other coordinate
    ///
    /// - Returns: The distance in meters.
    public func distance(from other: Coordinate3D) -> CLLocationDistance {
        distance(to: other)
    }

    /// Calculates the distance between two coordinates, in meters.
    ///
    /// The formula used depends on the receiver's projection:
    /// - ``Projection/epsg4326``: Haversine (geodesic great‑circle distance).
    /// - ``Projection/epsg3857``, ``Projection/noSRID``: 2‑D Euclidean
    ///   ``sqrt(dx² + dy²)``.
    /// - ``Projection/epsg4978`` (ECEF): 3‑D Euclidean
    ///   ``sqrt(dx² + dy² + dz²)``.
    ///
    /// - Parameter other: The other coordinate
    ///
    /// - Returns: The distance in meters.
    public func distance(to other: Coordinate3D) -> CLLocationDistance {
        switch projection {
        case .epsg4326:
            return _distance(from: other.projected(to: .epsg4326))
        case .epsg3857, .noSRID:
            let dx = longitude - other.longitude
            let dy = latitude - other.latitude
            return sqrt(dx * dx + dy * dy)
        case .epsg4978:
            let dx = longitude - other.longitude
            let dy = latitude - other.latitude
            let dz = (altitude ?? 0.0) - (other.altitude ?? 0.0)
            return sqrt(dx * dx + dy * dy + dz * dz)
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
    ///
    /// The formula used depends on the receiver's coordinate projection
    /// (see ``Coordinate3D/distance(to:)``).
    ///
    /// - Parameter other: The other point
    ///
    /// - Returns: The distance in meters.
    public func distance(from other: Point) -> CLLocationDistance {
        distance(to: other)
    }

    /// Calculates the distance between two points, in meters.
    ///
    /// The formula used depends on the receiver's coordinate projection
    /// (see ``Coordinate3D/distance(to:)``).
    ///
    /// - Parameter other: The other point
    ///
    /// - Returns: The distance in meters.
    public func distance(to other: Point) -> CLLocationDistance {
        coordinate.distance(to: other.coordinate)
    }

}
