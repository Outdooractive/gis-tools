#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Polygon union using a split-and-filter approach:
//
// 1. Find all intersections between the two polygons (edge–edge and
//    vertex–on–edge, with a floating-point tolerance).
// 2. Build augmented vertex lists where every edge is split at
//    intersections.
// 3. Trace the union boundary: walk each polygon in CCW order. At an
//    intersection, check whether the next segment lies on the union
//    boundary — i.e., is its midpoint STRICTLY OUTSIDE the other
//    polygon? If yes (outside), continue tracing the current polygon.
//    If no (on the boundary or inside), the boundary must come from
//    the other polygon, so switch.
// 4. The trace completes when we return to the starting position.

// Ported from the approach described in:
//   Weiler, K. and Atherton, P. "Hidden surface removal using polygon
//   area sorting." SIGGRAPH 1977.
//
// The key insight that makes shared-edges and the Buffer corner case
// work correctly: the midpoint test uses `ignoringBoundary: false`
// so that a point sitting exactly on the other polygon's boundary is
// NOT considered "outside". This forces the algorithm to switch at
// shared edges and at the Buffer's rectangle–circle junction points,
// producing a proper stadium shape.

extension Polygon {

    public func union(with other: PolygonGeometry) -> MultiPolygon? {
        var all = self.polygons
        all.append(contentsOf: other.polygons)
        return Union.unionPolygons(all)
    }

}

extension MultiPolygon {

    public func union(with other: PolygonGeometry) -> MultiPolygon? {
        var all = self.polygons
        all.append(contentsOf: other.polygons)
        return Union.unionPolygons(all)
    }

    public mutating func formUnion(with other: PolygonGeometry) {
        guard let merged = union(with: other) else { return }
        self = merged
    }

}


extension FeatureCollection {

    /// Computes the union of all polygon features in the collection.
    public func union() -> FeatureCollection? {
        let geometries = features
            .compactMap { ($0.geometry as? PolygonGeometry)?.polygons }
            .flatMap { $0 }
        guard let result = Union.unionPolygons(geometries) else { return nil }
        return FeatureCollection(Feature(result))
    }

}

// MARK: - Private implementation

enum Union {

    public static func unionPolygons(
        _ polygons: [Polygon]
    ) -> MultiPolygon? {
        guard polygons.isNotEmpty else { return nil }

        var result: [Polygon] = []
        var remaining = polygons
        
        while remaining.isNotEmpty {
            var merged = remaining.removeFirst()
            var didMerge: Bool
            repeat {
                didMerge = false
                var newRemaining: [Polygon] = []
                for poly in remaining {
                    if let union = mergeTwo(merged, poly) {
                        merged = union
                        didMerge = true
                    } else {
                        newRemaining.append(poly)
                    }
                }
                remaining = newRemaining
            } while didMerge
            result.append(merged)
        }
        
        return MultiPolygon(unchecked: result)
    }

    // MARK: - Merge

    private static func mergeTwo(
        _ a: Polygon,
        _ b: Polygon
    ) -> Polygon? {
        guard let ringA = a.outerRing, let ringB = b.outerRing
        else { return nil }

        // One completely contains the other?
        if ringA.coordinates.allSatisfy({ b.contains($0, ignoringBoundary: true) }) { return b }
        if ringB.coordinates.allSatisfy({ a.contains($0, ignoringBoundary: true) }) { return a }
        
        // Bounding-box quick rejection
        guard let bbA = a.calculateBoundingBox(),
              let bbB = b.calculateBoundingBox(),
              bbA.intersects(bbB)
        else { return nil }
        
        // Currently only simple polygons (no holes)
        guard (a.innerRings?.isEmpty ?? true),
              (b.innerRings?.isEmpty ?? true)
        else { return nil }
        
        let aCoords = ensureCCW(ringA.coordinates)
        let bCoords = ensureCCW(ringB.coordinates)
        
        return traceUnion(aCoords: aCoords, bCoords: bCoords, aPolygon: a, bPolygon: b)
    }

    // MARK: - Core algorithm

    /// An edge–edge intersection with parametric positions.
    private struct EdgeIntersection {
        let point: Coordinate3D
        let edgeA: Int
        let edgeB: Int
        let tA: Double
        let tB: Double
    }

    /// A vertex in an augmented polygon.
    private struct PolyVertex: Equatable {
        let point: Coordinate3D
        let isIntersection: Bool
        let intersectionId: Int

        static func == (lhs: PolyVertex, rhs: PolyVertex) -> Bool {
            lhs.point == rhs.point && lhs.intersectionId == rhs.intersectionId
        }
    }

    private static func traceUnion(
        aCoords rawA: [Coordinate3D],
        bCoords rawB: [Coordinate3D],
        aPolygon: Polygon,
        bPolygon: Polygon
    ) -> Polygon? {
        let aCount = rawA.count
        let bCount = rawB.count

        // ---- 1. Find all intersections ----
        var intersections: [EdgeIntersection] = []

        // 1a. Edge–edge (strict bounds)
        for i in 0 ..< (aCount - 1) {
            for j in 0 ..< (bCount - 1) {
                if let (point, tA, tB) = lineSegmentIntersection(
                    rawA[i], rawA[i + 1],
                    rawB[j], rawB[j + 1]
                ) {
                    intersections.append(EdgeIntersection(
                        point: point, edgeA: i, edgeB: j, tA: tA, tB: tB
                    ))
                }
            }
        }

        // 1b. Vertex–on–edge (with tolerance, for floating-point noise)
        let vertexOnEdgeTolerance = 1.0e-4
        for i in 0 ..< aCount {
            let vertex = rawA[i]
            let edgeA = i == 0 ? aCount - 2 : i - 1  // the edge ending at vertex i
            for j in 0 ..< (bCount - 1) {
                if let tB = pointOnSegment(rawB[j], rawB[j + 1], vertex, tolerance: vertexOnEdgeTolerance) {
                    intersections.append(EdgeIntersection(
                        point: vertex, edgeA: edgeA, edgeB: j, tA: 1.0, tB: tB
                    ))
                }
            }
        }
        for j in 0 ..< bCount {
            let vertex = rawB[j]
            let edgeB = j == 0 ? bCount - 2 : j - 1
            for i in 0 ..< (aCount - 1) {
                if let tA = pointOnSegment(rawA[i], rawA[i + 1], vertex, tolerance: vertexOnEdgeTolerance) {
                    intersections.append(EdgeIntersection(
                        point: vertex, edgeA: i, edgeB: edgeB, tA: tA, tB: 1.0
                    ))
                }
            }
        }

        // 1c. Deduplicate
        intersections = deduplicateIntersections(intersections)

        // 1d. Snap remaining intersections to nearby existing vertices.
        //     A circle's vertex can land ~1e-6 away from a rectangle's
        //     corner due to floating-point differences in the `destination`
        //     formula.  If left unsnapped, the algorithm sees two near-
        //     identical intersections at the same corner and switches
        //     prematurely onto the circle's second vertex.
        let snapTolerance = 1.0e-4
        for id in intersections.indices {
            let pt = intersections[id].point
            if let snapped = nearestVertex(pt, candidates: rawA + rawB, tolerance: snapTolerance) {
                intersections[id] = EdgeIntersection(
                    point: snapped, edgeA: intersections[id].edgeA,
                    edgeB: intersections[id].edgeB,
                    tA: intersections[id].tA, tB: intersections[id].tB
                )
            }
        }

        // Re-deduplicate after snapping (two previously distinct
        // intersections may have snapped to the same vertex).
        intersections = deduplicateIntersections(intersections)

        guard intersections.count >= 2 else { return nil }

        // ---- 2. Build augmented vertex lists ----
        var aByEdge: [Int: [(t: Double, id: Int)]] = [:]
        var bByEdge: [Int: [(t: Double, id: Int)]] = [:]
        var aVertexIS: [Int: Int] = [:]  // vertex index -> intersection id
        var bVertexIS: [Int: Int] = [:]

        for (id, inter) in intersections.enumerated() {
            if inter.tA >= 1.0 {
                aVertexIS[(inter.edgeA + 1) % (aCount - 1)] = id
            } else if inter.tA <= 0.0 {
                aVertexIS[inter.edgeA] = id
            } else {
                aByEdge[inter.edgeA, default: []].append((inter.tA, id))
            }
            if inter.tB >= 1.0 {
                bVertexIS[(inter.edgeB + 1) % (bCount - 1)] = id
            } else if inter.tB <= 0.0 {
                bVertexIS[inter.edgeB] = id
            } else {
                bByEdge[inter.edgeB, default: []].append((inter.tB, id))
            }
        }
        for key in aByEdge.keys { aByEdge[key]?.sort(by: { $0.t < $1.t }) }
        for key in bByEdge.keys { bByEdge[key]?.sort(by: { $0.t < $1.t }) }

        var augmentedA: [PolyVertex] = []
        var idToIndexA: [Int: Int] = [:]
        for i in 0 ..< (aCount - 1) {
            let isVI = aVertexIS[i] != nil
            let vi = aVertexIS[i] ?? -1
            augmentedA.append(PolyVertex(point: rawA[i], isIntersection: isVI, intersectionId: vi))
            if isVI { idToIndexA[vi] = augmentedA.count - 1 }
            if let edgeInts = aByEdge[i] {
                for (_, id) in edgeInts {
                    idToIndexA[id] = augmentedA.count
                    augmentedA.append(PolyVertex(
                        point: intersections[id].point, isIntersection: true, intersectionId: id
                    ))
                }
            }
        }

        var augmentedB: [PolyVertex] = []
        var idToIndexB: [Int: Int] = [:]
        for j in 0 ..< (bCount - 1) {
            let isVI = bVertexIS[j] != nil
            let vi = bVertexIS[j] ?? -1
            augmentedB.append(PolyVertex(point: rawB[j], isIntersection: isVI, intersectionId: vi))
            if isVI { idToIndexB[vi] = augmentedB.count - 1 }
            if let edgeInts = bByEdge[j] {
                for (_, id) in edgeInts {
                    idToIndexB[id] = augmentedB.count
                    augmentedB.append(PolyVertex(
                        point: intersections[id].point, isIntersection: true, intersectionId: id
                    ))
                }
            }
        }

        // ---- 3. Trace the union boundary ----
        // Start: first vertex on A that is STRICTLY OUTSIDE B.
        var startIndex = -1
        for (i, vertex) in augmentedA.enumerated()
            where !bPolygon.contains(vertex.point, ignoringBoundary: false)
        {
            startIndex = i
            break
        }
        guard startIndex >= 0 else { return nil }

        var result: [Coordinate3D] = []
        var onA = true
        var currentIndex = startIndex
        var visitedIntersections: Set<Int> = []
        let maxIter = (augmentedA.count + augmentedB.count) * 4

        for _ in 0 ..< maxIter {
            if onA, currentIndex == startIndex, !result.isEmpty { break }

            let vertex = onA ? augmentedA[currentIndex] : augmentedB[currentIndex]
            if vertex.isIntersection {
                if visitedIntersections.contains(vertex.intersectionId) { break }
                visitedIntersections.insert(vertex.intersectionId)
            }

            result.append(vertex.point)

            let list = onA ? augmentedA : augmentedB
            let nextIndex = (currentIndex + 1) % list.count
            let nextVertex = list[nextIndex]

            if nextVertex.isIntersection {
                // The next edge of the current polygon starts at the
                // intersection.  If it goes to a point that is strictly
                // outside the other polygon it belongs to the union
                // boundary -> continue.  Otherwise switch.
                let nextNextIndex = (nextIndex + 1) % list.count
                let nextNextVertex = list[nextNextIndex]
                let epsilon = 1.0e-7
                let step = Coordinate3D(
                    latitude: nextVertex.point.latitude
                        + epsilon * (nextNextVertex.point.latitude - nextVertex.point.latitude),
                    longitude: nextVertex.point.longitude
                        + epsilon * (nextNextVertex.point.longitude - nextVertex.point.longitude)
                )
                let otherPoly = onA ? bPolygon : aPolygon
                // Strictly outside the other polygon?  If yes → stay,
                // otherwise → switch.
                let isOutside = !otherPoly.contains(step, ignoringBoundary: false)
                if isOutside {
                    currentIndex = nextIndex
                } else {
                    onA = !onA
                    let otherIndex = onA ? idToIndexA : idToIndexB
                    guard let jump = otherIndex[nextVertex.intersectionId] else { return nil }
                    currentIndex = jump
                }
                continue
            }
            currentIndex = nextIndex
        }

        guard result.count >= 3 else { return nil }

        // Remove consecutive vertices that are essentially duplicates.
        // This can happen when the algorithm switches polygons at an
        // intersection and then visits the same point in the other
        // polygon.
        let dupTol = 1.0e-5
        var deduped: [Coordinate3D] = [result[0]]
        for i in 1 ..< result.count {
            let last = deduped.last!
            let curr = result[i]
            if abs(last.latitude - curr.latitude) > dupTol
                || abs(last.longitude - curr.longitude) > dupTol
            {
                deduped.append(curr)
            }
        }
        guard deduped.count >= 3 else { return nil }
        result = deduped

        // Close the ring
        if result.first != result.last {
            result.append(result.first!)
        }

        return Polygon(unchecked: [result])
    }

    // MARK: - Helpers

    /// Reverse a CW ring so it becomes CCW.
    private static func ensureCCW(_ coordinates: [Coordinate3D]) -> [Coordinate3D] {
        guard signedArea(of: coordinates) < 0 else { return coordinates }
        let isClosed = coordinates.count > 1 && coordinates.first == coordinates.last
        let open = isClosed ? Array(coordinates.dropLast()) : coordinates
        return Array(open.reversed())
    }

    /// Shoelace signed area. Positive ⇒ CCW.
    private static func signedArea(of coordinates: [Coordinate3D]) -> Double {
        guard coordinates.count > 2 else { return 0 }
        var area = 0.0
        let n = coordinates.count - (coordinates.first == coordinates.last ? 1 : 0)
        for i in 0 ..< n {
            let j = (i + 1) % n
            area += coordinates[i].longitude * coordinates[j].latitude
            area -= coordinates[j].longitude * coordinates[i].latitude
        }
        return area / 2.0
    }

    /// Snap `point` to the closest existing vertex within `tolerance`.
    /// Returns nil if no vertex is that close.
    private static func nearestVertex(
        _ point: Coordinate3D,
        candidates: [Coordinate3D],
        tolerance: Double
    ) -> Coordinate3D? {
        for v in candidates {
            if abs(v.latitude - point.latitude) <= tolerance
                && abs(v.longitude - point.longitude) <= tolerance
            {
                return v
            }
        }
        return nil
    }

    /// Computes the intersection of two line segments in 2D (strict bounds).
    private static func lineSegmentIntersection(
        _ a1: Coordinate3D, _ a2: Coordinate3D,
        _ b1: Coordinate3D, _ b2: Coordinate3D
    ) -> (point: Coordinate3D, tA: Double, tB: Double)? {
        let denom = (b2.latitude - b1.latitude) * (a2.longitude - a1.longitude)
                  - (b2.longitude - b1.longitude) * (a2.latitude - a1.latitude)
        guard denom != 0 else { return nil }

        let numA = (b2.longitude - b1.longitude) * (a1.latitude - b1.latitude)
                 - (b2.latitude - b1.latitude) * (a1.longitude - b1.longitude)
        let numB = (a2.longitude - a1.longitude) * (a1.latitude - b1.latitude)
                 - (a2.latitude - a1.latitude) * (a1.longitude - b1.longitude)
        let tA = numA / denom
        let tB = numB / denom
        guard tA > 0, tA < 1, tB > 0, tB < 1 else { return nil }

        return (
            Coordinate3D(
                latitude: a1.latitude + tA * (a2.latitude - a1.latitude),
                longitude: a1.longitude + tA * (a2.longitude - a1.longitude)
            ),
            tA, tB
        )
    }

    /// Returns `t` in [0,1] if `point` lies within `tolerance` of the
    /// segment p1→p2. Returns nil otherwise.
    private static func pointOnSegment(
        _ p1: Coordinate3D, _ p2: Coordinate3D,
        _ point: Coordinate3D,
        tolerance: Double
    ) -> Double? {
        let dx = p2.longitude - p1.longitude
        let dy = p2.latitude - p1.latitude
        let lenSq = dx * dx + dy * dy
        guard lenSq > 0 else { return nil }
        let t = ((point.longitude - p1.longitude) * dx + (point.latitude - p1.latitude) * dy) / lenSq
        let tc = min(1.0, max(0.0, t))
        let cx = p1.longitude + tc * dx
        let cy = p1.latitude + tc * dy
        let d = ((point.longitude - cx) * (point.longitude - cx) + (point.latitude - cy) * (point.latitude - cy)).squareRoot()
        guard d <= tolerance else { return nil }
        return tc
    }

    /// Deduplicate intersections that resolve to the same physical point.
    private static func deduplicateIntersections(
        _ intersections: [EdgeIntersection]
    ) -> [EdgeIntersection] {
        let tol = 1.0e-5
        var result: [EdgeIntersection] = []
        for inter in intersections {
            let dup = result.contains { existing in
                abs(existing.point.latitude - inter.point.latitude) <= tol
                && abs(existing.point.longitude - inter.point.longitude) <= tol
            }
            if !dup { result.append(inter) }
        }
        return result
    }

}
