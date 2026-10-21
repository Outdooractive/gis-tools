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

// MARK: - Coordinate3D / Point

extension Coordinate3D {

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

    /// Returns the Rhumb distance to another coordinate in the requested unit.
    ///
    /// - Parameters:
    ///   - other: The other coordinate
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func rhumbDistance(
        from other: Coordinate3D,
        in unit: GISTool.Unit
    ) -> Double? {
        DistanceUnitConverter.fromMeters(
            rhumbDistance(from: other),
            projection: projection,
            unit: unit)
    }

}

extension Point {

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

    /// Returns the Rhumb distance to another point in the requested unit.
    ///
    /// - Parameters:
    ///   - other: The other point
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func rhumbDistance(
        from other: Point,
        in unit: GISTool.Unit
    ) -> Double? {
        coordinate.rhumbDistance(from: other.coordinate, in: unit)
    }

}

// MARK: - LineString distance along

extension LineString {

    /// Returns the distance along the line in the requested unit.
    ///
    /// - Parameters:
    ///   - coordinate: A coordinate near the line
    ///   - tolerance: Maximum distance from the line in meters (default `1.0`)
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func distanceAlong(
        to coordinate: Coordinate3D,
        tolerance: CLLocationDistance = 1.0,
        in unit: GISTool.Unit
    ) -> Double? {
        guard let distance = distanceAlong(to: coordinate, tolerance: tolerance) else {
            return nil
        }

        return DistanceUnitConverter.fromMeters(
            distance,
            projection: projection,
            unit: unit)
    }

}

// MARK: - Point-to-line distance

extension LineSegment {

    /// Returns the minimum distance to a coordinate in the requested unit.
    ///
    /// - Parameters:
    ///   - coordinate: The coordinate to measure from
    ///   - gridSize: Snap coordinates to a grid before computing (default `nil`)
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func distanceFrom(
        coordinate: Coordinate3D,
        gridSize: Double? = nil,
        in unit: GISTool.Unit
    ) -> Double? {
        DistanceUnitConverter.fromMeters(
            distanceFrom(coordinate: coordinate, gridSize: gridSize),
            projection: projection,
            unit: unit)
    }

    /// Returns the minimum distance to a point in the requested unit.
    ///
    /// - Parameters:
    ///   - point: The point to measure from
    ///   - gridSize: Snap coordinates to a grid before computing (default `nil`)
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func distanceFrom(
        point: Point,
        gridSize: Double? = nil,
        in unit: GISTool.Unit
    ) -> Double? {
        distanceFrom(coordinate: point.coordinate, gridSize: gridSize, in: unit)
    }

}

extension LineString {

    /// Returns the minimum distance to a coordinate in the requested unit.
    ///
    /// - Parameters:
    ///   - coordinate: The coordinate to measure from
    ///   - gridSize: Snap coordinates to a grid before computing (default `nil`)
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func distanceFrom(
        coordinate: Coordinate3D,
        gridSize: Double? = nil,
        in unit: GISTool.Unit
    ) -> Double? {
        DistanceUnitConverter.fromMeters(
            distanceFrom(coordinate: coordinate, gridSize: gridSize),
            projection: projection,
            unit: unit)
    }

    /// Returns the minimum distance to a point in the requested unit.
    ///
    /// - Parameters:
    ///   - point: The point to measure from
    ///   - gridSize: Snap coordinates to a grid before computing (default `nil`)
    ///   - unit: The target unit
    /// - Returns: The converted distance, or `nil` for noSRID or an invalid unit
    public func distanceFrom(
        point: Point,
        gridSize: Double? = nil,
        in unit: GISTool.Unit
    ) -> Double? {
        distanceFrom(coordinate: point.coordinate, gridSize: gridSize, in: unit)
    }

}

// MARK: - dWithin

extension GeoJson {

    /// Returns `true` if the receiver is within the given distance of `other`.
    ///
    /// The distance is converted to meters from `unit`. For
    /// ``Projection/noSRID`` no physical unit is defined and this returns
    /// `false`.
    ///
    /// - Parameters:
    ///   - other: The other geometry
    ///   - distance: The maximum distance in `unit`
    ///   - unit: The unit of `distance`
    /// - Returns: `true` if the minimum distance is at most `distance`
    public func dWithin(
        _ other: GeoJson,
        distance: CLLocationDistance,
        in unit: GISTool.Unit
    ) -> Bool {
        guard let meters = DistanceUnitConverter.toMeters(
            distance,
            projection: projection,
            unit: unit)
        else { return false }

        return dWithin(other, distance: meters)
    }

}
