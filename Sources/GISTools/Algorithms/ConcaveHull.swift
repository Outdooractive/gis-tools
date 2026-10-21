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

        let filteredTriangles = ConcaveHullBuilder.filter(
            triangles: triangles,
            maxEdgeLength: maxEdgeLength,
            projection: projection)

        guard filteredTriangles.isNotEmpty else { return nil }

        if filteredTriangles.count == 1 {
            return MultiPolygon(unchecked: [
                Self.polygon(for: filteredTriangles[0], projection: projection)
            ])
        }

        // Geocentric and antimeridian-crossing inputs keep the previous
        // overlay-based merge path, which handles their coordinate frames.
        if projection.isGeocentric || ConcaveHullBuilder.crossesAntimeridian(snappedSelf) {
            return Union.unionPolygons(filteredTriangles.map {
                Self.polygon(for: $0, projection: projection)
            })
        }

        // The surviving triangles form a planar mesh. Its boundary is the set
        // of directed triangle edges that have no opposite counterpart, so
        // the union can be assembled without running the full polygon
        // overlay algorithm over thousands of triangles.
        let boundary = ConcaveHullBuilder.boundaryEdges(
            of: filteredTriangles,
            projection: projection)
        let assembled = Overlay.polygons(fromBoundaryEdges: boundary)

        guard assembled.isNotEmpty else {
            return Union.unionPolygons(filteredTriangles.map {
                Self.polygon(for: $0, projection: projection)
            })
        }

        return MultiPolygon(unchecked: assembled)
    }

    private static func polygon(
        for triangle: Triangle,
        projection: Projection
    ) -> Polygon {
        let p1 = Coordinate3D(x: triangle.a.x, y: triangle.a.y, projection: projection)
        let p2 = Coordinate3D(x: triangle.b.x, y: triangle.b.y, projection: projection)
        let p3 = Coordinate3D(x: triangle.c.x, y: triangle.c.y, projection: projection)
        return Polygon(unchecked: [[p1, p2, p3, p1]])
    }

}

// MARK: - Boundary construction

private enum ConcaveHullBuilder {

    private struct DirectedEdge: Hashable {
        let start: Pt
        let end: Pt
    }

    private struct UnitVector {
        let x: Double
        let y: Double
        let z: Double
    }

    static func crossesAntimeridian(_ geoJson: GeoJson) -> Bool {
        switch geoJson {
        case let geometry as GeoJsonGeometry:
            return geometry.crossesAntimeridian

        case let feature as Feature:
            return feature.crossesAntimeridian

        case let featureCollection as FeatureCollection:
            return featureCollection.crossesAntimeridian

        default:
            return false
        }
    }

    static func filter(
        triangles: [Triangle],
        maxEdgeLength: Double,
        projection: Projection
    ) -> [Triangle] {
        if projection == .epsg4326 {
            var vectors: [Pt: UnitVector] = [:]
            vectors.reserveCapacity(triangles.count * 3)

            func vector(for point: Pt) -> UnitVector {
                if let vector = vectors[point] {
                    return vector
                }

                let latitude = point.y * Double.pi / 180.0
                let longitude = point.x * Double.pi / 180.0
                let cosLatitude = cos(latitude)
                let vector = UnitVector(
                    x: cosLatitude * cos(longitude),
                    y: cosLatitude * sin(longitude),
                    z: sin(latitude))
                vectors[point] = vector
                return vector
            }

            func distance(_ a: Pt, _ b: Pt) -> Double {
                let first = vector(for: a)
                let second = vector(for: b)
                let crossX = first.y * second.z - first.z * second.y
                let crossY = first.z * second.x - first.x * second.z
                let crossZ = first.x * second.y - first.y * second.x
                let crossLength = sqrt(
                    crossX * crossX
                        + crossY * crossY
                        + crossZ * crossZ)
                let dot = first.x * second.x
                    + first.y * second.y
                    + first.z * second.z
                return GISTool.earthRadius * atan2(crossLength, dot)
            }

            return triangles.filter { triangle in
                distance(triangle.a, triangle.b) <= maxEdgeLength
                    && distance(triangle.b, triangle.c) <= maxEdgeLength
                    && distance(triangle.a, triangle.c) <= maxEdgeLength
            }
        }

        if projection.isGeographic {
            return triangles.filter { triangle in
                let a = Coordinate3D(
                    x: triangle.a.x,
                    y: triangle.a.y,
                    projection: projection)
                let b = Coordinate3D(
                    x: triangle.b.x,
                    y: triangle.b.y,
                    projection: projection)
                let c = Coordinate3D(
                    x: triangle.c.x,
                    y: triangle.c.y,
                    projection: projection)

                return a.distance(to: b) <= maxEdgeLength
                    && b.distance(to: c) <= maxEdgeLength
                    && a.distance(to: c) <= maxEdgeLength
            }
        }

        return triangles.filter { triangle in
            hypot(triangle.b.x - triangle.a.x, triangle.b.y - triangle.a.y) <= maxEdgeLength
                && hypot(triangle.c.x - triangle.b.x, triangle.c.y - triangle.b.y) <= maxEdgeLength
                && hypot(triangle.c.x - triangle.a.x, triangle.c.y - triangle.a.y) <= maxEdgeLength
        }
    }

    static func boundaryEdges(
        of triangles: [Triangle],
        projection: Projection
    ) -> [(start: Coordinate3D, end: Coordinate3D)] {
        var edges = Set<DirectedEdge>()

        func add(_ start: Pt, _ end: Pt) {
            let edge = DirectedEdge(start: start, end: end)
            let reverse = DirectedEdge(start: end, end: start)
            if edges.contains(reverse) {
                edges.remove(reverse)
            }
            else {
                edges.insert(edge)
            }
        }

        for triangle in triangles {
            let a = triangle.a
            let b = triangle.b
            let c = triangle.c
            let cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

            guard cross != 0.0 else { continue }

            if cross > 0.0 {
                add(a, b)
                add(b, c)
                add(c, a)
            }
            else {
                add(a, c)
                add(c, b)
                add(b, a)
            }
        }

        let sorted = edges.sorted { lhs, rhs in
            if lhs.start.x != rhs.start.x {
                return lhs.start.x < rhs.start.x
            }
            if lhs.start.y != rhs.start.y {
                return lhs.start.y < rhs.start.y
            }
            if lhs.end.x != rhs.end.x {
                return lhs.end.x < rhs.end.x
            }
            return lhs.end.y < rhs.end.y
        }

        return sorted.map { edge in
            (
                start: Coordinate3D(
                    x: edge.start.x,
                    y: edge.start.y,
                    projection: projection),
                end: Coordinate3D(
                    x: edge.end.x,
                    y: edge.end.y,
                    projection: projection))
        }
    }

}
