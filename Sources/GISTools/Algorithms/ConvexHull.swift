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

        // Handle anti-meridian: if the bounding box crosses the date line,
        // shift negative longitudes to [0, 360] range.
        let minLon = unique.map(\.longitude).min() ?? 0
        let maxLon = unique.map(\.longitude).max() ?? 0
        let spansAntimeridian = (maxLon - minLon) > 180.0

        let normalized: [Coordinate3D]
        if spansAntimeridian {
            normalized = unique.map { coord in
                var c = coord
                c = Coordinate3D(
                    latitude: c.latitude,
                    longitude: c.longitude < 0 ? c.longitude + 360.0 : c.longitude)
                return c
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
                return Coordinate3D(latitude: coord.latitude, longitude: lon)
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
