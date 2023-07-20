#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-boolean-parallel

extension LineSegment {

    /// Checks if the receiver is parallel to the other *LineSegment*.
    ///
    /// - Parameters:
    ///    - other: The other LineSegment
    ///    - tolerance: The tolerance, in degrees
    ///
    /// - Returns: *true* if the segments are parallel within the tolerance, *false* otherwise.
    public func isParallel(
        to other: LineSegment,
        tolerance: CLLocationDegrees = 0.0,
        undirectedEdge: Bool = false)
        -> Bool
    {
        var azimuth1 = first.rhumbBearing(to: second).bearingToAzimuth
        let azimuth2 = other.first.rhumbBearing(to: other.second).bearingToAzimuth

        if abs(azimuth1 - azimuth2) <= tolerance {
            return true
        }
        else if undirectedEdge {
            azimuth1 -= 180.0
            if azimuth1 < 0.0 {
                azimuth1 += 360.0
            }
            return abs(azimuth1 - azimuth2) <= tolerance
        }

        return false
    }

}

extension LineString {

    /// Checks if each of the receiver's segment is parallel to the correspondent segment of the other *LineString*.
    ///
    /// - Parameters:
    ///    - other: The other LineString
    ///    - tolerance: The tolerance for each pair of segments, in degrees
    ///
    /// - Returns: *true* if the lines are parallel within the tolerance, *false* otherwise.
    public func isParallel(
        to other: LineString,
        tolerance: CLLocationDegrees = 0.0)
        -> Bool
    {
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
