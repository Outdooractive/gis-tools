#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-overlap

extension PointGeometry {

    /// Compares two Point|MultiPoint geometries and returns true if their intersection set results in a geometry
    /// different from both but of the same dimension.
    ///
    /// - Parameters:
    ///    - other: The other Point or MultiPoint
    ///    - tolerance: The tolerance, in meters.
    ///
    /// - Returns: *true* if the points overlap, *false* otherwise.
    public func isOverlapping(
        with other: PointGeometry,
        tolerance: CLLocationDegrees = 0.0)
        -> Bool
    {
        let other = other.projected(to: projection)

        guard !isEqualTo(other) else { return false }

        if let point = self as? Point {
            if let otherPoint = other as? Point {
                return point == otherPoint
            }
            else if let otherMultiPoint = other as? MultiPoint {
                return otherMultiPoint.coordinates.contains(point.coordinate)
            }
        }
        else if let multiPoint = self as? MultiPoint {
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
    /// - Parameters:
    ///    - other: The other Point or MultiPoint
    ///    - tolerance: The tolerance, in meters.
    ///
    /// - Returns: *true* if the points overlap, *false* otherwise.
    public func isOverlapping(
        with other: LineStringGeometry,
        tolerance: CLLocationDegrees = 0.0)
        -> Bool
    {
        let other = other.projected(to: projection)

        guard !isEqualTo(other) else { return false }

        let tree: RTree<LineSegment> = RTree(lineSegments)

        for segment in other.lineSegments {
            guard let boundingBox = segment.boundingBox ?? segment.calculateBoundingBox() else { continue }

            for match in tree.search(inBoundingBox: boundingBox) {
                if segment.compare(other: match, tolerance: tolerance) != .notEqual {
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
    /// - Parameters:
    ///    - other: The other Point or MultiPoint
    ///    - tolerance: The tolerance, in meters.
    ///
    /// - Returns: *true* if the points overlap, *false* otherwise.
    public func isOverlapping(
        with other: PolygonGeometry,
        tolerance: CLLocationDegrees = 0.0)
        -> Bool
    {
        let other = other.projected(to: projection)

        guard !isEqualTo(other) else { return false }

        let tree: RTree<LineSegment> = RTree(lineSegments)

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
    /// - Parameters:
    ///    - other: The other Point or MultiPoint
    ///    - tolerance: The tolerance, in meters.
    ///
    /// - Returns: *true* if the points overlap, *false* otherwise.
    public func isOverlapping(
        with other: Feature,
        tolerance: CLLocationDegrees = 0.0)
        -> Bool
    {
        let other = other.projected(to: projection)

        if let first = self.geometry as? PointGeometry,
           let second = other.geometry as? PointGeometry
        {
            return first.isOverlapping(with: second, tolerance: tolerance)
        }
        else if let first = self.geometry as? LineStringGeometry,
                let second = other.geometry as? LineStringGeometry
        {
            return first.isOverlapping(with: second, tolerance: tolerance)
        }
        else if let first = self.geometry as? PolygonGeometry,
                let second = other.geometry as? PolygonGeometry
        {
            return first.isOverlapping(with: second, tolerance: tolerance)
        }

        return false
    }

}
