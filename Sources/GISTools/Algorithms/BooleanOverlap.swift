#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-overlap

extension PointGeometry {

    /// Compares two Point|MultiPoint geometries and returns true if their intersection set results in a geometry
    /// different from both but of the same dimension.
    ///
    /// - Parameter other: The other Point or MultiPoint
    /// - Parameter tolerance: The tolerance, in meters.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the points overlap, `false` otherwise.
    public func isOverlapping(
        with other: PointGeometry,
        tolerance: CLLocationDegrees = 0.0,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let other = snappedOther.projected(to: snappedSelf.projection)

        guard !snappedSelf.isEqualTo(other) else { return false }

        if let point = snappedSelf as? Point {
            if let otherPoint = other as? Point {
                return point == otherPoint
            }
            else if let otherMultiPoint = other as? MultiPoint {
                return otherMultiPoint.coordinates.contains(point.coordinate)
            }
        }
        else if let multiPoint = snappedSelf as? MultiPoint {
            if let otherPoint = other as? Point {
                return multiPoint.coordinates.contains(otherPoint.coordinate)
            }
            else if let otherMultiPoint = other as? MultiPoint {
                let first = Set(multiPoint.coordinates)
                let second = Set(otherMultiPoint.coordinates)
                return !first.isDisjoint(with: second)
            }
        }

        return false
    }

}

extension LineStringGeometry {

    /// Compares two LineString|MultiLineString geometries and returns true if their intersection set results in a geometry
    /// different from both but of the same dimension.
    ///
    /// - Parameter other: The other LineString or MultiLineString
    /// - Parameter tolerance: The tolerance, in meters.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the lines overlap, `false` otherwise.
    public func isOverlapping(
        with other: LineStringGeometry,
        tolerance: CLLocationDegrees = 0.0,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let other = snappedOther.projected(to: snappedSelf.projection)

        guard !snappedSelf.isEqualTo(other) else { return false }

        let tree: RTree<LineSegment> = RTree(snappedSelf.lineSegments)

        for segment in other.lineSegments {
            guard let boundingBox = segment.boundingBox ?? segment.calculateBoundingBox() else { continue }

            for match in tree.search(inBoundingBox: boundingBox) {
                if segment.compare(match, tolerance: tolerance) != .notEqual {
                    return true
                }
            }
        }

        return false
    }

}

extension PolygonGeometry {

    /// Compares two Polygon|MultiPolygon geometries and returns true if their intersection set results in a geometry
    /// different from both but of the same dimension.
    ///
    /// - Parameter other: The other Polygon or MultiPolygon
    /// - Parameter tolerance: The tolerance, in meters.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the polygons overlap, `false` otherwise.
    public func isOverlapping(
        with other: PolygonGeometry,
        tolerance: CLLocationDegrees = 0.0,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let other = snappedOther.projected(to: snappedSelf.projection)

        guard !snappedSelf.isEqualTo(other) else { return false }

        let tree: RTree<LineSegment> = RTree(snappedSelf.lineSegments)

        for segment in other.lineSegments {
            guard let boundingBox = segment.boundingBox ?? segment.calculateBoundingBox() else { continue }

            for match in tree.search(inBoundingBox: boundingBox) {
                if segment.intersects(match) {
                    return true
                }
            }
        }

        return false
    }

}

extension Feature {

    /// Compares two Features and returns true if their geometry's intersection set results in a geometry
    /// different from both but of the same dimension.
    ///
    /// - Parameter other: The other Feature
    /// - Parameter tolerance: The tolerance, in meters.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the features overlap, `false` otherwise.
    public func isOverlapping(
        with other: Feature,
        tolerance: CLLocationDegrees = 0.0,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let other = snappedOther.projected(to: snappedSelf.projection)

        if let first = snappedSelf.geometry as? PointGeometry,
           let second = other.geometry as? PointGeometry
        {
            return first.isOverlapping(with: second, tolerance: tolerance, gridSize: nil)
        }
        else if let first = snappedSelf.geometry as? LineStringGeometry,
                let second = other.geometry as? LineStringGeometry
        {
            return first.isOverlapping(with: second, tolerance: tolerance, gridSize: nil)
        }
        else if let first = snappedSelf.geometry as? PolygonGeometry,
                let second = other.geometry as? PolygonGeometry
        {
            return first.isOverlapping(with: second, tolerance: tolerance, gridSize: nil)
        }

        return false
    }

}
