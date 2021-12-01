#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-point-to-line-distance

extension LineSegment {

    /// Returns the minimum distance between the coordinate and the segment.
    public func distanceFrom(coordinate: Coordinate3D) -> CLLocationDistance {
        let foot = perpendicularFoot(coordinate: coordinate, clampToEnds: true) ?? first
        return foot.distance(from: coordinate)
    }

    /// Returns the minimum distance between the *Point* and the segment.
    public func distanceFrom(point: Point) -> CLLocationDistance {
        distanceFrom(coordinate: point.coordinate)
    }

}

extension LineString {

    /// Returns the minimum distance between a *Point* and the receiver, being the distance
    /// from a line the minimum distance between the point and any segment of the line.
    public func distanceFrom(
        point: Point)
        -> CLLocationDistance
    {
        distanceFrom(coordinate: point.coordinate)
    }

    /// Returns the minimum distance between a coordinate and the receiver, being the distance
    /// from a line the minimum distance between the coordinate and any segment of the line.
    public func distanceFrom(
        coordinate: Coordinate3D)
        -> CLLocationDistance
    {
        var bestDistance: CLLocationDistance = .greatestFiniteMagnitude

        for segment in lineSegments {
            let distance = segment.distanceFrom(coordinate: coordinate)

            if distance < bestDistance {
                bestDistance = distance
            }
        }

        return bestDistance
    }

}
