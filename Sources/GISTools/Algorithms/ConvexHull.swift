#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-convex
// Monotone chain algorithm from https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain

extension GeoJson {

    /// Computes the convex hull of all coordinates in the receiver.
    ///
    /// Uses Andrew's monotone chain algorithm.
    /// Returns `nil` if there are fewer than 3 distinct points.
    public func convexHull() -> Polygon? {
        let coords = allCoordinates

        // Deduplicate
        let unique = Array(Set(coords))
        guard unique.count >= 3 else { return nil }

        // Handle anti-meridian: only applies to EPSG:4326 where longitude
        // is in degrees. For other projections the values are in projection
        // units (meters for 3857/4978) and a span > 180° does not indicate
        // a date-line crossing.
        let spansAntimeridian: Bool
        if projection == .epsg4326 {
            let minLon = unique.map(\.longitude).min() ?? 0
            let maxLon = unique.map(\.longitude).max() ?? 0
            spansAntimeridian = (maxLon - minLon) > 180.0
        }
        else {
            spansAntimeridian = false
        }

        let normalized: [Coordinate3D]
        if spansAntimeridian {
            normalized = unique.map { coord in
                Coordinate3D(
                    x: coord.longitude < 0 ? coord.longitude + 360.0 : coord.longitude,
                    y: coord.latitude,
                    z: coord.altitude,
                    m: coord.m,
                    projection: projection)
            }
        }
        else {
            normalized = unique
        }

        // Sort by x (longitude), then y (latitude)
        let sorted = normalized.sorted { a, b in
            if a.longitude != b.longitude {
                return a.longitude < b.longitude
            }
            return a.latitude < b.latitude
        }

        // Build lower hull
        var lower: [Coordinate3D] = []
        for point in sorted {
            while lower.count >= 2 {
                let a = lower[lower.count - 2]
                let b = lower[lower.count - 1]
                if cross(a, b, point) > 0 { break }
                lower.removeLast()
            }
            lower.append(point)
        }

        // Build upper hull
        var upper: [Coordinate3D] = []
        for point in sorted.reversed() {
            while upper.count >= 2 {
                let a = upper[upper.count - 2]
                let b = upper[upper.count - 1]
                if cross(a, b, point) > 0 { break }
                upper.removeLast()
            }
            upper.append(point)
        }

        // Remove last point of each (duplicate of first of the other)
        lower.removeLast()
        upper.removeLast()

        // Combine
        var hull = lower + upper

        // Close the ring
        hull.append(hull[0])

        // Normalize back if needed
        if spansAntimeridian {
            hull = hull.map { coord in
                let lon = coord.longitude > 180.0 ? coord.longitude - 360.0 : coord.longitude
                return Coordinate3D(x: lon, y: coord.latitude, z: coord.altitude, projection: projection)
            }
        }

        return Polygon([hull])
    }

    // MARK: - Cross product helper

    /// Cross product of vectors (a-o) and (b-o).
    /// > 0 means counter-clockwise turn, < 0 means clockwise, == 0 means collinear.
    private func cross(
        _ o: Coordinate3D,
        _ a: Coordinate3D,
        _ b: Coordinate3D
    ) -> Double {
        let lhs = (a.longitude - o.longitude) * (b.latitude - o.latitude)
        let rhs = (a.latitude - o.latitude) * (b.longitude - o.longitude)
        return lhs - rhs
    }

}
