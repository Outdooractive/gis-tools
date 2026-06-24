#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-along

extension LineString {

    /// Returns a coordinate at a specified distance along the line.
    ///
    /// When both endpoints of the segment containing the target distance have
    /// an ``altitude`` value, the result carries a linearly interpolated
    /// altitude. Otherwise the result has no altitude.
    ///
    /// - Parameter distance: The distance along the line, in meters.
    ///
    /// - Returns: A *Coordinate3D* *distance* meters along the line.
    public func coordinateAlong(distance: CLLocationDistance) -> Coordinate3D {
        var travelled: CLLocationDistance = 0.0

        for (index, coordinate) in coordinates.enumerated() {
            if distance >= travelled, index == coordinates.count - 1 {
                break
            }

            if travelled >= distance {
                let overshot: CLLocationDistance = distance - travelled
                if overshot == 0.0 {
                    return coordinate
                }

                return interpolate(
                    from: coordinates[index - 1],
                    to: coordinate,
                    overshot: overshot,
                    projection: projection)
            }
            else {
                travelled += coordinate.distance(from: coordinates[index + 1])
            }
        }

        return coordinates[coordinates.count - 1]
    }

    /// Returns a `Point` at a specified distance along the line.
    ///
    /// When both endpoints of the segment containing the target distance have
    /// an ``altitude`` value, the result carries a linearly interpolated
    /// altitude. Otherwise the result has no altitude.
    ///
    /// - Parameter distance: The distance along the line, in meters
    ///
    /// - Returns: A *Point* *distance* meters along the line.
    public func pointAlong(distance: CLLocationDistance) -> Point {
        Point(coordinateAlong(distance: distance))
    }

    /// Returns the distance in meters from the start of the line to the nearest
    /// point on the line from the given coordinate.
    ///
    /// - Parameter coordinate: A coordinate near the line
    /// - Parameter tolerance: Maximum distance from the line in meters (default `1.0`).
    /// - Returns: The distance along the line in meters, or `nil` if the coordinate
    ///   is further than `tolerance` from the line.
    public func distanceAlong(
        to coordinate: Coordinate3D,
        tolerance: CLLocationDistance = 1.0
    ) -> CLLocationDistance? {
        guard coordinates.count >= 2 else { return nil }

        let projected = coordinate.projected(to: projection)
        var bestDistance = Double.greatestFiniteMagnitude
        var bestSegment: (index: Int, foot: Coordinate3D)? = nil

        for (i, segment) in lineSegments.enumerated() {
            guard let foot = segment.perpendicularFoot(from: projected, clampToEnds: true) else { continue }
            let d = projected.distance(from: foot)
            if d < bestDistance {
                bestDistance = d
                bestSegment = (i, foot)
            }
        }

        guard let (segIndex, foot) = bestSegment,
              bestDistance < tolerance
        else { return nil }

        var travelled: CLLocationDistance = 0.0
        for i in 0..<segIndex {
            travelled += coordinates[i].distance(from: coordinates[i + 1])
        }

        travelled += coordinates[segIndex].distance(from: foot)
        return travelled
    }

    // MARK: - Private

    /// Interpolate between two segment endpoints.
    ///
    /// For EPSG:4326 the 2-D interpolation follows the geodesic arc via
    /// `destination`; for other CRS a straight line is used.
    /// Z is always linearly interpolated when both endpoints have altitude.
    ///
    /// - Parameter overshot: How far `coord` is past the target (negative).
    /// - Parameter projection: The receiver's projection.
    private func interpolate(
        from prev: Coordinate3D,
        to coord: Coordinate3D,
        overshot: CLLocationDistance,
        projection: Projection
    ) -> Coordinate3D {
        var result: Coordinate3D
        switch projection {
        case .epsg4326:
            // Go from coord back toward prev by |overshot| meters.
            let bearing = coord.bearing(to: prev)
            result = coord.destination(distance: -overshot, bearing: bearing)
        default:
            // Straight‑line interpolation.
            let segmentLength = coord.distance(from: prev)
            let weight = 1.0 + overshot / segmentLength
            let lat = prev.latitude + weight * (coord.latitude - prev.latitude)
            let lon = prev.longitude + weight * (coord.longitude - prev.longitude)
            result = Coordinate3D(x: lon, y: lat, projection: projection)
        }

        if let za = prev.altitude,
           let zb = coord.altitude
        {
            let segmentLength = coord.distance(from: prev)
            let weight = 1.0 + overshot / segmentLength
            result.altitude = za + weight * (zb - za)
        }

        return result
    }

}
