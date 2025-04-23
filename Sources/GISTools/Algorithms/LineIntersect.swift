#if !os(Linux)
import CoreLocation
#endif
import Foundation

// (Partly) ported from https://github.com/Turfjs/turf/blob/master/packages/turf-line-intersect
// and from https://www.geeksforgeeks.org/orientation-3-ordered-points

extension LineSegment {

    private enum Orientation: Sendable {
        case colinear
        case clockwise
        case counterClockwise
    }

    // To find orientation of ordered triplet (p, q, r).
    private func orientation(
        p: Coordinate3D,
        q: Coordinate3D,
        r: Coordinate3D)
        -> Orientation
    {
        // See https://www.geeksforgeeks.org/orientation-3-ordered-points for details of below formula.
        let value = (q.latitude - p.latitude) * (r.longitude - q.longitude) - (q.longitude - p.longitude) * (r.latitude - q.latitude)

        if value == 0 {
            return .colinear
        }
        else if value > 0 {
            return .clockwise
        }
        else {
            return .counterClockwise
        }
    }

    // Given three colinear points p, q, r, the function checks if point q lies on line segment 'pr'
    private func onSegment(
        p: Coordinate3D,
        q: Coordinate3D,
        r: Coordinate3D)
        -> Bool
    {
        if q.longitude <= max(p.longitude, r.longitude),
           q.longitude >= min(p.longitude, r.longitude),
           q.latitude <= max(p.latitude, r.latitude),
           q.latitude >= min(p.latitude, r.latitude)
        {
            return true
        }

        return false
    }

    // Ported from https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect

    /// Checks if two line segments intersect.
    ///
    /// - Parameter other: The other *LineSegment*
    public func intersects(_ other: LineSegment) -> Bool {
        let other = other.projected(to: projection)

        // Find the four orientations needed for general and special cases
        let o1 = orientation(p: first, q: second, r: other.first)
        let o2 = orientation(p: first, q: second, r: other.second)
        let o3 = orientation(p: other.first, q: other.second, r: first)
        let o4 = orientation(p: other.first, q: other.second, r: second)

        // General case
        if o1 != o2, o3 != o4 {
            return true
        }

        // Special Cases
        // p1, q1 and p2 are colinear and p2 lies on segment p1q1
        if o1 == .colinear, onSegment(p: first, q: other.first, r: second) {
            return true
        }

        // p1, q1 and q2 are colinear and q2 lies on segment p1q1
        if o2 == .colinear, onSegment(p: first, q: other.second, r: second) {
            return true
        }

        // p2, q2 and p1 are colinear and p1 lies on segment p2q2
        if o3 == .colinear, onSegment(p: other.first, q: first, r: other.second) {
            return true
        }

        // p2, q2 and q1 are colinear and q1 lies on segment p2q2
        if o4 == .colinear, onSegment(p: other.first, q: second, r: other.second) {
            return true
        }

        // Doesn't fall in any of the above cases
        return false
    }

    /// Returns the intersection of two line segments.
    ///
    /// - Parameter other: The other *LineSegment*
    public func intersection(_ other: LineSegment) -> Coordinate3D? {
        let other = other.projected(to: projection)

        // TODO: BBox check
        // Test if a quick bbox test improves performance

        let denominator: Double = ((other.second.latitude - other.first.latitude) * (self.second.longitude - self.first.longitude))
            - ((other.second.longitude - other.first.longitude) * (self.second.latitude - self.first.latitude))

        guard denominator != 0.0 else { return nil }

        let numeratorA: Double = ((other.second.longitude - other.first.longitude) * (self.first.latitude - other.first.latitude))
            - ((other.second.latitude - other.first.latitude) * (self.first.longitude - other.first.longitude))
        let numeratorB: Double = ((self.second.longitude - self.first.longitude) * (self.first.latitude - other.first.latitude))
            - ((self.second.latitude - self.first.latitude) * (self.first.longitude - other.first.longitude))

        let uA: Double = numeratorA / denominator
        let uB: Double = numeratorB / denominator

        if uA >= 0.0,
           uA <= 1.0,
           uB >= 0.0,
           uB <= 1.0
        {
            let longitude = self.first.longitude + (uA * (self.second.longitude - self.first.longitude))
            let latitude = self.first.latitude + (uA * (self.second.latitude - self.first.latitude))

            return Coordinate3D(x: longitude, y: latitude, projection: projection)
        }

        return nil
    }

}

extension GeoJson {

    /// Returns the intersecting point(s) with the receiver.
    ///
    /// - note: Takes all poygon rings into account,  not just the outer ring.
    ///
    /// - Parameter other: The other geometry
    public func intersections(other: GeoJson) -> [Point] {
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
                    if let intersection = lineSegment.intersection(otherLineSegment) {
                        result.insert(intersection)
                    }
                }
            }
        }

        return result.map { Point($0) }
    }

}
