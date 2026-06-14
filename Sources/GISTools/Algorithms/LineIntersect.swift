#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// (Partly) ported from https://github.com/Turfjs/turf/blob/master/packages/turf-line-intersect
// and from https://www.geeksforgeeks.org/orientation-3-ordered-points

extension LineSegment {

    /// The orientation of three ordered points.
    private enum Orientation: Sendable {
        /// Points are colinear.
        case colinear
        /// Points are oriented clockwise.
        case clockwise
        /// Points are oriented counter-clockwise.
        case counterClockwise
    }

    /// Determines the orientation of an ordered triplet of points.
    private func orientation(
        p: Coordinate3D,
        q: Coordinate3D,
        r: Coordinate3D,
        epsilon: Double = 0.0
    ) -> Orientation {
        let value = (q.latitude - p.latitude) * (r.longitude - q.longitude) - (q.longitude - p.longitude) * (r.latitude - q.latitude)

        if abs(value) <= epsilon {
            return .colinear
        }
        if value > 0 {
            return .clockwise
        }
        return .counterClockwise
    }

    /// Checks if point q lies on the line segment between p and r, given that all three are colinear.
    private func onSegment(
        p: Coordinate3D,
        q: Coordinate3D,
        r: Coordinate3D,
        epsilon: Double = 0.0
    ) -> Bool {
        let minX = min(p.longitude, r.longitude) - epsilon
        let maxX = max(p.longitude, r.longitude) + epsilon
        let minY = min(p.latitude, r.latitude) - epsilon
        let maxY = max(p.latitude, r.latitude) + epsilon

        return q.longitude >= minX && q.longitude <= maxX
            && q.latitude >= minY && q.latitude <= maxY
    }

    // Ported from https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect

    /// Checks if two line segments intersect.
    ///
    /// - Parameters:
    /// - Parameter other: The other *LineSegment*
    /// - Parameter epsilon: Tolerance for collinearity and on-segment checks
    ///     (in the coordinate system's native units, e.g. degrees for EPSG:4326)
    ///
    /// - Returns: `true` if the line segments intersect.
    public func intersects(_ other: LineSegment, epsilon: Double = 0.0) -> Bool {
        let other = other.projected(to: projection)

        let o1 = orientation(p: first, q: second, r: other.first, epsilon: epsilon)
        let o2 = orientation(p: first, q: second, r: other.second, epsilon: epsilon)
        let o3 = orientation(p: other.first, q: other.second, r: first, epsilon: epsilon)
        let o4 = orientation(p: other.first, q: other.second, r: second, epsilon: epsilon)

        if o1 != o2, o3 != o4 {
            return true
        }

        if o1 == .colinear, onSegment(p: first, q: other.first, r: second, epsilon: epsilon) {
            return true
        }
        if o2 == .colinear, onSegment(p: first, q: other.second, r: second, epsilon: epsilon) {
            return true
        }
        if o3 == .colinear, onSegment(p: other.first, q: first, r: other.second, epsilon: epsilon) {
            return true
        }
        if o4 == .colinear, onSegment(p: other.first, q: second, r: other.second, epsilon: epsilon) {
            return true
        }

        return false
    }

    /// Returns the parameter (0–1) of `point` projected onto this segment's direction.
    private func parameter(of point: Coordinate3D) -> Double {
        let dx = second.longitude - first.longitude
        let dy = second.latitude - first.latitude
        let lengthSq = dx * dx + dy * dy
        guard lengthSq > 0 else { return 0.0 }
        let px = point.longitude - first.longitude
        let py = point.latitude - first.latitude
        return (px * dx + py * dy) / lengthSq
    }

    /// Returns the intersection of two line segments with an epsilon tolerance.
    ///
    /// Returns `nil` when the segments are parallel or collinear (overlapping
    /// collinear segments produce a line segment, not a single point).
    ///
    /// - Parameters:
    /// - Parameter other: The other *LineSegment*
    /// - Parameter epsilon: Tolerance for endpoint parameter checks
    ///     (in the coordinate system's native units, e.g. degrees for EPSG:4326)
    ///
    /// - Returns: The intersection point, or `nil`.
    public func intersection(
        _ other: LineSegment,
        epsilon: Double = 0.0
    ) -> Coordinate3D? {
        let other = other.projected(to: projection)

        let denominator: Double = ((other.second.latitude - other.first.latitude) * (self.second.longitude - self.first.longitude))
            - ((other.second.longitude - other.first.longitude) * (self.second.latitude - self.first.latitude))

        if abs(denominator) > 1e-15 {
            let numeratorA: Double = ((other.second.longitude - other.first.longitude) * (self.first.latitude - other.first.latitude))
                - ((other.second.latitude - other.first.latitude) * (self.first.longitude - other.first.longitude))
            let numeratorB: Double = ((self.second.longitude - self.first.longitude) * (self.first.latitude - other.first.latitude))
                - ((self.second.latitude - self.first.latitude) * (self.first.longitude - other.first.longitude))

            let uA: Double = numeratorA / denominator
            let uB: Double = numeratorB / denominator

            if uA >= -epsilon,
               uA <= 1.0 + epsilon,
               uB >= -epsilon,
               uB <= 1.0 + epsilon
            {
                let longitude = self.first.longitude + (uA * (self.second.longitude - self.first.longitude))
                let latitude = self.first.latitude + (uA * (self.second.latitude - self.first.latitude))

                return Coordinate3D(x: longitude, y: latitude, projection: projection)
            }
            return nil
        }

        return nil
    }

}

extension GeoJson {

    /// Returns the intersecting point(s) with the receiver.
    ///
    /// - note: Takes all polygon rings into account, not just the outer ring.
    ///
    /// - Parameters:
    /// - Parameter other: The other geometry
    /// - Parameter epsilon: Tolerance passed through to ``LineSegment/intersection(_:epsilon:)``
    ///     (in the coordinate system's native units, e.g. degrees for EPSG:4326)
    ///
    /// - Returns: An array of intersecting points.
    public func intersections(with other: GeoJson, epsilon: Double = 0.0) -> [Point] {
        let other = other.projected(to: projection)

        if let otherBoundingBox = other.boundingBox ?? other.calculateBoundingBox(),
           !intersects(otherBoundingBox)
        {
            return []
        }

        var result: Set<Coordinate3D> = []

        if let point = self as? PointGeometry {
            if let otherPoint = other as? PointGeometry {
                for coordinate in point.allCoordinates
                    where otherPoint.allCoordinates.contains(coordinate)
                {
                    result.insert(coordinate)
                }
            }
            else {
                for coordinate in point.allCoordinates {
                    for otherLineSegment in other.lineSegments
                        where otherLineSegment.checkIsOnSegment(coordinate)
                    {
                        result.insert(coordinate)
                    }
                }
            }
        }
        else {
            for lineSegment in lineSegments {
                for otherLineSegment in other.lineSegments {
                    if let intersection = lineSegment.intersection(otherLineSegment, epsilon: epsilon) {
                        result.insert(intersection)
                    }
                }
            }
        }

        return result.map { Point($0) }
    }

}
