#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-points-within-polygon

extension PolygonGeometry {

    /// Finds coordinates that fall within the receiver.
    public func coordinatesWithin(_ coordinates: [Coordinate3D]) -> [Coordinate3D] {
        coordinates.filter({ (coordinate) -> Bool in
            contains(coordinate, ignoreBoundary: false)
        })
    }

    /// Finds *Point*s that fall within the receiver.
    public func pointsWithin(_ points: [Point]) -> [Point] {
        points.filter({ (point) -> Bool in
            contains(point.coordinate, ignoreBoundary: false)
        })
    }

}
