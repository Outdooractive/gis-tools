import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-tesselate

extension Polygon {

    /// Tesselates the polygon into a collection of triangle polygons using the
    /// ear-clipping algorithm.
    ///
    /// The result is a ``FeatureCollection`` of ``Polygon`` features, each
    /// representing a single triangle. Polygons with holes are handled by
    /// bridging each hole to the outer ring before triangulation.
    ///
    /// - Returns: A ``FeatureCollection`` of triangle polygons.
    public func tesselated() -> FeatureCollection {
        Tesselate.tesselate(polygon: self)
    }

}

extension MultiPolygon {

    /// Tesselates each constituent polygon and merges the results.
    ///
    /// - Returns: A ``FeatureCollection`` of triangle polygons.
    public func tesselated() -> FeatureCollection {
        let collections = polygons.map { $0.tesselated() }
        return FeatureCollection(collections.flatMap(\.features))
    }

}

// MARK: - Implementation

private enum Tesselate {

    static func tesselate(polygon: Polygon) -> FeatureCollection {
        let rings = polygon.rings
        guard rings.count >= 1 else { return FeatureCollection() }

        // Build vertex list from outer ring (ensure CCW)
        let outerCoords = Tesselate.toCCW(ring: rings[0])
        var vertices = outerCoords.map { Vertex($0) }

        // Bridge holes into the vertex list
        for ring in rings.dropFirst() {
            let holeCoords = Tesselate.toCCW(ring: ring)
            var holeVerts = holeCoords.map { Vertex($0) }
            guard holeVerts.isNotEmpty else { continue }

            bridgeHole(&vertices, &holeVerts)
        }

        guard vertices.count >= 3 else { return FeatureCollection() }

        // Ear clipping
        let triangles = earClipTriangulation(&vertices)
        let features = triangles.map { triVertices in
            let coords = triVertices.map { $0.coordinate } + [triVertices[0].coordinate]
            return Feature(Polygon(unchecked: [coords]))
        }

        return FeatureCollection(features)
    }

    // MARK: - Hole bridging

    /// Bridge a hole into the main vertex list by finding the closest pair
    /// of vertices (one on the main ring, one on the hole) and inserting
    /// the hole vertices at that point.
    private static func bridgeHole(_ vertices: inout [Vertex], _ hole: inout [Vertex]) {
        guard hole.isNotEmpty else { return }

        // Find closest pair: main vertex i, hole vertex j
        var bestDist = Double.infinity
        var bestI = 0
        var bestJ = 0

        for i in 0 ..< vertices.count {
            let vi = vertices[i]
            for j in 0 ..< hole.count {
                let vj = hole[j]
                let dx = vi.x - vj.x
                let dy = vi.y - vj.y
                let dist = dx * dx + dy * dy
                if dist < bestDist {
                    bestDist = dist
                    bestI = i
                    bestJ = j
                }
            }
        }

        // Insert hole vertices at position bestI, bridging via duplicate
        // The hole vertices are inserted in order starting from bestJ,
        // followed by bestJ as the bridge-back vertex.
        let count = hole.count
        var insert: [Vertex] = []
        insert.reserveCapacity(count + 2)

        // Bridge from main ring to hole
        insert.append(vertices[bestI])

        // All hole vertices in order from bestJ
        for k in 0 ..< count {
            insert.append(hole[(bestJ + k) % count])
        }

        // Bridge back
        insert.append(hole[bestJ])

        vertices.replaceSubrange(bestI ... bestI, with: insert)
    }

    // MARK: - Ear clipping

    private static func earClipTriangulation(_ vertices: inout [Vertex]) -> [[Vertex]] {
        guard vertices.count >= 3 else { return [] }

        var triangles: [[Vertex]] = []

        while vertices.count > 3 {
            let count = vertices.count
            var earFound = false

            for i in 0 ..< count {
                let prev = vertices[(i + count - 1) % count]
                let curr = vertices[i]
                let next = vertices[(i + 1) % count]

                guard isConvex(prev, curr, next) else { continue }
                guard isEar(prev, curr, next, vertices) else { continue }

                triangles.append([prev, curr, next])
                vertices.remove(at: i)
                earFound = true
                break
            }

            if !earFound {
                // Degenerate polygon — force-remove the most reflex vertex
                let reflex = findMostReflex(vertices)
                if let index = vertices.firstIndex(of: reflex) {
                    let prev = vertices[(index + count - 1) % count]
                    let curr = vertices[index]
                    let next = vertices[(index + 1) % count]
                    triangles.append([prev, curr, next])
                    vertices.remove(at: index)
                }
                else {
                    break
                }
            }
        }

        if vertices.count == 3 {
            triangles.append(vertices)
        }

        return triangles
    }

    /// Check if the angle at `curr` is convex (< 180°) for a CCW polygon.
    private static func isConvex(_ prev: Vertex, _ curr: Vertex, _ next: Vertex) -> Bool {
        cross(prev, curr, next) > 0.0
    }

    /// Check if no other vertex lies inside the triangle (prev, curr, next).
    private static func isEar(
        _ prev: Vertex,
        _ curr: Vertex,
        _ next: Vertex,
        _ vertices: [Vertex]
    ) -> Bool {
        for v in vertices {
            if v == prev || v == curr || v == next { continue }
            if pointInTriangle(v, prev, curr, next) {
                return false
            }
        }
        return true
    }

    /// Find the most reflex (deepest interior angle) vertex as a fallback.
    private static func findMostReflex(_ vertices: [Vertex]) -> Vertex {
        var worst = vertices[0]
        var worstDot = 1.0

        let count = vertices.count
        for i in 0 ..< count {
            let prev = vertices[(i + count - 1) % count]
            let curr = vertices[i]
            let next = vertices[(i + 1) % count]

            let ax = prev.x - curr.x
            let ay = prev.y - curr.y
            let bx = next.x - curr.x
            let by = next.y - curr.y
            let lenA = sqrt(ax * ax + ay * ay)
            let lenB = sqrt(bx * bx + by * by)

            guard lenA > 0, lenB > 0 else { continue }
            let dot = (ax * bx + ay * by) / (lenA * lenB)

            if dot < worstDot {
                worstDot = dot
                worst = curr
            }
        }

        return worst
    }

        /// Return the ring's coordinates in CCW order (dropping the closing repeat).
    private static func toCCW(ring: Ring) -> [Coordinate3D] {
        let coords = Array(ring.coordinates.dropLast())
        if ring.isClockwise {
            return coords.reversed()
        }
        return coords
    }

    // MARK: - Helpers

    /// Cross product of vectors (prev -> curr) and (curr -> next).
    private static func cross(_ prev: Vertex, _ curr: Vertex, _ next: Vertex) -> Double {
        (curr.x - prev.x) * (next.y - curr.y) - (curr.y - prev.y) * (next.x - curr.x)
    }

    /// Check if point `p` is inside the triangle (a, b, c) using barycentric
    /// coordinates.
    private static func pointInTriangle(
        _ p: Vertex,
        _ a: Vertex,
        _ b: Vertex,
        _ c: Vertex
    ) -> Bool {
        let d1 = sign(p, a, b)
        let d2 = sign(p, b, c)
        let d3 = sign(p, c, a)

        let hasNeg = d1 < 0 || d2 < 0 || d3 < 0
        let hasPos = d1 > 0 || d2 > 0 || d3 > 0

        return !(hasNeg && hasPos)
    }

    private static func sign(_ p: Vertex, _ q1: Vertex, _ q2: Vertex) -> Double {
        (p.x - q2.x) * (q1.y - q2.y) - (q1.x - q2.x) * (p.y - q2.y)
    }

}

// MARK: - Vertex

private struct Vertex: Hashable, Sendable {

    let x: Double
    let y: Double
    let coordinate: Coordinate3D

    init(_ coordinate: Coordinate3D) {
        self.x = coordinate.longitude
        self.y = coordinate.latitude
        self.coordinate = coordinate
    }

}
