import Foundation

// MARK: - Shared overlay infrastructure

/// Shared implementation for polygon overlay operations (union, intersection, etc.).
/// All geometry is reprojected to EPSG:3857 for uniform Cartesian tolerances.
/// This limits the usable latitude range to approximately ±85°.
enum Overlay {

    // MARK: - Types

    struct Edge {
        let start: Coordinate3D
        let end: Coordinate3D
        let polygonIndex: Int
        var boundingBox: BoundingBox?

        init(start: Coordinate3D, end: Coordinate3D, polygonIndex: Int) {
            self.start = start
            self.end = end
            self.polygonIndex = polygonIndex
            self.boundingBox = BoundingBox(coordinates: [start, end])
        }
    }

    struct SplitPoint {
        let coordinate: Coordinate3D
        let edgeIndex: Int
        let distanceAlong: Double
    }

    // MARK: - Public API

    /// Perform a polygon overlay operation.
    ///
    /// - Parameters:
    ///   - polygons: The input polygons (projected to EPSG:3857).
    ///   - boundaryTest: Returns `true` when an edge is part of the result boundary.
    /// - Returns: A MultiPolygon representing the overlay result, or `nil` if empty.
    static func overlayPolygons(
        _ polygons: [Polygon],
        boundaryTest: (Edge, [Polygon]) -> Bool
    ) -> MultiPolygon? {
        guard polygons.isNotEmpty else { return nil }
        guard polygons.count > 1 else { return MultiPolygon(unchecked: polygons) }

        let allEdges = extractEdges(from: polygons)
        guard allEdges.isNotEmpty else { return nil }

        let intersections = findIntersections(between: allEdges)
        let splitEdges = splitEdges(allEdges, at: intersections)
        guard splitEdges.isNotEmpty else { return nil }

        let boundary = splitEdges.filter { edge in
            boundaryTest(edge, polygons)
        }
        guard boundary.isNotEmpty else { return nil }

        let mergedBoundary = mergeReversePairs(boundary)
        guard mergedBoundary.isNotEmpty else { return nil }

        let rings = buildRings(from: mergedBoundary)
        let result = assemblePolygons(from: rings)
        guard result.isNotEmpty else { return nil }

        return MultiPolygon(unchecked: result)
    }

    // MARK: - Boundary test helpers

    /// Create a boundary test closure that compares the "inside result" status
    /// on both sides of each edge. An edge is part of the result boundary when
    /// the two sides have different "inside result" status.
    ///
    /// - Parameter isInsideResult: Returns `true` if a point is inside the
    ///   overlay result region.
    /// - Returns: A boundary test closure for ``overlayPolygons(_:boundaryTest:)``.
    static func makeBoundaryTest(
        isInsideResult: @escaping (Coordinate3D, [Polygon]) -> Bool
    ) -> (Edge, [Polygon]) -> Bool {
        { edge, polygons in
            let midLongitude = (edge.start.longitude + edge.end.longitude) * 0.5
            let midLatitude = (edge.start.latitude + edge.end.latitude) * 0.5
            let dx = edge.end.longitude - edge.start.longitude
            let dy = edge.end.latitude - edge.start.latitude

            let (left, right) = offsetPerpendicular(
                midLongitude: midLongitude,
                midLatitude: midLatitude,
                dx: dx,
                dy: dy,
                distance: 0.001)

            return isInsideResult(left, polygons) != isInsideResult(right, polygons)
        }
    }

    /// Offset a point perpendicular to an edge direction.
    /// Returns two points offset by `distance` meters to the left and right.
    static func offsetPerpendicular(
        midLongitude: Double,
        midLatitude: Double,
        dx: Double,
        dy: Double,
        distance: Double
    ) -> (left: Coordinate3D, right: Coordinate3D) {
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0 else {
            let p = Coordinate3D(x: midLongitude, y: midLatitude)
            return (p, p)
        }
        let offsetX = -dy / len * distance
        let offsetY = dx / len * distance
        let left = Coordinate3D(x: midLongitude + offsetX, y: midLatitude + offsetY)
        let right = Coordinate3D(x: midLongitude - offsetX, y: midLatitude - offsetY)
        return (left, right)
    }
}

// MARK: - BoundingBoxRepresentable

extension Overlay.Edge: BoundingBoxRepresentable {

    var projection: Projection { start.projection }

    func calculateBoundingBox() -> BoundingBox? {
        BoundingBox(coordinates: [start, end])
    }

    func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        boundingBox?.intersects(otherBoundingBox) ?? true
    }

}

// MARK: - Private helpers

private struct IndexedEdge: BoundingBoxRepresentable {
    let edge: Overlay.Edge
    let index: Int
    var boundingBox: BoundingBox?

    var projection: Projection { edge.projection }

    func calculateBoundingBox() -> BoundingBox? {
        edge.calculateBoundingBox()
    }

    func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        edge.boundingBox?.intersects(otherBoundingBox) ?? true
    }
}

private extension Overlay {

    // MARK: - Edge extraction

    static func extractEdges(from polygons: [Polygon]) -> [Edge] {
        var edges: [Edge] = []
        for (pIndex, polygon) in polygons.enumerated() {
            let rings = polygon.rings
            for ring in rings {
                let coords = ring.coordinates
                for i in 0..<(coords.count - 1) {
                    let start = coords[i]
                    let end = coords[i + 1]
                    if start != end {
                        edges.append(Edge(start: start, end: end, polygonIndex: pIndex))
                    }
                }
            }
        }
        return edges
    }

    // MARK: - Intersection finding

    static func findIntersections(between edges: [Edge]) -> [SplitPoint] {
        var result: [SplitPoint] = []
        let splitEps = 1.0e-10

        let indexedEdges = edges.enumerated().map { (i, e) in
            IndexedEdge(edge: e, index: i, boundingBox: e.boundingBox)
        }
        let tree = RTree(indexedEdges)

        for i in 0..<edges.count {
            guard let bbI = edges[i].boundingBox else { continue }

            let candidates = tree.search(inBoundingBox: bbI)

            for candidate in candidates {
                let j = candidate.index
                guard j > i else { continue }
                guard edges[i].polygonIndex != edges[j].polygonIndex else { continue }

                let segI = LineSegment(first: edges[i].start, second: edges[i].end)
                let segJ = LineSegment(first: edges[j].start, second: edges[j].end)

                guard segI.intersects(segJ, epsilon: 1.0e-12) else {
                    continue
                }

                guard let raw = segI.intersection(segJ, epsilon: 1.0e-12) else {
                    continue
                }

                let dI = distanceAlong(edges[i], at: raw)
                if dI > splitEps && dI < 1.0 - splitEps {
                    result.append(SplitPoint(coordinate: raw, edgeIndex: i, distanceAlong: dI))
                }

                let dJ = distanceAlong(edges[j], at: raw)
                if dJ > splitEps && dJ < 1.0 - splitEps {
                    result.append(SplitPoint(coordinate: raw, edgeIndex: j, distanceAlong: dJ))
                }
            }
        }

        var deduped: [SplitPoint] = []
        for sp in result {
            let isDup = deduped.contains { existing in
                existing.edgeIndex == sp.edgeIndex
                    && abs(existing.distanceAlong - sp.distanceAlong) < splitEps
            }
            if !isDup {
                deduped.append(sp)
            }
        }
        return deduped
    }

    /// Returns the signed parameter t along the edge, where t=0 is start and t=1 is end.
    static func distanceAlong(
        _ edge: Edge,
        at point: Coordinate3D
    ) -> Double {
        let dx = edge.end.longitude - edge.start.longitude
        let dy = edge.end.latitude - edge.start.latitude
        let lengthSq = dx * dx + dy * dy

        guard lengthSq > 0 else { return 0.0 }

        let px = point.longitude - edge.start.longitude
        let py = point.latitude - edge.start.latitude
        return (px * dx + py * dy) / lengthSq
    }

    // MARK: - Edge splitting

    static func splitEdges(
        _ edges: [Edge],
        at splitPoints: [SplitPoint]
    ) -> [Edge] {
        guard splitPoints.isNotEmpty else { return edges }

        var splitsByEdge: [Int: [SplitPoint]] = [:]
        for sp in splitPoints {
            splitsByEdge[sp.edgeIndex, default: []].append(sp)
        }
        for (index, var splits) in splitsByEdge {
            splits.sort { $0.distanceAlong < $1.distanceAlong }
            splitsByEdge[index] = splits
        }

        var result: [Edge] = []
        for (i, edge) in edges.enumerated() {
            if let splits = splitsByEdge[i] {
                var currentStart = edge.start
                for sp in splits {
                    if sp.distanceAlong <= 0 || sp.distanceAlong >= 1.0 {
                        continue
                    }
                    if currentStart != sp.coordinate {
                        result.append(Edge(start: currentStart, end: sp.coordinate, polygonIndex: edge.polygonIndex))
                    }
                    currentStart = sp.coordinate
                }
                if currentStart != edge.end {
                    result.append(Edge(start: currentStart, end: edge.end, polygonIndex: edge.polygonIndex))
                }
            } else {
                result.append(edge)
            }
        }
        return result
    }

    // MARK: - Duplicate removal

    static func mergeReversePairs(_ edges: [Edge]) -> [Edge] {
        var result: [Edge] = []
        var used = Set<Int>()

        for i in 0..<edges.count {
            guard !used.contains(i) else { continue }

            var merged = false
            for j in (i + 1)..<edges.count {
                guard !used.contains(j) else { continue }

                if edges[i].start == edges[j].end,
                   edges[i].end == edges[j].start
                {
                    result.append(edges[i])
                    used.insert(i)
                    used.insert(j)
                    merged = true
                    break
                }
            }
            if !merged {
                result.append(edges[i])
                used.insert(i)
            }
        }

        return result
    }

    // MARK: - Ring construction

    /// Normalizes a coordinate to a fixed-precision key for use as dictionary keys.
    static func vertexKey(_ coord: Coordinate3D) -> String {
        let q = 0.1
        let x = round(coord.x / q) * q
        let y = round(coord.y / q) * q
        return "\(x),\(y)"
    }

    static func buildRings(from edges: [Edge]) -> [[Coordinate3D]] {
        guard edges.isNotEmpty else { return [] }

        var adj: [String: [Int]] = [:]
        for (i, edge) in edges.enumerated() {
            let sk = vertexKey(edge.start)
            let ek = vertexKey(edge.end)
            adj[sk, default: []].append(i)
            adj[ek, default: []].append(i)
        }

        let snapEpsMeters = 0.5

        var used = Set<Int>()
        var rings: [[Coordinate3D]] = []

        for startIdx in edges.indices where !used.contains(startIdx) {
            var ring: [Coordinate3D] = [edges[startIdx].start, edges[startIdx].end]
            used.insert(startIdx)
            let startKey = vertexKey(edges[startIdx].start)
            var currentKey = vertexKey(edges[startIdx].end)

            func currentCoord() -> Coordinate3D {
                guard let last = ring.last else { return edges[startIdx].start }
                return last
            }

            while currentKey != startKey || ring.count < 4 {
                let candidates = adj[currentKey] ?? []
                var found = false
                for ci in candidates where !used.contains(ci) {
                    let e = edges[ci]
                    let sk = vertexKey(e.start)
                    let ek = vertexKey(e.end)
                    if ek == currentKey {
                        ring.append(e.start)
                        currentKey = sk
                    }
                    else {
                        ring.append(e.end)
                        currentKey = ek
                    }
                    used.insert(ci)
                    found = true
                    break
                }

                if !found {
                    let cur = currentCoord()
                    var best: (ci: Int, useEnd: Bool, dist: Double)?
                    for (i, e) in edges.enumerated() where !used.contains(i) {
                        let dStart = hypot(e.start.x - cur.x, e.start.y - cur.y)
                        let dEnd = hypot(e.end.x - cur.x, e.end.y - cur.y)
                        if dStart < snapEpsMeters,
                           dStart < (best?.dist ?? .greatestFiniteMagnitude)
                        {
                            best = (i, false, dStart)
                        }
                        if dEnd < snapEpsMeters,
                           dEnd < (best?.dist ?? .greatestFiniteMagnitude)
                        {
                            best = (i, true, dEnd)
                        }
                    }
                    if let best {
                        used.insert(best.ci)
                        let e = edges[best.ci]
                        if best.useEnd {
                            ring.append(e.start)
                            currentKey = vertexKey(e.start)
                        }
                        else {
                            ring.append(e.end)
                            currentKey = vertexKey(e.end)
                        }
                        found = true
                    }
                }

                if !found { break }
            }

            if ring.count >= 4 {
                rings.append(ring)
            }
        }

        return rings
    }

    // MARK: - Polygon assembly

    static func assemblePolygons(from rings: [[Coordinate3D]]) -> [Polygon] {
        guard rings.isNotEmpty else { return [] }

        let candidates: [(coords: [Coordinate3D], area: Double)] = rings.compactMap { coords in
            guard coords.count >= 4 else { return nil }
            let ring = Ring(unchecked: coords)
            return (coords, ring.area)
        }
        guard candidates.isNotEmpty else { return [] }

        let sorted = candidates.sorted { abs($0.area) > abs($1.area) }

        var result: [Polygon] = []
        for (coords, _) in sorted {
            let ring = Ring(unchecked: coords)
            let testPoint = ring.coordinates.first!

            var assigned = false
            for (i, _) in result.enumerated() {
                if result[i].contains(testPoint, ignoringBoundary: false) {
                    let poly = Polygon(unchecked: [result[i].outerRing!] + (result[i].innerRings ?? []) + [ring])
                    result[i] = poly
                    assigned = true
                    break
                }
            }
            if !assigned {
                let poly = Polygon(unchecked: [ring])
                result.append(poly)
            }
        }

        return result
    }

}
