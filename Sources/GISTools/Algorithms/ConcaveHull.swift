#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-concave

extension GeoJson {

    /// Computes the concave hull of all coordinates in the receiver.
    ///
    /// Uses Delaunay triangulation internally, then removes triangles
    /// whose edges exceed `maxEdgeLength`, and merges the survivors.
    /// Returns `nil` if there are fewer than 3 distinct points or if
    /// no triangles survive the `maxEdgeLength` filter.
    ///
    /// - Parameter maxEdgeLength: The maximum edge length in meters for
    ///   a triangle to be included in the hull
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    ///
    /// - Returns: A `MultiPolygon` representing the concave hull
    public func concaveHull(
        maxEdgeLength: CLLocationDistance,
        gridSize: Double? = nil
    ) -> MultiPolygon? {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let coords = snappedSelf.allCoordinates
        let unique = Set(coords)
        guard unique.count >= 3 else { return nil }

        let points = unique.map { Pt(x: $0.longitude, y: $0.latitude) }
        let triangles = Triangulator.triangulate(points)

        guard triangles.isNotEmpty else { return nil }

        let polygons: [Polygon] = triangles.compactMap { triangle in
            let p1 = Coordinate3D(x: triangle.a.x, y: triangle.a.y, projection: projection)
            let p2 = Coordinate3D(x: triangle.b.x, y: triangle.b.y, projection: projection)
            let p3 = Coordinate3D(x: triangle.c.x, y: triangle.c.y, projection: projection)

            let d1 = p1.distance(to: p2)
            let d2 = p2.distance(to: p3)
            let d3 = p1.distance(to: p3)

            guard d1 <= maxEdgeLength, d2 <= maxEdgeLength, d3 <= maxEdgeLength
            else { return nil }

            return Polygon([[p1, p2, p3, p1]])
        }

        guard polygons.isNotEmpty else { return nil }

        if polygons.count == 1 {
            return MultiPolygon(unchecked: polygons)
        }

        return Union.unionPolygons(polygons)
    }

}
