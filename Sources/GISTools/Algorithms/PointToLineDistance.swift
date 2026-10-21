#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-point-to-line-distance

extension LineSegment {

    /// Returns the minimum distance between the coordinate and the segment.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func distanceFrom(coordinate: Coordinate3D, gridSize: Double? = nil) -> CLLocationDistance {
        let segment = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let coordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        let foot = segment.perpendicularFoot(from: coordinate, clampToEnds: true) ?? segment.first
        return foot.distance(from: coordinate)
    }

    /// Returns the minimum distance between the *Point* and the segment.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func distanceFrom(point: Point, gridSize: Double? = nil) -> CLLocationDistance {
        distanceFrom(coordinate: point.coordinate, gridSize: gridSize)
    }

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

    /// Returns the minimum distance between a *Point* and the receiver, being the distance
    /// from a line the minimum distance between the point and any segment of the line.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func distanceFrom(point: Point, gridSize: Double? = nil) -> CLLocationDistance {
        distanceFrom(coordinate: point.coordinate, gridSize: gridSize)
    }

    /// Returns the minimum distance between a coordinate and the receiver, being the distance
    /// from a line the minimum distance between the coordinate and any segment of the line.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func distanceFrom(coordinate: Coordinate3D, gridSize: Double? = nil) -> CLLocationDistance {
        let lineString = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let coordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate
        var bestDistance: CLLocationDistance = .greatestFiniteMagnitude

        for segment in lineString.lineSegments {
            let distance = segment.distanceFrom(coordinate: coordinate, gridSize: nil)

            if distance < bestDistance {
                bestDistance = distance
            }
        }

        return bestDistance
    }

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
