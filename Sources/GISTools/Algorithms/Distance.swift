#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - Distance unit conversion

enum DistanceUnitConverter {

    /// Converts a distance returned by the library's meter-based distance APIs
    /// into `unit`.
    static func fromMeters(
        _ distance: Double,
        projection: Projection,
        unit: GISTool.Unit
    ) -> Double? {
        guard projection != .noSRID else { return nil }
        return GISTool.convert(length: distance, from: .meters, to: unit)
    }

    /// Converts a distance expressed in `unit` into meters for comparison with
    /// the library's meter-based distance APIs.
    static func toMeters(
        _ distance: Double,
        projection: Projection,
        unit: GISTool.Unit
    ) -> Double? {
        guard projection != .noSRID else { return nil }
        return GISTool.convert(length: distance, from: unit, to: .meters)
    }

}

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-distance

extension Coordinate3D {

    /// Calculates the distance between two coordinates, in meters.
    ///
    /// The formula used depends on the receiver's projection kind:
    /// - Geographic (e.g. ``Projection/epsg4326``): Haversine
    ///   (geodesic great‑circle distance).
    /// - Planar (e.g. ``Projection/epsg3857``) and ``Projection/noSRID``:
    ///   2‑D Euclidean ``sqrt(dx² + dy²)``.
    /// - Geocentric (e.g. ``Projection/epsg4978``, ECEF): 3‑D Euclidean
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
    /// The formula used depends on the receiver's projection kind:
    /// - Geographic (e.g. ``Projection/epsg4326``): Haversine
    ///   (geodesic great‑circle distance).
    /// - Planar (e.g. ``Projection/epsg3857``) and ``Projection/noSRID``:
    ///   2‑D Euclidean ``sqrt(dx² + dy²)``.
    /// - Geocentric (e.g. ``Projection/epsg4978``, ECEF): 3‑D Euclidean
    ///   ``sqrt(dx² + dy² + dz²)``.
    ///
    /// - Parameter other: The other coordinate
    ///
    /// - Returns: The distance in meters.
    public func distance(to other: Coordinate3D) -> CLLocationDistance {
        switch projection.kind {
        case .geographic:
            return _distance(from: other.projected(to: .epsg4326))
        case .planar, .undefined:
            let dx = longitude - other.longitude
            let dy = latitude - other.latitude
            return sqrt(dx * dx + dy * dy)
        case .geocentric:
            let dx = longitude - other.longitude
            let dy = latitude - other.latitude
            let dz = (altitude ?? 0.0) - (other.altitude ?? 0.0)
            return sqrt(dx * dx + dy * dy + dz * dz)
        }
    }

    /// Returns the distance to another coordinate in the requested unit.
    ///
    /// The underlying distance is in meters for EPSG:4326, EPSG:3857 and
    /// EPSG:4978. For ``Projection/noSRID`` no physical unit is defined and
    /// this returns `nil`.
    ///
    /// - Parameters:
    ///   - other: The other coordinate
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func distance(
        to other: Coordinate3D,
        in unit: GISTool.Unit
    ) -> Double? {
        DistanceUnitConverter.fromMeters(
            distance(to: other),
            projection: projection,
            unit: unit)
    }

    /// Returns the distance from another coordinate in the requested unit.
    ///
    /// - Parameters:
    ///   - other: The other coordinate
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func distance(
        from other: Coordinate3D,
        in unit: GISTool.Unit
    ) -> Double? {
        distance(to: other, in: unit)
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

    /// Returns the distance to another point in the requested unit.
    ///
    /// - Parameters:
    ///   - other: The other point
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func distance(
        to other: Point,
        in unit: GISTool.Unit
    ) -> Double? {
        coordinate.distance(to: other.coordinate, in: unit)
    }

    /// Returns the distance from another point in the requested unit.
    ///
    /// - Parameters:
    ///   - other: The other point
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func distance(
        from other: Point,
        in unit: GISTool.Unit
    ) -> Double? {
        coordinate.distance(from: other.coordinate, in: unit)
    }

}
