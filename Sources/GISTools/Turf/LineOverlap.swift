#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-line-overlap

extension LineSegment {

    public enum LineSegmentComparisonResult {
        case equal
        case notEqual
        case thisOnOther
        case otherOnThis
    }

    /// Checks how the receiver and the other *LineSegment* lie in relation to each other.
    ///
    /// - Parameters:
    ///    - other: The other *LineSegment*
    ///    - tolerance: The tolerance, in meters
    public func compare(
        other: LineSegment,
        tolerance: CLLocationDistance = 0.0)
        -> LineSegmentComparisonResult
    {
        let tolerance = abs(tolerance)

        if (first == other.first && second == other.second)
            || (first == other.second && second == other.first)
        {
            return .equal
        }
        else if tolerance == 0.0 {
            if other.checkIsOnSegment(first), other.checkIsOnSegment(second) {
                return .thisOnOther
            }
            else if checkIsOnSegment(other.first), checkIsOnSegment(other.second) {
                return .otherOnThis
            }
        }
        else if tolerance > 0.0 {
            if other.nearestCoordinateOnSegment(from: first).distance <= tolerance,
               other.nearestCoordinateOnSegment(from: second).distance <= tolerance
            {
                return .thisOnOther
            }
            else if nearestCoordinateOnSegment(from: other.first).distance <= tolerance,
                    nearestCoordinateOnSegment(from: other.second).distance <= tolerance
            {
                return .otherOnThis
            }
        }

        return .notEqual
    }

}

extension GeoJson {

    /// Returns the overlapping segments between the receiver and the other geometry.
    ///
    /// - Parameters:
    ///    - other: The other geometry
    ///    - tolerance: The tolerance, in meters
    public func overlappingSegments(
        with other: GeoJson,
        tolerance: CLLocationDistance = 0.0)
        -> [LineSegment]
    {
        let tolerance = abs(tolerance)

        var result: [LineSegment] = []

        let tree: RTree<LineSegment> = RTree(lineSegments())

        for segment in other.lineSegments() {
            guard let boundingBox = segment.boundingBox ?? segment.calculateBoundingBox() else { continue }

            for match in tree.search(inBoundingBox: boundingBox) {
                let comparison = segment.compare(other: match, tolerance: tolerance)

                if comparison == .equal {
                    result.append(segment)
                    break
                }
                else if comparison == .thisOnOther {
                    result.append(segment)
                    break
                }
                else if comparison == .otherOnThis {
                    result.append(match)
                }
            }
        }

        return result
    }

}
