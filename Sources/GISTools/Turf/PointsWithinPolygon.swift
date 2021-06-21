#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-points-within-polygon

extension PolygonGeometry {

    /// Finds coordinates that fall within the receiver.
    public func coordinatesWithin(_ coordinates: [Coordinate3D]) -> [Coordinate3D] {
        return coordinates.filter({ (coordinate) -> Bool in
            return contains(coordinate, ignoreBoundary: false)
        })
    }

    /// Finds *Point*s that fall within the receiver.
    public func pointsWithin(_ points: [Point]) -> [Point] {
        return points.filter({ (point) -> Bool in
            return contains(point.coordinate, ignoreBoundary: false)
        })
    }

}
