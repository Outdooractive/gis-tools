#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-overlap

extension PointGeometry {

    /// Compares two Point|MultiPoint geometries and returns true if their intersection set results in a geometry
    /// different from both but of the same dimension.
    ///
    /// All projections are supported — coordinates are compared for equality.
    ///
    /// - Parameter other: The other Point or MultiPoint
    /// - Parameter tolerance: The tolerance, in meters.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the points overlap, `false` otherwise.
    public func isOverlapping(
        with other: PointGeometry,
        tolerance: CLLocationDistance = 0.0,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let other = snappedOther.projected(to: snappedSelf.projection)

        guard !snappedSelf.equals(other) else { return false }

        func matches(_ first: Coordinate3D, _ second: Coordinate3D) -> Bool {
            if tolerance > 0.0 {
                return first.distance(from: second) <= tolerance
            }
            return first.isCoincident(to: second)
        }

        let firstCoordinates = snappedSelf.allCoordinates
        let secondCoordinates = other.allCoordinates
        let commonCount = firstCoordinates.filter { first in
            secondCoordinates.contains { second in matches(first, second) }
        }
        .count

        return commonCount > 0
            && commonCount < firstCoordinates.count
            && commonCount < secondCoordinates.count
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
        tolerance: CLLocationDistance = 0.0,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let other = snappedOther.projected(to: snappedSelf.projection)

        guard !snappedSelf.isEqualTo(other) else { return false }
        guard !snappedSelf.covers(other), !other.covers(snappedSelf) else { return false }

        if snappedSelf.hasCollinearOverlap(with: other) {
            return true
        }

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

    fileprivate func hasCollinearOverlap(with other: LineStringGeometry) -> Bool {
        let other = other.projected(to: projection)
        let otherSegments = other.lineSegments

        for segment in lineSegments {
            for otherSegment in otherSegments {
                let cross = ((segment.second.longitude - segment.first.longitude)
                    * (otherSegment.second.latitude - otherSegment.first.latitude))
                    - ((segment.second.latitude - segment.first.latitude)
                        * (otherSegment.second.longitude - otherSegment.first.longitude))
                guard abs(cross) <= GISTool.intersectionEpsilon else { continue }

                func isInterior(_ coordinate: Coordinate3D) -> Bool {
                    !coordinate.isCoincident(to: segment.first)
                        && !coordinate.isCoincident(to: segment.second)
                        && segment.checkIsOnSegment(coordinate)
                }

                if isInterior(otherSegment.first) || isInterior(otherSegment.second) {
                    return true
                }
            }
        }

        return false
    }

}

extension PolygonGeometry {

    /// Compares two Polygon|MultiPolygon geometries using OGC `ST_Overlaps`.
    ///
    /// The result is `true` when the interiors intersect, neither geometry
    /// contains the other, and the geometries are not equal. Boundary-only
    /// contact does not count as overlap.
    ///
    /// - Parameter other: The other Polygon or MultiPolygon
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the polygons overlap, `false` otherwise.
    public func isOverlapping(
        with other: PolygonGeometry,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let other = snappedOther.projected(to: snappedSelf.projection)

        guard !snappedSelf.isEqualTo(other) else { return false }

        // Overlay projects to EPSG:3857, which is not meaningful for ECEF
        // coordinates near the origin. Keep the raw-XY boundary check for
        // geocentric data.
        if snappedSelf.projection.isGeocentric {
            let first = snappedSelf.projected(to: .epsg4326)
            let second = other.projected(to: .epsg4326)
            return first.isOverlapping(with: second)
        }

        // OGC ST_Overlaps: equal interiors alone are not overlap. The
        // geometries must have the same dimension, their interiors must
        // intersect, neither may contain the other, and they must not be
        // equal. Compare intersection and component areas so this also works
        // in projected CRSs where the coverage predicate is not the right
        // abstraction.
        guard let intersection = Intersection.intersectPolygons(
            snappedSelf.polygons + other.polygons,
            firstCount: snappedSelf.polygons.count)
        else { return false }

        let overlapArea = OverlapArea.of(intersection)
        guard overlapArea > GISTool.equalityDelta else { return false }

        let selfArea = snappedSelf.polygons.reduce(0.0) { $0 + $1.area }
        let otherArea = other.polygons.reduce(0.0) { $0 + $1.area }

        return !AreaComparison.areEqual(overlapArea, selfArea)
            && !AreaComparison.areEqual(overlapArea, otherArea)
    }

}

extension Feature {

    /// Compares two Features and returns true if their geometry's intersection set results in a geometry
    /// different from both but of the same dimension.
    ///
    /// - Parameter other: The other Feature
    /// - Parameter tolerance: The tolerance in meters for point and line
    ///   geometry features. Polygon features use OGC area-based overlap.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the features overlap, `false` otherwise.
    public func isOverlapping(
        with other: Feature,
        tolerance: CLLocationDistance = 0.0,
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
            return first.isOverlapping(with: second, gridSize: nil)
        }

        return false
    }

}

private enum OverlapArea {

    static func of(_ geometry: PolygonGeometry) -> Double {
        switch geometry {
        case let polygon as Polygon:
            return polygon.area
        case let multiPolygon as MultiPolygon:
            return multiPolygon.area
        default:
            return 0.0
        }
    }

}
