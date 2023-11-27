#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-point-on-line
// and from https://github.com/Turfjs/turf/blob/master/packages/turf-point-on-feature

extension LineSegment {

    /// Tests if *Coordinate3D* is on the segment.
    public func checkIsOnSegment(_ coordinate: Coordinate3D) -> Bool {
        let coordinate = coordinate.projected(to: projection)

        let ab = sqrt((second.longitude - first.longitude) * (second.longitude - first.longitude)
            + (second.latitude - first.latitude) * (second.latitude - first.latitude))
        let ap = sqrt((coordinate.longitude - first.longitude) * (coordinate.longitude - first.longitude)
            + (coordinate.latitude - first.latitude) * (coordinate.latitude - first.latitude))
        let pb = sqrt((second.longitude - coordinate.longitude) * (second.longitude - coordinate.longitude)
            + (second.latitude - coordinate.latitude) * (second.latitude - coordinate.latitude))

        return abs(ab - (ap + pb)) < GISTool.equalityDelta
    }

    /// Tests if *Point* is on the segment.
    public func checkIsOnSegment(_ point: Point) -> Bool {
        checkIsOnSegment(point.coordinate)
    }

}

extension LineStringGeometry {

    /// Tests if *Coordinate3D* is on the segment.
    public func checkIsOnLine(_ coordinate: Coordinate3D) -> Bool {
        lineSegments.contains { (segment) in
            segment.checkIsOnSegment(coordinate)
        }
    }

    /// Tests if *Point* is on the segment.
    public func checkIsOnLine(_ point: Point) -> Bool {
        checkIsOnLine(point.coordinate)
    }

}
