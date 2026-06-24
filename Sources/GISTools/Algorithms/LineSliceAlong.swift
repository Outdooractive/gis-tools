#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-line-slice-along

extension LineString {

    /// Takes a specified distance along the line to a start point, and a specified distance along
    /// the line to a stop point and returns a subsection of the line in-between those points.
    ///
    /// When both endpoints of a cut segment have an ``altitude`` value, the
    /// interpolated start/stop points carry a linearly interpolated altitude.
    ///
    /// This can be useful for extracting only the part of a route between two distances.
    ///
    /// - Parameter startDistance: The distance along the line to the starting point, in meters
    /// - Parameter stopDistance: The distance along the line to the ending point, in meters
    ///
    /// - Returns: A `LineString` subsection, or `nil`.
    public func sliceAlong(
        startDistance: CLLocationDistance = 0.0,
        stopDistance: CLLocationDistance = .greatestFiniteMagnitude
    ) -> LineString? {
        guard coordinates.count >= 2 else { return nil }

        var slice: [Coordinate3D] = []
        var travelled: CLLocationDistance = 0.0

        for (index, coordinate) in coordinates.enumerated() {
            if startDistance >= travelled, index == coordinates.count - 1 {
                break
            }

            if travelled > startDistance, slice.isEmpty {
                let overshot = startDistance - travelled
                if overshot == 0.0 {
                    slice.append(contentsOf: [coordinate, coordinate])
                    return LineString(slice)
                }

                slice.append(interpolate(
                    from: coordinates[index - 1],
                    to: coordinate,
                    overshot: overshot,
                    projection: projection))
            }

            if travelled >= stopDistance {
                let overshot = stopDistance - travelled
                if overshot == 0.0 {
                    slice.append(coordinate)
                    if slice.count == 1 {
                        slice.append(coordinate)
                    }
                    return LineString(slice)
                }

                slice.append(interpolate(
                    from: coordinates[index - 1],
                    to: coordinate,
                    overshot: overshot,
                    projection: projection))
                return LineString(slice)
            }

            if travelled >= startDistance {
                slice.append(coordinate)
            }

            if index == coordinates.count - 1 {
                return LineString(slice)
            }

            travelled += coordinate.distance(from: coordinates[index + 1])
        }

        if travelled < startDistance {
            return nil
        }

        let last = coordinates[coordinates.count - 1]
        return LineString([last, last])
    }

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

extension Feature {

    /// Takes a specified distance along the line to a start point, and a specified distance along
    /// the line to a stop point and returns a subsection of the line in-between those points.
    ///
    /// When both endpoints of a cut segment have an ``altitude`` value, the
    /// interpolated start/stop points carry a linearly interpolated altitude.
    ///
    /// This can be useful for extracting only the part of a route between two distances.
    ///
    /// - Parameters:
    /// - Parameter startDistance: The distance along the line to the starting point, in meters
    /// - Parameter stopDistance: The distance along the line to the ending point, in meters
    ///
    /// - Returns: A `Feature` subsection, or `nil`.
    public func sliceAlong(
        startDistance: CLLocationDistance = 0.0,
        stopDistance: CLLocationDistance = .greatestFiniteMagnitude
    ) -> Feature? {
        guard let lineString = geometry as? LineString,
              let lineSlice = lineString.sliceAlong(
                startDistance: startDistance,
                stopDistance: stopDistance)
        else { return nil }

        var newFeature = Feature(
            lineSlice,
            id: id,
            properties: properties,
            calculateBoundingBox: (self.boundingBox != nil))
        newFeature.foreignMembers = foreignMembers
        return newFeature
    }

}
