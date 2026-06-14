#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-boolean-parallel

extension LineSegment {

    /// Checks if the receiver is parallel to the other *LineSegment*.
    ///
    /// - Parameter other: The other LineSegment
    /// - Parameter tolerance: The tolerance, in degrees
    /// - Parameter undirectedEdge: Whether the segment should be treated as an undirected edge
    ///
    /// - Returns: `true` if the segments are parallel within the tolerance, `false` otherwise.
    public func isParallel(
        to other: LineSegment,
        tolerance: CLLocationDegrees = 0.0,
        undirectedEdge: Bool = false
    ) -> Bool {
        let azimuth1 = first.rhumbBearing(to: second).bearingToAzimuth
        let azimuth2 = other.first.rhumbBearing(to: other.second).bearingToAzimuth

        // Normalise the angular difference to [0, 180] so the comparison
        // correctly handles values that straddle the 0°/360° boundary.
        var diff = abs(azimuth1 - azimuth2)
        if diff > 180.0 {
            diff = 360.0 - diff
        }

        if diff <= tolerance {
            return true
        }

        if undirectedEdge {
            // Test the opposite direction: a line is parallel to its reversal.
            var opposite = azimuth1 + 180.0
            if opposite >= 360.0 {
                opposite -= 360.0
            }
            diff = abs(opposite - azimuth2)
            if diff > 180.0 {
                diff = 360.0 - diff
            }
            return diff <= tolerance
        }

        return false
    }

}

extension LineString {

    /// Checks if each of the receiver's segment is parallel to the correspondent segment of the other *LineString*.
    ///
    /// - Parameter other: The other LineString
    /// - Parameter tolerance: The tolerance for each pair of segments, in degrees
    ///
    /// - Returns: `true` if the lines are parallel within the tolerance, `false` otherwise.
    public func isParallel(
        to other: LineString,
        tolerance: CLLocationDegrees = 0.0
    ) -> Bool {
        let segments1 = lineSegments
        let segments2 = other.lineSegments
        let count = min(segments1.count, segments2.count)

        for index in 0 ..< count {
            let segment1 = segments1[index]
            let segment2 = segments2[index]

            if !segment1.isParallel(to: segment2, tolerance: tolerance) {
                return false
            }
        }

        return true
    }

}
