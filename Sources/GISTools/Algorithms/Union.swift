#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-union

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
                    }
                    else {
                        newRemaining.append(poly)
                    }
                }
                remaining = newRemaining
            } while didMerge
            result.append(merged)
        }

        return MultiPolygon(unchecked: result)
    }

    private static func mergeTwo(
        _ a: Polygon,
        _ b: Polygon
    ) -> Polygon? {
        guard let outerARing = a.outerRing,
              let outerBRing = b.outerRing,
              let outerA = outerARing.coordinates.first,
              let outerB = outerBRing.coordinates.first
        else { return nil }

        // If one polygon completely contains the other, the union is the
        // container. (Check every vertex of the candidate - a single point
        // is not enough, since the polygons might just touch.)
        if a.contains(outerB, ignoringBoundary: true),
           outerBRing.coordinates.allSatisfy({ a.contains($0, ignoringBoundary: true) })
        {
            return a
        }
        if b.contains(outerA, ignoringBoundary: true),
           outerARing.coordinates.allSatisfy({ b.contains($0, ignoringBoundary: true) })
        {
            return b
        }

        guard let bbA = a.calculateBoundingBox(),
              let bbB = b.calculateBoundingBox(),
              bbA.intersects(bbB),
              a.intersects(bbB),
              b.intersects(bbA)
        else { return nil }

        // Currently only polygons without holes are supported.
        guard (a.innerRings?.isEmpty ?? true),
              (b.innerRings?.isEmpty ?? true)
        else { return nil }

        return weilerAthertonUnion(ringA: outerARing, ringB: outerBRing, polygonA: a, polygonB: b)
    }

    // MARK: - Weiler-Atherton union

    /// An intersection between an edge of A and an edge of B.
    private struct EdgeIntersection {
        let point: Coordinate3D
        let edgeA: Int
        let edgeB: Int
        let tA: Double
        let tB: Double
    }

    /// A vertex in an augmented polygon vertex list, with a possible cross-reference
    /// to the corresponding vertex in the other polygon (for intersection points).
    private struct PolyVertex {
        let point: Coordinate3D
        let isIntersection: Bool
        let intersectionId: Int
    }

    private static func weilerAthertonUnion(
        ringA: Ring,
        ringB: Ring,
        polygonA: Polygon,
        polygonB: Polygon
    ) -> Polygon? {
        // Weiler-Atherton requires the rings to be in CCW order so that the
        // interior is on the left of the direction of travel. Rings produced
        // by some callers (notably `Buffer`'s rectangle) come in CW order;
        // reverse them in place.
        let aCoords = ensureCCW(ringA.coordinates)
        let bCoords = ensureCCW(ringB.coordinates)
        let aCount = aCoords.count
        let bCount = bCoords.count

        // 1. Find all intersections between edges of A and edges of B.
        var intersections: [EdgeIntersection] = []
        for i in 0 ..< (aCount - 1) {
            for j in 0 ..< (bCount - 1) {
                if let (point, tA, tB) = lineSegmentIntersection(
                    aCoords[i], aCoords[i + 1],
                    bCoords[j], bCoords[j + 1]
                ) {
                    intersections.append(EdgeIntersection(
                        point: point,
                        edgeA: i,
                        edgeB: j,
                        tA: tA,
                        tB: tB
                    ))
                }
            }
        }

        // 1b. Find vertex-on-edge intersections. Weiler-Atherton's standard
        //     edge-edge intersection uses strict parametric bounds, so it
        //     misses intersections that land exactly on a corner of one
        //     polygon (e.g. `Buffer`'s rectangle corners vs. the circle's
        //     poles, which differ by ~1e-6 in lon due to the great-circle
        //     bearing not being exactly perpendicular to the line). Use a
        //     tolerance to catch those.
        let vertexOnEdgeTolerance = 1.0e-4
        for i in 0 ..< aCount {
            let vertex = aCoords[i]
            // Vertex i sits between edge i-1 (ending here) and edge i
            // (starting here). The "edgeA" we record is the edge that
            // follows the vertex in the augmented list.
            let edgeA = i == 0 ? aCount - 2 : i - 1
            for j in 0 ..< (bCount - 1) {
                if let tB = pointOnSegment(
                    bCoords[j], bCoords[j + 1], vertex, tolerance: vertexOnEdgeTolerance
                ) {
                    intersections.append(EdgeIntersection(
                        point: vertex,
                        edgeA: edgeA,
                        edgeB: j,
                        tA: 1.0, // at the end of edgeA
                        tB: tB
                    ))
                }
            }
        }
        for j in 0 ..< bCount {
            let vertex = bCoords[j]
            let edgeB = j == 0 ? bCount - 2 : j - 1
            for i in 0 ..< (aCount - 1) {
                if let tA = pointOnSegment(
                    aCoords[i], aCoords[i + 1], vertex, tolerance: vertexOnEdgeTolerance
                ) {
                    intersections.append(EdgeIntersection(
                        point: vertex,
                        edgeA: i,
                        edgeB: edgeB,
                        tA: tA,
                        tB: 1.0
                    ))
                }
            }
        }

        // Deduplicate intersections that are at the same physical point
        // (the same corner can be detected twice: once from each side).
        intersections = deduplicateIntersections(intersections)

        // For a clean union we expect an even number of intersections (>= 2).
        // A single intersection means the polygons just touch at a point.
        guard intersections.count >= 2 else { return nil }

        // 2. Build augmented vertex lists for both polygons with intersections inserted.
        var aByEdge: [Int: [(t: Double, id: Int)]] = [:]
        var bByEdge: [Int: [(t: Double, id: Int)]] = [:]
        // Track which vertex indices are themselves intersection points (the
        // vertex-on-edge case). We record the intersection id per vertex.
        var aVertexIntersection: [Int: Int] = [:]
        var bVertexIntersection: [Int: Int] = [:]
        for (id, inter) in intersections.enumerated() {
            // If tA is 1.0, the intersection is at the end of edgeA, which
            // is the same as the start of edgeA+1. Mark that vertex instead
            // of inserting a separate point.
            if inter.tA >= 1.0 {
                aVertexIntersection[(inter.edgeA + 1) % (aCount - 1)] = id
            }
            else if inter.tA <= 0.0 {
                aVertexIntersection[inter.edgeA] = id
            }
            else {
                aByEdge[inter.edgeA, default: []].append((inter.tA, id))
            }
            if inter.tB >= 1.0 {
                bVertexIntersection[(inter.edgeB + 1) % (bCount - 1)] = id
            }
            else if inter.tB <= 0.0 {
                bVertexIntersection[inter.edgeB] = id
            }
            else {
                bByEdge[inter.edgeB, default: []].append((inter.tB, id))
            }
        }
        for key in aByEdge.keys {
            aByEdge[key]?.sort(by: { $0.t < $1.t })
        }
        for key in bByEdge.keys {
            bByEdge[key]?.sort(by: { $0.t < $1.t })
        }

        var augmentedA: [PolyVertex] = []
        var idToIndexA: [Int: Int] = [:]
        for i in 0 ..< (aCount - 1) {
            let isVertexIntersection = aVertexIntersection[i] != nil
            let intersectionId = aVertexIntersection[i] ?? -1
            augmentedA.append(PolyVertex(
                point: aCoords[i],
                isIntersection: isVertexIntersection,
                intersectionId: intersectionId
            ))
            if isVertexIntersection {
                idToIndexA[intersectionId] = augmentedA.count - 1
            }
            if let edgeInters = aByEdge[i] {
                for (_, id) in edgeInters {
                    idToIndexA[id] = augmentedA.count
                    augmentedA.append(PolyVertex(
                        point: intersections[id].point,
                        isIntersection: true,
                        intersectionId: id
                    ))
                }
            }
        }

        var augmentedB: [PolyVertex] = []
        var idToIndexB: [Int: Int] = [:]
        for j in 0 ..< (bCount - 1) {
            let isVertexIntersection = bVertexIntersection[j] != nil
            let intersectionId = bVertexIntersection[j] ?? -1
            augmentedB.append(PolyVertex(
                point: bCoords[j],
                isIntersection: isVertexIntersection,
                intersectionId: intersectionId
            ))
            if isVertexIntersection {
                idToIndexB[intersectionId] = augmentedB.count - 1
            }
            if let edgeInters = bByEdge[j] {
                for (_, id) in edgeInters {
                    idToIndexB[id] = augmentedB.count
                    augmentedB.append(PolyVertex(
                        point: intersections[id].point,
                        isIntersection: true,
                        intersectionId: id
                    ))
                }
            }
        }

        // 3. Find a starting vertex on A that is not inside B.
        var startIndex = -1
        for (i, vertex) in augmentedA.enumerated()
            where !polygonB.contains(vertex.point, ignoringBoundary: true)
        {
            startIndex = i
            break
        }
        guard startIndex >= 0 else { return nil }

        // 4. Trace the union boundary. Always traverse each polygon in CCW order.
        //    At each intersection, check whether the next segment of the current
        //    polygon goes into the other polygon. If so, switch polygons.
        var result: [Coordinate3D] = []
        var onA = true
        var currentIndex = startIndex
        var visitedIntersections: Set<Int> = []
        let maxIterations = (augmentedA.count + augmentedB.count) * 4

        for _ in 0 ..< maxIterations {
            // Stop when we return to the starting position on A.
            if onA, currentIndex == startIndex, !result.isEmpty {
                break
            }

            let vertex = onA ? augmentedA[currentIndex] : augmentedB[currentIndex]

            if vertex.isIntersection {
                if visitedIntersections.contains(vertex.intersectionId) {
                    break
                }
                visitedIntersections.insert(vertex.intersectionId)
            }

            result.append(vertex.point)

            let list = onA ? augmentedA : augmentedB
            let nextIndex = (currentIndex + 1) % list.count
            let nextVertex = list[nextIndex]

            if nextVertex.isIntersection {
                // Look a tiny bit ahead of the intersection: if the next edge
                // enters or sits on the other polygon's boundary, jump to the
                // other polygon's matching intersection and continue there.
                // Treating the boundary as "inside" makes the algorithm
                // switch at shared edges and at the "corner" case produced
                // by `Buffer` (rectangle corner vs. circle pole).
                let nextNextIndex = (nextIndex + 1) % list.count
                let nextNextVertex = list[nextNextIndex]
                let epsilon = 1.0e-7
                let step = Coordinate3D(
                    latitude: nextVertex.point.latitude
                        + epsilon * (nextNextVertex.point.latitude - nextVertex.point.latitude),
                    longitude: nextVertex.point.longitude
                        + epsilon * (nextNextVertex.point.longitude - nextVertex.point.longitude)
                )
                let otherPolygon = onA ? polygonB : polygonA

                if otherPolygon.contains(step, ignoringBoundary: false) {
                    onA = !onA
                    let otherIndex = onA ? idToIndexA : idToIndexB
                    guard let jump = otherIndex[nextVertex.intersectionId] else { return nil }
                    currentIndex = jump
                    continue
                }
            }

            currentIndex = nextIndex
        }

        guard result.count >= 3 else { return nil }

        // Close the ring if needed.
        if result.first != result.last {
            result.append(result.first!)
        }

        return Polygon(unchecked: [result])
    }

    /// Returns the coordinates reversed if the ring's signed area is
    /// negative (CW in standard math convention). Weiler-Atherton needs
    /// CCW rings so that "interior on the left" holds.
    private static func ensureCCW(_ coordinates: [Coordinate3D]) -> [Coordinate3D] {
        guard signedArea(of: coordinates) < 0 else { return coordinates }
        let isClosed = coordinates.count > 1 && coordinates.first == coordinates.last
        let open = isClosed ? Array(coordinates.dropLast()) : coordinates
        return Array(open.reversed())
    }

    /// Shoelace signed area. Positive => CCW.
    private static func signedArea(of coordinates: [Coordinate3D]) -> Double {
        guard coordinates.count > 2 else { return 0 }
        var area = 0.0
        let count = coordinates.count - (coordinates.first == coordinates.last ? 1 : 0)
        for i in 0 ..< count {
            let j = (i + 1) % count
            area += coordinates[i].longitude * coordinates[j].latitude
            area -= coordinates[j].longitude * coordinates[i].latitude
        }
        return area / 2.0
    }

    /// Computes the intersection of two line segments in 2D, returning the intersection
    /// point and the parametric position along each segment.
    private static func lineSegmentIntersection(
        _ a1: Coordinate3D, _ a2: Coordinate3D,
        _ b1: Coordinate3D, _ b2: Coordinate3D
    ) -> (point: Coordinate3D, tA: Double, tB: Double)? {
        let denominator = (b2.latitude - b1.latitude) * (a2.longitude - a1.longitude)
            - (b2.longitude - b1.longitude) * (a2.latitude - a1.latitude)

        guard denominator != 0 else { return nil }

        let numeratorA = (b2.longitude - b1.longitude) * (a1.latitude - b1.latitude)
            - (b2.latitude - b1.latitude) * (a1.longitude - b1.longitude)
        let numeratorB = (a2.longitude - a1.longitude) * (a1.latitude - b1.latitude)
            - (a2.latitude - a1.latitude) * (a1.longitude - b1.longitude)

        let tA = numeratorA / denominator
        let tB = numeratorB / denominator

        // Strictly inside each segment.
        guard tA > 0, tA < 1, tB > 0, tB < 1 else { return nil }

        let point = Coordinate3D(
            latitude: a1.latitude + tA * (a2.latitude - a1.latitude),
            longitude: a1.longitude + tA * (a2.longitude - a1.longitude)
        )

        return (point, tA, tB)
    }

    /// Returns the parametric position of `point` on the segment (p1 -> p2)
    /// if the perpendicular distance from `point` to the segment is within
    /// `tolerance` (in degrees). The returned `t` is clamped to [0, 1].
    private static func pointOnSegment(
        _ p1: Coordinate3D, _ p2: Coordinate3D,
        _ point: Coordinate3D,
        tolerance: Double
    ) -> Double? {
        let dx = p2.longitude - p1.longitude
        let dy = p2.latitude - p1.latitude
        let lenSquared = dx * dx + dy * dy
        guard lenSquared > 0 else { return nil }

        let t = ((point.longitude - p1.longitude) * dx + (point.latitude - p1.latitude) * dy) / lenSquared
        let tClamped = min(1.0, max(0.0, t))
        let closestLongitude = p1.longitude + tClamped * dx
        let closestLatitude = p1.latitude + tClamped * dy
        let distX = point.longitude - closestLongitude
        let distY = point.latitude - closestLatitude
        let distance = (distX * distX + distY * distY).squareRoot()
        guard distance <= tolerance else { return nil }

        return tClamped
    }

    /// Removes duplicate intersections that resolve to the same physical
    /// point. Each duplicate keeps the first occurrence.
    private static func deduplicateIntersections(
        _ intersections: [EdgeIntersection]
    ) -> [EdgeIntersection] {
        let duplicateTolerance = 1.0e-5
        var result: [EdgeIntersection] = []
        result.reserveCapacity(intersections.count)
        for inter in intersections {
            let isDuplicate = result.contains { existing in
                abs(existing.point.latitude - inter.point.latitude) <= duplicateTolerance
                    && abs(existing.point.longitude - inter.point.longitude) <= duplicateTolerance
            }
            if !isDuplicate {
                result.append(inter)
            }
        }
        return result
    }

}
