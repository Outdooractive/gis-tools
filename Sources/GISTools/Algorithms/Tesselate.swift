import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-tesselate

extension Polygon {

    /// Tesselates the polygon into a collection of triangle polygons using the
    /// ear-clipping algorithm.
    ///
    /// The result is a ``FeatureCollection`` of ``Polygon`` features, each
    /// representing a single triangle. Polygons with holes are handled by
    /// bridging each hole to the outer ring before triangulation; the hole is
    /// traversed in the opposite winding direction and both bridge endpoints
    /// are duplicated so the combined ring stays closed.
    ///
    /// Rings that cross the projection's wraparound axis (the antimeridian for
    /// EPSG:4326, ±`originShift` for EPSG:3857) are unwrapped into a
    /// continuous frame before triangulation, and the emitted triangle
    /// coordinates are normalized back into the source range. This keeps the
    /// triangles on the short side of the seam instead of triangulating the
    /// long way around the world.
    ///
    /// Degenerate rings (collinear vertices, repeated coordinates) are
    /// simplified first. If no valid ear remains, triangulation stops instead
    /// of emitting overlapping triangles.
    ///
    /// All projections are supported. The ear-clipping algorithm uses
    /// Cartesian math on native XY values.
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
        // ECEF x/y/z are not a map plane: triangulating them directly would
        // produce triangles that do not project back onto the polygon. Work
        // in geographic coordinates and project the resulting triangles back
        // into the source CRS.
        if polygon.projection.isGeocentric {
            let geographic = tesselate(polygon: polygon.projected(to: .epsg4326))
            return FeatureCollection(geographic.features.compactMap { feature in
                guard let triangle = feature.geometry as? Polygon else { return nil }
                return Feature(triangle.projected(to: polygon.projection))
            })
        }

        let rings = polygon.rings
        guard let outerRing = rings.first,
              outerRing.coordinates.count >= 4
        else { return FeatureCollection() }

        let projection = polygon.projection
        let extent = projection.wraparoundExtent

        guard var outer = unwrappedVertices(
            for: outerRing,
            projection: projection,
            extent: extent)
        else { return FeatureCollection() }

        makeCounterClockwise(&outer)

        var holes: [[Vertex]] = []
        for ring in rings.dropFirst() {
            guard var hole = unwrappedVertices(
                for: ring,
                projection: projection,
                extent: extent)
            else { continue }

            align(hole: &hole, with: outer, extent: extent)
            makeClockwise(&hole)
            if hole.count >= 3 {
                holes.append(hole)
            }
        }

        // Process rightmost holes first; this keeps the bridge candidates
        // for a hole from having to cross holes that have not been merged
        // yet more often than necessary.
        holes.sort { lhs, rhs in
            (lhs.map(\.x).max() ?? 0.0) > (rhs.map(\.x).max() ?? 0.0)
        }

        for index in holes.indices {
            bridge(
                hole: holes[index],
                remainingHoles: Array(holes[(index + 1)...]),
                into: &outer)
        }

        guard outer.count >= 3 else { return FeatureCollection() }

        let triangles = earClip(&outer)
        let features = triangles.compactMap { triangle -> Feature? in
            let coordinates = triangle.map {
                normalized($0, projection: projection)
            }
            let ring = coordinates + [coordinates[0]]
            guard let polygon = Polygon([ring]) else { return nil }
            return Feature(polygon)
        }

        return FeatureCollection(features)
    }

    // MARK: - Ring preparation

    /// Returns the ring's vertices without the closing repeat, after removing
    /// repeated and collinear vertices, unwrapped into a continuous frame.
    private static func unwrappedVertices(
        for ring: Ring,
        projection: Projection,
        extent: Double?
    ) -> [Vertex]? {
        var coordinates = ring.coordinates
        if coordinates.count > 1,
           coordinates.first == coordinates.last
        {
            coordinates.removeLast()
        }
        guard coordinates.count >= 3 else { return nil }

        var vertices = coordinates.map { Vertex($0) }

        if let extent, extent > 0.0 {
            let period = 2.0 * extent
            for index in 1 ..< vertices.count {
                var x = vertices[index].x
                while x - vertices[index - 1].x > extent {
                    x -= period
                }
                while vertices[index - 1].x - x > extent {
                    x += period
                }
                vertices[index].x = x
            }
        }

        removeDegenerateVertices(&vertices)
        return vertices.count >= 3 ? vertices : nil
    }

    /// Shifts a hole by whole world copies so it sits in the same unwrapped
    /// frame as the outer ring.
    private static func align(
        hole: inout [Vertex],
        with outer: [Vertex],
        extent: Double?
    ) {
        guard let extent, extent > 0.0,
              hole.isNotEmpty,
              outer.isNotEmpty
        else { return }

        let period = 2.0 * extent
        let outerCenter = outer.reduce(0.0) { $0 + $1.x } / Double(outer.count)
        let holeCenter = hole.reduce(0.0) { $0 + $1.x } / Double(hole.count)
        let shift = ((outerCenter - holeCenter) / period).rounded() * period
        guard shift != 0.0 else { return }

        for index in hole.indices {
            hole[index].x += shift
        }
    }

    private static func makeCounterClockwise(_ vertices: inout [Vertex]) {
        if signedArea(vertices) < 0.0 {
            vertices.reverse()
        }
    }

    private static func makeClockwise(_ vertices: inout [Vertex]) {
        if signedArea(vertices) > 0.0 {
            vertices.reverse()
        }
    }

    // MARK: - Hole bridging

    /// Bridges one hole into the outer ring.
    ///
    /// The bridge starts at the hole's rightmost vertex and ends at the
    /// nearest outer-ring vertex for which the connecting segment does not
    /// cross any ring edge and whose midpoint lies inside the current ring.
    /// Both endpoints are duplicated so the combined ring remains closed.
    private static func bridge(
        hole: [Vertex],
        remainingHoles: [[Vertex]],
        into outer: inout [Vertex]
    ) {
        guard hole.count >= 3,
              let holeIndex = hole.indices.max(by: {
                  hole[$0].x == hole[$1].x
                      ? hole[$0].y < hole[$1].y
                      : hole[$0].x < hole[$1].x
              })
        else { return }

        let holeVertex = hole[holeIndex]
        var bestOuterIndex: Int?
        var bestDistance = Double.infinity
        var fallbackOuterIndex: Int?
        var fallbackDistance = Double.infinity

        for index in outer.indices {
            let outerVertex = outer[index]
            let dx = outerVertex.x - holeVertex.x
            let dy = outerVertex.y - holeVertex.y
            let distance = dx * dx + dy * dy
            if distance < fallbackDistance {
                fallbackDistance = distance
                fallbackOuterIndex = index
            }

            guard isVisibleBridge(
                holeVertex,
                outerVertex,
                outer: outer,
                holes: [hole] + remainingHoles)
            else { continue }

            if distance < bestDistance {
                bestDistance = distance
                bestOuterIndex = index
            }
        }

        // A valid simple polygon always has a visible vertex for its
        // rightmost hole vertex. The fallback keeps pathological input from
        // silently dropping the hole; ear clipping will refuse to emit
        // overlapping triangles if the bridge is invalid.
        guard let outerIndex = bestOuterIndex ?? fallbackOuterIndex else { return }
        let outerVertex = outer[outerIndex]

        var insertion: [Vertex] = []
        insertion.reserveCapacity(hole.count + 2)
        for offset in 0 ..< hole.count {
            insertion.append(hole[(holeIndex + offset) % hole.count])
        }
        insertion.append(holeVertex)
        insertion.append(outerVertex)

        outer.insert(contentsOf: insertion, at: outerIndex + 1)
    }

    private static func isVisibleBridge(
        _ from: Vertex,
        _ to: Vertex,
        outer: [Vertex],
        holes: [[Vertex]]
    ) -> Bool {
        let midpoint = Vertex(
            x: (from.x + to.x) / 2.0,
            y: (from.y + to.y) / 2.0,
            coordinate: from.coordinate)
        guard pointInRing(midpoint, ring: outer) else { return false }

        if crossesAnyEdge(from, to, ring: outer) { return false }
        for hole in holes where crossesAnyEdge(from, to, ring: hole) {
            return false
        }
        return true
    }

    private static func crossesAnyEdge(
        _ from: Vertex,
        _ to: Vertex,
        ring: [Vertex]
    ) -> Bool {
        guard ring.count >= 2 else { return false }
        for index in ring.indices {
            let a = ring[index]
            let b = ring[(index + 1) % ring.count]
            if segmentsIntersect(from, to, a, b) {
                return true
            }
        }
        return false
    }

    // MARK: - Ear clipping

    private static func earClip(_ input: inout [Vertex]) -> [[Vertex]] {
        var vertices = input
        var triangles: [[Vertex]] = []

        while vertices.count > 3 {
            var earIndex: Int?

            for index in vertices.indices {
                let count = vertices.count
                let prev = vertices[(index + count - 1) % count]
                let curr = vertices[index]
                let next = vertices[(index + 1) % count]

                guard isConvex(prev, curr, next),
                      isEar(prev, curr, next, vertices)
                else { continue }

                triangles.append([prev, curr, next])
                vertices.remove(at: index)
                earIndex = index
                break
            }

            if earIndex == nil {
                // No ear: remove a collinear/repeated vertex, which may make
                // an ear available. If none exists, stop rather than emit
                // overlapping triangles.
                if let degenerate = degenerateVertexIndex(in: vertices) {
                    vertices.remove(at: degenerate)
                    continue
                }
                break
            }
        }

        if vertices.count == 3,
           abs(signedArea(vertices)) > Self.areaEpsilon
        {
            triangles.append(vertices)
        }

        input = vertices
        return triangles.filter { abs(signedArea($0)) > Self.areaEpsilon }
    }

    /// Check if the angle at `curr` is convex (< 180°) for a CCW ring.
    private static func isConvex(_ prev: Vertex, _ curr: Vertex, _ next: Vertex) -> Bool {
        cross(prev, curr, next) > Self.crossEpsilon
    }

    /// Check if no other vertex lies inside the triangle (prev, curr, next).
    private static func isEar(
        _ prev: Vertex,
        _ curr: Vertex,
        _ next: Vertex,
        _ vertices: [Vertex]
    ) -> Bool {
        for vertex in vertices {
            if sameCoordinate(vertex, prev)
                || sameCoordinate(vertex, curr)
                || sameCoordinate(vertex, next)
            {
                continue
            }
            if pointInTriangle(vertex, prev, curr, next) {
                return false
            }
        }
        return true
    }

    // MARK: - Degenerate vertices

    private static func removeDegenerateVertices(_ vertices: inout [Vertex]) {
        while vertices.count > 3 {
            if let index = degenerateVertexIndex(in: vertices) {
                vertices.remove(at: index)
            }
            else {
                break
            }
        }
    }

    private static func degenerateVertexIndex(in vertices: [Vertex]) -> Int? {
        let count = vertices.count
        guard count > 3 else { return nil }

        for index in 0 ..< count {
            let prev = vertices[(index + count - 1) % count]
            let curr = vertices[index]
            let next = vertices[(index + 1) % count]

            if sameCoordinate(prev, curr) || sameCoordinate(curr, next) {
                return index
            }

            // Collinear vertices are kept during preparation: for geographic
            // and projected CRSs the area is spherical, where a vertex that
            // is collinear in lon/lat is not collinear on the ellipsoid.
            // Dropping it would change the area. Ear clipping removes such a
            // vertex only if it is the last resort for a stuck ring.
        }
        return nil
    }

    // MARK: - Geometry helpers

    private static let crossEpsilon = 1.0e-14
    private static let areaEpsilon = 1.0e-20

    private static func signedArea(_ vertices: [Vertex]) -> Double {
        guard vertices.count >= 3 else { return 0.0 }

        var sum = 0.0
        for index in vertices.indices {
            let a = vertices[index]
            let b = vertices[(index + 1) % vertices.count]
            sum += a.x * b.y - b.x * a.y
        }
        return sum / 2.0
    }

    /// Cross product of vectors (prev -> curr) and (curr -> next).
    private static func cross(_ prev: Vertex, _ curr: Vertex, _ next: Vertex) -> Double {
        (curr.x - prev.x) * (next.y - curr.y)
            - (curr.y - prev.y) * (next.x - curr.x)
    }

    private static func sameCoordinate(_ lhs: Vertex, _ rhs: Vertex) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }

    private static func pointInTriangle(
        _ p: Vertex,
        _ a: Vertex,
        _ b: Vertex,
        _ c: Vertex
    ) -> Bool {
        let d1 = sign(p, a, b)
        let d2 = sign(p, b, c)
        let d3 = sign(p, c, a)

        let hasNegative = d1 < -Self.crossEpsilon
            || d2 < -Self.crossEpsilon
            || d3 < -Self.crossEpsilon
        let hasPositive = d1 > Self.crossEpsilon
            || d2 > Self.crossEpsilon
            || d3 > Self.crossEpsilon

        return !(hasNegative && hasPositive)
    }

    private static func pointInRing(_ point: Vertex, ring: [Vertex]) -> Bool {
        var inside = false

        for index in ring.indices {
            let a = ring[index]
            let b = ring[(index + 1) % ring.count]

            if pointOnSegment(point, a, b) {
                return true
            }

            let crosses = (a.y > point.y) != (b.y > point.y)
            if crosses {
                let x = (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x
                if point.x < x {
                    inside.toggle()
                }
            }
        }
        return inside
    }

    private static func pointOnSegment(_ p: Vertex, _ a: Vertex, _ b: Vertex) -> Bool {
        let turn = sign(p, a, b)
        guard abs(turn) <= Self.crossEpsilon else { return false }

        return p.x >= min(a.x, b.x) - Self.crossEpsilon
            && p.x <= max(a.x, b.x) + Self.crossEpsilon
            && p.y >= min(a.y, b.y) - Self.crossEpsilon
            && p.y <= max(a.y, b.y) + Self.crossEpsilon
    }

    private static func sign(_ p: Vertex, _ q1: Vertex, _ q2: Vertex) -> Double {
        (p.x - q2.x) * (q1.y - q2.y) - (q1.x - q2.x) * (p.y - q2.y)
    }

    private static func segmentsIntersect(
        _ a: Vertex,
        _ b: Vertex,
        _ c: Vertex,
        _ d: Vertex
    ) -> Bool {
        // Shared endpoints are not a crossing.
        if sameCoordinate(a, c)
            || sameCoordinate(a, d)
            || sameCoordinate(b, c)
            || sameCoordinate(b, d)
        {
            return false
        }

        let o1 = orientation(a, b, c)
        let o2 = orientation(a, b, d)
        let o3 = orientation(c, d, a)
        let o4 = orientation(c, d, b)

        if o1 != o2, o3 != o4 {
            return true
        }

        if o1 == 0, pointOnSegment(c, a, b) { return true }
        if o2 == 0, pointOnSegment(d, a, b) { return true }
        if o3 == 0, pointOnSegment(a, c, d) { return true }
        if o4 == 0, pointOnSegment(b, c, d) { return true }

        return false
    }

    private static func orientation(_ a: Vertex, _ b: Vertex, _ c: Vertex) -> Int {
        let value = (b.x - a.x) * (c.y - a.y)
            - (b.y - a.y) * (c.x - a.x)
        if value > Self.crossEpsilon { return 1 }
        if value < -Self.crossEpsilon { return -1 }
        return 0
    }

    private static func normalized(
        _ vertex: Vertex,
        projection: Projection
    ) -> Coordinate3D {
        Coordinate3D(
            x: vertex.x,
            y: vertex.y,
            z: vertex.coordinate.altitude,
            m: vertex.coordinate.m,
            projection: projection).normalized()
    }

}

// MARK: - Vertex

private struct Vertex: Hashable, Sendable {

    var x: Double
    var y: Double
    let coordinate: Coordinate3D

    init(_ coordinate: Coordinate3D) {
        self.x = coordinate.longitude
        self.y = coordinate.latitude
        self.coordinate = coordinate
    }

    init(x: Double, y: Double, coordinate: Coordinate3D) {
        self.x = x
        self.y = y
        self.coordinate = coordinate
    }

}
