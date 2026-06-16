#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-planepoint

extension Polygon {

    /// Interpolates the z-value at a point on a triangular polygon.
    ///
    /// The polygon must be a triangle (3 vertices) with z-values (altitudes) assigned
    /// to each vertex. The result is the interpolated z-value at the given point using
    /// barycentric coordinates.
    ///
    /// - Parameter point: The query coordinate
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: The interpolated z-value, or `nil` if the point is outside the triangle
    ///   or the polygon is not a triangle
    public func planepoint(
        _ point: Coordinate3D,
        gridSize: Double? = nil
    ) -> CLLocationDistance? {
        guard let ring = outerRing else { return nil }
        let coords = ring.coordinates

        // A triangle has 3 unique vertices. The ring may have 4 coordinates
        // if the last one closes the ring (same as first).
        var pts = coords
        if pts.count == 4, pts.first == pts.last {
            pts = Array(pts.dropLast())
        }
        guard pts.count == 3 else { return nil }

        let snappedPoint: Coordinate3D
        let snappedCoords: [Coordinate3D]
        if let gridSize {
            snappedPoint = point.snappedToGrid(tolerance: gridSize)
            snappedCoords = pts.map { $0.snappedToGrid(tolerance: gridSize) }
        } else {
            snappedPoint = point
            snappedCoords = pts
        }

        let p = snappedPoint.projected(to: projection)
        let a = snappedCoords[0].projected(to: projection)
        let b = snappedCoords[1].projected(to: projection)
        let c = snappedCoords[2].projected(to: projection)

        // Normalise antimeridian crossing: if the triangle spans >180° of
        // longitude, shift negative values by +360° so the Cartesian cross
        // product reflects the short path across the date line.
        let lons = [a.longitude, b.longitude, c.longitude, p.longitude]
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        let shift = (maxLon - minLon) > 180.0 ? 360.0 : 0.0

        func norm(_ coord: Coordinate3D) -> Coordinate3D {
            guard shift > 0, coord.longitude < 0 else { return coord }
            return Coordinate3D(
                latitude: coord.latitude,
                longitude: coord.longitude + shift,
                altitude: coord.altitude, m: coord.m)
        }

        let na = norm(a)
        let nb = norm(b)
        let nc = norm(c)
        let np = norm(p)

        // Barycentric coordinates using area ratios (cross products)
        let denom = (nb.longitude - na.longitude) * (nc.latitude - na.latitude)
            - (nc.longitude - na.longitude) * (nb.latitude - na.latitude)
        guard abs(denom) > 1e-15 else { return nil }

        let vb = ((np.longitude - na.longitude) * (nc.latitude - na.latitude)
            - (nc.longitude - na.longitude) * (np.latitude - na.latitude)) / denom
        let vc = ((nb.longitude - na.longitude) * (np.latitude - na.latitude)
            - (np.longitude - na.longitude) * (nb.latitude - na.latitude)) / denom
        let va = 1.0 - vb - vc

        guard va >= 0.0, vb >= 0.0, vc >= 0.0 else { return nil }

        let za = a.altitude ?? 0.0
        let zb = b.altitude ?? 0.0
        let zc = c.altitude ?? 0.0

        return va * za + vb * zb + vc * zc
    }

}

extension FeatureCollection {

    /// Converts a TIN (triangulated irregular network) into a point cloud by
    /// placing a point at the centroid of each triangle and interpolating its
    /// altitude from the triangle vertices.
    ///
    /// Each feature in the collection must contain a triangular ``Polygon``
    /// with z-values (altitudes) on its vertices. The result is a
    /// ``FeatureCollection`` of ``Point`` features, one per input triangle,
    /// with the interpolated altitude set on the coordinate.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``FeatureCollection`` of point features with interpolated altitudes
    public func tinToPointCloud(gridSize: Double? = nil) -> FeatureCollection {
        let points: [Feature] = features.compactMap { feature in
            guard let polygon = feature.geometry as? Polygon,
                  let centroid = polygon.centroid,
                  let z = polygon.planepoint(centroid.coordinate, gridSize: gridSize)
            else { return nil }

            var pointFeature = Feature(Point(Coordinate3D(
                latitude: centroid.coordinate.latitude,
                longitude: centroid.coordinate.longitude,
                altitude: z)))
            pointFeature.properties = feature.properties
            return pointFeature
        }
        return FeatureCollection(points)
    }

}
