#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-kinks
// and https://github.com/Turfjs/turf/tree/master/packages/turf-unkink-polygon

// MARK: - Kinks (self-intersection detection)

extension GeoJson {

    /// Finds all self-intersection points in the geometry.
    ///
    /// Supports ``LineString``, ``MultiLineString``, ``Polygon``,
    /// and ``MultiPolygon``.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``MultiPoint`` with one point for each
    ///   self-intersection.
    public func kinks(gridSize: Double? = nil) -> MultiPoint {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let geometry = (snappedSelf as? Feature)?.geometry ?? (snappedSelf as? GeoJsonGeometry)

        let coordSets: [[Coordinate3D]]

        switch geometry {
        case let ls as LineString:
            coordSets = [ls.coordinates]
        case let mls as MultiLineString:
            coordSets = mls.coordinates
        case let polygon as Polygon:
            coordSets = polygon.coordinates
        case let mp as MultiPolygon:
            coordSets = mp.coordinates.flatMap { $0 }
        default:
            return MultiPoint()
        }

        var intersectionPoints: Set<Coordinate3D> = []

        for setIndex1 in 0..<coordSets.count {
            let line1 = coordSets[setIndex1]
            for setIndex2 in setIndex1..<coordSets.count {
                let line2 = coordSets[setIndex2]
                for i in 0..<(line1.count - 1) {
                    for k in (setIndex1 == setIndex2 ? i : 0)..<(line2.count - 1) {
                        if setIndex1 == setIndex2 {
                            // Adjacent segments share a vertex, not a kink
                            if abs(i - k) == 1 {
                                continue
                            }
                            // First and last segment in a closed ring share a vertex
                            if i == 0, k == line1.count - 2,
                               line1[i] == line1[line1.count - 1]
                            {
                                continue
                            }
                        }

                        let seg1 = LineSegment(
                            first: line1[i],
                            second: line1[i + 1])
                        let seg2 = LineSegment(
                            first: line2[k],
                            second: line2[k + 1])

                        if let intersection = seg1.intersection(seg2) {
                            intersectionPoints.insert(intersection)
                        }
                    }
                }
            }
        }

        return MultiPoint(unchecked: Array(intersectionPoints))
    }

}

// MARK: - Unkink polygon (split self-intersecting polygon into simple polygons)

extension Polygon {

    /// Splits a self-intersecting polygon into an array of simple (non-self-intersecting) polygons.
    ///
    /// - Parameters:
    ///    - epsilon: Tolerance for intersection detection.
    ///    - gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: An array of simple polygons.
    public func unkinked(
        epsilon: Double = 1e-10,
        gridSize: Double? = nil
    ) -> [Polygon] {
        Self.unkinkPolygons(from: [self], epsilon: epsilon, gridSize: gridSize)
    }

    /// Splits a self-intersecting polygon in place.
    ///
    /// Replaces `self` with the first polygon from the unkinked result.
    ///
    /// - Parameters:
    ///    - epsilon: Tolerance for intersection detection.
    ///    - gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public mutating func unkink(
        epsilon: Double = 1e-10,
        gridSize: Double? = nil
    ) {
        let result = unkinked(epsilon: epsilon, gridSize: gridSize)
        if let first = result.first {
            self = first
        }
    }

}

extension MultiPolygon {

    /// Splits all self-intersecting polygons into an array of simple (non-self-intersecting) polygons.
    ///
    /// - Parameters:
    ///    - epsilon: Tolerance for intersection detection.
    ///    - gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: An array of simple polygons.
    public func unkinked(
        epsilon: Double = 1e-10,
        gridSize: Double? = nil
    ) -> [Polygon] {
        Polygon.unkinkPolygons(from: polygons, epsilon: epsilon, gridSize: gridSize)
    }

    /// Splits all self-intersecting polygons in place.
    ///
    /// Replaces `self` with a new multi-polygon built from the unkinked result.
    ///
    /// - Parameters:
    ///    - epsilon: Tolerance for intersection detection.
    ///    - gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public mutating func unkink(
        epsilon: Double = 1e-10,
        gridSize: Double? = nil
    ) {
        let result = unkinked(epsilon: epsilon, gridSize: gridSize)
        if let multi = MultiPolygon(result) {
            self = multi
        }
    }

}

private struct UnkinkIsect: Hashable {
    let coordinate: Coordinate3D
    let ring0: Int
    let edge0: Int
    let frac0: Double
    let ring1: Int
    let edge1: Int
    let frac1: Double
}

private struct UnkinkSegment: Hashable {
    let start: Coordinate3D
    let end: Coordinate3D
    let ringIndex: Int
    let edgeIndex: Int
    let segIndex: Int

    func reversed() -> UnkinkSegment {
        UnkinkSegment(
            start: end,
            end: start,
            ringIndex: ringIndex,
            edgeIndex: edgeIndex,
            segIndex: segIndex)
    }
}

extension Polygon {

    fileprivate static func unkinkPolygons(
        from polygons: [Polygon],
        epsilon: Double,
        gridSize: Double? = nil
    ) -> [Polygon] {
        // 1. Collect all rings
        var allRings: [(coords: [Coordinate3D], polyIndex: Int, isOuter: Bool)] = []
        for (polyIndex, polygon) in polygons.enumerated() {
            if let outer = polygon.outerRing {
                allRings.append((outer.coordinates, polyIndex, true))
            }
            for inner in polygon.innerRings ?? [] {
                allRings.append((inner.coordinates, polyIndex, false))
            }
        }

        guard allRings.isNotEmpty else { return [] }

        // 2. Ensure rings are closed
        var closedRingCoords: [[Coordinate3D]] = []
        for entry in allRings {
            var coords = entry.coords
            if coords.first != coords.last {
                coords.append(coords.first!)
            }
            // Snap to grid if requested
            if let gridSize {
                coords = coords.map { $0.snappedToGrid(tolerance: gridSize) }
            }
            closedRingCoords.append(coords)
        }

        // 3. Detect intersections
        let numRings = closedRingCoords.count
        var intersections: Set<UnkinkIsect> = []
        var intersectionCoords: Set<Coordinate3D> = []

        for ringIndex1 in 0 ..< numRings {
            let coords1 = closedRingCoords[ringIndex1]
            let numEdges1 = coords1.count - 1
            for ringIndex2 in ringIndex1 ..< numRings {
                let coords2 = closedRingCoords[ringIndex2]
                let numEdges2 = coords2.count - 1
                for edge1 in 0 ..< numEdges1 {
                    let seg1 = LineSegment(first: coords1[edge1], second: coords1[edge1 + 1])
                    let startEdge2 = (ringIndex1 == ringIndex2) ? edge1 : 0
                    for edge2 in startEdge2 ..< numEdges2 {
                        if ringIndex1 == ringIndex2 {
                            if abs(edge1 - edge2) == 1 { continue }
                            if edge1 == 0, edge2 == numEdges1 - 1 { continue }
                            if edge2 == 0, edge1 == numEdges1 - 1 { continue }
                        }
                        if coords1[edge1] == coords2[edge2 + 1] || coords1[edge1 + 1] == coords2[edge2] {
                            continue
                        }
                        let seg2 = LineSegment(first: coords2[edge2], second: coords2[edge2 + 1])
                        if let intersection = seg1.intersection(seg2, epsilon: epsilon) {
                            let frac0 = Self.fractionAlong(point: intersection, start: coords1[edge1], end: coords1[edge1 + 1])
                            let frac1 = Self.fractionAlong(point: intersection, start: coords2[edge2], end: coords2[edge2 + 1])
                            let detail = UnkinkIsect(
                                coordinate: intersection,
                                ring0: ringIndex1, edge0: edge1, frac0: frac0,
                                ring1: ringIndex2, edge1: edge2, frac1: frac1)
                            intersections.insert(detail)
                            intersectionCoords.insert(intersection)
                        }
                    }
                }
            }
        }

        // 4. Split edges at intersection points, build segments
        typealias SplitPt = (coordinate: Coordinate3D, frac: Double)
        var ringEdgeSplits: [[[SplitPt]]] = []

        for ringIndex in 0 ..< numRings {
            let coords = closedRingCoords[ringIndex]
            let numEdges = coords.count - 1
            var edgeSplits: [[SplitPt]] = []

            for edge in 0 ..< numEdges {
                var splits: [SplitPt] = [
                    (coords[edge], 0.0),
                    (coords[edge + 1], 1.0),
                ]
                for isect in intersections {
                    if isect.ring0 == ringIndex, isect.edge0 == edge {
                        splits.append((isect.coordinate, isect.frac0))
                    }
                    if isect.ring1 == ringIndex, isect.edge1 == edge {
                        splits.append((isect.coordinate, isect.frac1))
                    }
                }
                splits.sort { $0.frac < $1.frac }
                // Deduplicate by coordinate
                var deduped: [SplitPt] = []
                for s in splits {
                    if deduped.last.map({ $0.coordinate == s.coordinate }) == true {
                        continue
                    }
                    deduped.append(s)
                }
                edgeSplits.append(deduped)
            }
            ringEdgeSplits.append(edgeSplits)
        }

        // 5. Build segments and adjacency
        var segments: [UnkinkSegment] = []
        var adj: [String: [Int]] = [:]

        for ringIndex in 0 ..< numRings {
            let edgeSplits = ringEdgeSplits[ringIndex]
            for edge in 0 ..< edgeSplits.count {
                let splits = edgeSplits[edge]
                for i in 0 ..< (splits.count - 1) {
                    let start = splits[i].coordinate
                    let end = splits[i + 1].coordinate
                    if start == end { continue }
                    let segIndex = segments.count
                    let seg = UnkinkSegment(
                        start: start, end: end,
                        ringIndex: ringIndex, edgeIndex: edge, segIndex: i)
                    segments.append(seg)
                    let sk = vertexKey(start)
                    let ek = vertexKey(end)
                    adj[sk, default: []].append(segIndex)
                    adj[ek, default: []].append(segIndex)
                }
            }
        }

        // 6. Walk the adjacency graph using "switch ring at intersection" rule
        var used: Set<Int> = []
        var outputRings: [[Coordinate3D]] = []

        // Build lookup: for each intersection coordinate, which segments from
        // each ring meet at that point
        typealias SegAtNode = (segIndex: Int, forward: Bool)
        var nodeSegs: [String: [SegAtNode]] = [:]
        for (segIndex, seg) in segments.enumerated() {
            let sk = vertexKey(seg.start)
            let ek = vertexKey(seg.end)
            nodeSegs[sk, default: []].append((segIndex, true))
            nodeSegs[ek, default: []].append((segIndex, false))
        }

        // For each intersection coordinate, find the two original edges that intersect
        var isectEdgePairs: [String: (ring0: Int, edge0: Int, ring1: Int, edge1: Int)] = [:]
        for isect in intersections {
            let key = vertexKey(isect.coordinate)
            isectEdgePairs[key] = (isect.ring0, isect.edge0, isect.ring1, isect.edge1)
        }

        func getOtherRingSegments(
            at nodeKey: String,
            fromRing: Int,
            fromEdge: Int,
            arrivingForward: Bool
        ) -> [SegAtNode] {
            guard let candidates = nodeSegs[nodeKey] else { return [] }
            // Find the intersection info for this node
            guard let pair = isectEdgePairs[nodeKey] else { return [] }

            let otherRing: Int
            let otherEdge: Int
            if pair.ring0 == fromRing, pair.edge0 == fromEdge {
                otherRing = pair.ring1
                otherEdge = pair.edge1
            }
            else if pair.ring1 == fromRing, pair.edge1 == fromEdge {
                otherRing = pair.ring0
                otherEdge = pair.edge0
            }
            else {
                return [] // Not at an intersection
            }

            return candidates.filter { candidate in
                let seg = segments[candidate.segIndex]
                return seg.ringIndex == otherRing && seg.edgeIndex == otherEdge && !used.contains(candidate.segIndex)
            }
        }

        for startSegIndex in segments.indices where !used.contains(startSegIndex) {
            let startSeg = segments[startSegIndex]
            var ring: [Coordinate3D] = [startSeg.start, startSeg.end]
            used.insert(startSegIndex)

            var currentSegIndex = startSegIndex
            var currentForward = true

            while true {
                let currentSeg = segments[currentSegIndex]
                let endCoord = currentForward ? currentSeg.end : currentSeg.start
                let endKey = vertexKey(endCoord)
                let startKey = vertexKey(ring.first!)

                if endKey == startKey, ring.count >= 3 {
                    break
                }

                // Find next segment at this node
                let isAtIntersection = isectEdgePairs[endKey] != nil
                var nextSegIndex: Int?
                var nextForward = true

                if isAtIntersection {
                    // Try to switch to the other ring
                    let otherCandidates = getOtherRingSegments(
                        at: endKey,
                        fromRing: currentSeg.ringIndex,
                        fromEdge: currentSeg.edgeIndex,
                        arrivingForward: currentForward)
                    // Prefer the sub-segment that starts at the node (forward=true),
                    // so we traverse away from the intersection rather than back
                    // toward the origin of the intersecting edge.
                    if let best = otherCandidates.first(where: { $0.forward })
                        ?? otherCandidates.first
                    {
                        nextSegIndex = best.segIndex
                        nextForward = best.forward
                    }
                }

                if nextSegIndex == nil {
                    // Fall back to any unused segment at this node
                    let candidates = adj[endKey] ?? []
                    for ci in candidates where !used.contains(ci) {
                        if ci == currentSegIndex { continue }
                        let seg = segments[ci]
                        nextSegIndex = ci
                        nextForward = vertexKey(seg.start) == endKey
                        break
                    }
                }

                guard let next = nextSegIndex else { break }

                used.insert(next)
                let nextSeg = segments[next]
                let nextCoord = nextForward ? nextSeg.end : nextSeg.start
                ring.append(nextCoord)
                currentSegIndex = next
                currentForward = nextForward
            }

            if ring.count >= 3 && vertexKey(ring.first!) == vertexKey(ring.last!) {
                outputRings.append(ring)
            }
            else if ring.count >= 3 {
                // Try to close: check if last coordinate matches any earlier point
            }
        }

        // 7. Build simple polygons from output rings
        let result = Self.buildSimplePolygons(rings: outputRings)
        return result
    }

    private static func buildSimplePolygons(rings: [[Coordinate3D]]) -> [Polygon] {
        guard rings.isNotEmpty else { return [] }

        var counted: [(coords: [Coordinate3D], area: Double, parentIndex: Int)] = []
        for ring in rings {
            let area = abs(Self.signedArea2D(ring))
            counted.append((ring, area, -1))
        }
        counted.sort { $0.area > $1.area }

        for i in 1 ..< counted.count {
            let testCoord = counted[i].coords.first!
            for j in (0 ..< i).reversed() {
                if Self.pointInRing(testCoord, ring: counted[j].coords) {
                    counted[i].parentIndex = j
                    break
                }
            }
        }

        var result: [Polygon] = []
        var usedAsChild: Set<Int> = []

        for i in 0 ..< counted.count where counted[i].parentIndex == -1 {
            var outerCoords = counted[i].coords
            if outerCoords.count > 2, outerCoords.first! == outerCoords.last! {
                outerCoords.removeLast()
            }
            var holes: [[Coordinate3D]] = []
            for h in 0 ..< counted.count where counted[h].parentIndex == i {
                var hc = counted[h].coords
                if hc.count > 2, hc.first! == hc.last! {
                    hc.removeLast()
                }
                holes.append(hc)
                usedAsChild.insert(h)
            }
            if let polygon = Polygon([outerCoords] + holes) {
                result.append(polygon)
            }
        }

        for i in 0 ..< counted.count where counted[i].parentIndex != -1 && !usedAsChild.contains(i) {
            var coords = counted[i].coords
            if coords.count > 2, coords.first! == coords.last! {
                coords.removeLast()
            }
            if let polygon = Polygon([coords]) {
                result.append(polygon)
            }
        }

        return result
    }

    private static func signedArea2D(_ ring: [Coordinate3D]) -> Double {
        guard ring.count >= 3 else { return 0.0 }
        var sum: Double = 0.0
        for i in 0 ..< (ring.count - 1) {
            sum += (ring[i].longitude * ring[i + 1].latitude - ring[i + 1].longitude * ring[i].latitude)
        }
        if let last = ring.last, let first = ring.first {
            sum += (last.longitude * first.latitude - first.longitude * last.latitude)
        }
        return sum / 2.0
    }

    private static func pointInRing(
        _ point: Coordinate3D,
        ring: [Coordinate3D]
    ) -> Bool {
        guard ring.count >= 4 else { return false }
        var inside = false
        for i in 0 ..< (ring.count - 1) {
            let a = ring[i]
            let b = ring[i + 1]
            if (a.latitude > point.latitude) != (b.latitude > point.latitude) {
                let intersectLon = a.longitude + (point.latitude - a.latitude) * (b.longitude - a.longitude) / (b.latitude - a.latitude)
                if point.longitude < intersectLon {
                    inside.toggle()
                }
            }
        }
        return inside
    }

    private static func fractionAlong(
        point: Coordinate3D,
        start: Coordinate3D,
        end: Coordinate3D
    ) -> Double {
        let dx = end.longitude - start.longitude
        let dy = end.latitude - start.latitude
        let lenSq = dx * dx + dy * dy
        guard lenSq > 0 else { return 0.0 }
        return ((point.longitude - start.longitude) * dx + (point.latitude - start.latitude) * dy) / lenSq
    }

    private static func vertexKey(_ c: Coordinate3D) -> String {
        "\(c.longitude),\(c.latitude)"
    }

}
