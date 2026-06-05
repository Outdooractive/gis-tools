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
        let aCoords = ringA.coordinates
        let bCoords = ringB.coordinates
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

        // For a clean union we expect an even number of intersections (>= 2).
        // A single intersection means the polygons just touch at a point.
        guard intersections.count >= 2 else { return nil }

        // 2. Build augmented vertex lists for both polygons with intersections inserted.
        var aByEdge: [Int: [(t: Double, id: Int)]] = [:]
        var bByEdge: [Int: [(t: Double, id: Int)]] = [:]
        for (id, inter) in intersections.enumerated() {
            aByEdge[inter.edgeA, default: []].append((inter.tA, id))
            bByEdge[inter.edgeB, default: []].append((inter.tB, id))
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
            augmentedA.append(PolyVertex(point: aCoords[i], isIntersection: false, intersectionId: -1))
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
            augmentedB.append(PolyVertex(point: bCoords[j], isIntersection: false, intersectionId: -1))
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
                // enters the other polygon, jump to the other polygon's
                // matching intersection and continue there.
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

                if otherPolygon.contains(step, ignoringBoundary: true) {
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

}
