#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-polygonize

extension FeatureCollection {

    /// Creates polygons from the LineStrings in this collection, replacing
    /// the receiver with the result.
    ///
    /// The input should contain connected LineString features whose segments
    /// form closed boundaries. The result is a ``FeatureCollection`` of
    /// ``Polygon`` features, one per closed ring found in the graph.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public mutating func polygonize(gridSize: Double? = nil) {
        self = polygonized(gridSize: gridSize)
    }

    /// Creates polygons from the LineStrings in this collection.
    ///
    /// The input should contain connected LineString features whose segments
    /// form closed boundaries. The result is a ``FeatureCollection`` of
    /// ``Polygon`` features, one per closed ring found in the graph.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``FeatureCollection`` of ``Polygon`` features
    public func polygonized(gridSize: Double? = nil) -> FeatureCollection {
        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let lineStrings: [LineString] = snapped.features.compactMap { $0.geometry as? LineString }
        guard !lineStrings.isEmpty else { return FeatureCollection() }

        return Polygonize.polygonize(lineStrings: lineStrings)
    }

}

extension LineString {

    /// Creates polygons from this LineString.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``FeatureCollection`` of ``Polygon`` features
    public func polygonized(gridSize: Double? = nil) -> FeatureCollection {
        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        return Polygonize.polygonize(lineStrings: [snapped])
    }

}

extension MultiLineString {

    /// Creates polygons from the LineStrings in this MultiLineString.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``FeatureCollection`` of ``Polygon`` features
    public func polygonized(gridSize: Double? = nil) -> FeatureCollection {
        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        return Polygonize.polygonize(lineStrings: snapped.lineStrings)
    }

}

// MARK: - Implementation

private enum Polygonize {

    private struct Node {

        let coordinate: Coordinate3D
        var edges: [DirectedEdge] = []
        var visited: Set<Int> = []

    }

    private struct DirectedEdge {

        let from: Int
        let to: Int
        let fromCoord: Coordinate3D
        let toCoord: Coordinate3D

    }

    // MARK: - Public API

    static func polygonize(lineStrings: [LineString]) -> FeatureCollection {
        // Determine projection from the first coordinate.
        let projection = lineStrings.first?.coordinates.first?.projection ?? .epsg4326

        // ECEF x/y/z are not a planar map: polygonize in geographic space and
        // project the resulting polygons back into the source CRS.
        if projection.isGeocentric {
            let geographic = lineStrings.map { $0.projected(to: .epsg4326) }
            let result = polygonize(lineStrings: geographic)
            let features = result.features.compactMap { feature -> Feature? in
                guard let polygon = feature.geometry as? Polygon else { return nil }
                return Feature(polygon.projected(to: projection))
            }
            return FeatureCollection(features)
        }

        // Normalise coordinates that cross the projection's wraparound axis
        // (the antimeridian for EPSG:4326, ±originShift for EPSG:3857) so the
        // graph sees a contiguous coordinate space.
        let extent = projection.wraparoundExtent
        var spansWraparound = false

        if let extent, extent > 0.0 {
            let xs = lineStrings.flatMap(\.coordinates).map(\.x)
            if let minimum = xs.min(), let maximum = xs.max() {
                spansWraparound = (maximum - minimum) > extent
            }
        }

        let period = (extent ?? 0.0) * 2.0
        let normalised: [LineString]
        if spansWraparound, period > 0.0 {
            normalised = lineStrings.map { ls in
                let coords = ls.coordinates.map { c in
                    Coordinate3D(
                        x: c.x < 0.0 ? c.x + period : c.x,
                        y: c.y,
                        z: c.altitude,
                        m: c.m,
                        projection: projection)
                }
                return LineString(unchecked: coords, calculateBoundingBox: ls.boundingBox != nil)
            }
        }
        else {
            normalised = lineStrings
        }

        // Step 1: find all intersection points and split segments
        let segments = extractSegments(from: normalised)
        guard segments.isNotEmpty else { return FeatureCollection() }

        let splitSegments = splitAtIntersections(segments)
        guard splitSegments.isNotEmpty else { return FeatureCollection() }

        // Step 2: build the graph and remove edges that cannot border a face.
        var nodes = buildGraph(from: splitSegments)
        guard nodes.isNotEmpty else { return FeatureCollection() }

        prune(&nodes)
        guard nodes.contains(where: { $0.edges.isNotEmpty }) else {
            return FeatureCollection()
        }

        // Step 3: find rings
        let rings = findRings(nodes: nodes, segments: splitSegments)

        // Step 4: assemble polygons
        let polygons = assemblePolygons(from: rings)

        // Unshift coordinates back to the source range.
        let unshifted: [Polygon]
        if spansWraparound, let extent, period > 0.0 {
            unshifted = polygons.map { poly in
                let coords = poly.coordinates.map { ring in
                    ring.map { c in
                        Coordinate3D(
                            x: c.x > extent ? c.x - period : c.x,
                            y: c.y,
                            z: c.altitude,
                            m: c.m,
                            projection: projection)
                    }
                }
                return Polygon(unchecked: coords, calculateBoundingBox: poly.boundingBox != nil)
            }
        }
        else {
            unshifted = polygons
        }

        let features = unshifted.map { Feature($0) }
        return FeatureCollection(features)
    }

    // MARK: - Segment extraction

    private static func extractSegments(from lineStrings: [LineString]) -> [LineSegment] {
        lineStrings.flatMap { $0.lineSegments }
    }

    // MARK: - Intersection splitting

    private static func splitAtIntersections(_ segments: [LineSegment]) -> [LineSegment] {
        // Collect all split points for each segment
        var splitPoints: [Int: Set<Coordinate3D>] = [:]

        for i in 0 ..< segments.count {
            for j in (i + 1) ..< segments.count {
                if let intersection = segments[i].intersection(segments[j]) {
                    splitPoints[i, default: []].insert(intersection)
                    splitPoints[j, default: []].insert(intersection)
                }

                // `LineSegment.intersection` returns nil for collinear
                // segments. Without noded collinear overlaps, duplicate or
                // partially overlapping edges are never split and produce
                // duplicate faces.
                for point in collinearOverlapPoints(segments[i], segments[j]) {
                    splitPoints[i, default: []].insert(point)
                    splitPoints[j, default: []].insert(point)
                }
            }
        }

        // Split segments at intersection points and deduplicate the noded
        // edges (collinear overlaps produce the same sub-segment from both
        // inputs).
        var result: [LineSegment] = []
        var seen: Set<SegmentKey> = []

        for (i, segment) in segments.enumerated() {
            let points = splitPoints[i] ?? []
            var allPoints = [segment.first, segment.second] + Array(points)
            allPoints.sort { segment.first.distance(from: $0) < segment.first.distance(from: $1) }

            for k in 0 ..< (allPoints.count - 1) {
                let first = allPoints[k]
                let second = allPoints[k + 1]
                guard first.distance(from: second) > GISTool.equalityDelta else { continue }

                let key = SegmentKey(first: first, second: second)
                guard seen.insert(key).inserted else { continue }
                result.append(LineSegment(first: first, second: second))
            }
        }

        return result
    }

    /// Points at which two collinear segments overlap. Each endpoint that lies
    /// inside the other segment is a node point.
    private static func collinearOverlapPoints(
        _ first: LineSegment,
        _ second: LineSegment
    ) -> [Coordinate3D] {
        let a = first.first
        let b = first.second
        let c = second.first
        let d = second.second

        let abx = b.x - a.x
        let aby = b.y - a.y
        let cdx = d.x - c.x
        let cdy = d.y - c.y
        let abLength = sqrt(abx * abx + aby * aby)
        let cdLength = sqrt(cdx * cdx + cdy * cdy)
        guard abLength > 0.0, cdLength > 0.0 else { return [] }

        let cross = abx * cdy - aby * cdx
        let crossTolerance = GISTool.intersectionEpsilon
            * max(1.0, abLength * cdLength)
        guard abs(cross) <= crossTolerance else { return [] }

        // Parallel but offset lines are not collinear.
        let offset = abs((c.x - a.x) * aby - (c.y - a.y) * abx) / abLength
        guard offset <= GISTool.intersectionEpsilon * max(1.0, abLength) else {
            return []
        }

        func parameter(of point: Coordinate3D, from start: Coordinate3D, dx: Double, dy: Double) -> Double {
            let lengthSquared = dx * dx + dy * dy
            guard lengthSquared > 0.0 else { return -1.0 }
            return ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        }

        func contains(_ point: Coordinate3D, start: Coordinate3D, dx: Double, dy: Double) -> Bool {
            let t = parameter(of: point, from: start, dx: dx, dy: dy)
            return t >= -0.000000001 && t <= 1.000000001
        }

        var points: [Coordinate3D] = []
        for point in [a, b, c, d] {
            if contains(point, start: a, dx: abx, dy: aby),
               contains(point, start: c, dx: cdx, dy: cdy),
               !points.contains(where: { $0.distance(from: point) <= GISTool.equalityDelta })
            {
                points.append(point)
            }
        }
        return points
    }

    private struct CoordinateKey: Hashable {
        let x: Int64
        let y: Int64

        init(_ coordinate: Coordinate3D) {
            x = Int64((coordinate.x / GISTool.equalityDelta).rounded())
            y = Int64((coordinate.y / GISTool.equalityDelta).rounded())
        }
    }

    private struct SegmentKey: Hashable {
        let first: CoordinateKey
        let second: CoordinateKey

        init(first: Coordinate3D, second: Coordinate3D) {
            let a = CoordinateKey(first)
            let b = CoordinateKey(second)
            if a.x < b.x || (a.x == b.x && a.y <= b.y) {
                self.first = a
                self.second = b
            }
            else {
                self.first = b
                self.second = a
            }
        }
    }

    // MARK: - Graph building

    private static func buildGraph(from segments: [LineSegment]) -> [Node] {
        // Deduplicate coordinates (graph nodes)
        var coordToIndex: [Coordinate3D: Int] = [:]
        var nodes: [Node] = []

        func index(for coord: Coordinate3D) -> Int {
            if let existing = coordToIndex[coord] {
                return existing
            }
            let idx = nodes.count
            coordToIndex[coord] = idx
            nodes.append(Node(coordinate: coord))
            return idx
        }

        // Add edges
        for segment in segments {
            let fromIdx = index(for: segment.first)
            let toIdx = index(for: segment.second)

            let edge = DirectedEdge(
                from: fromIdx,
                to: toIdx,
                fromCoord: segment.first,
                toCoord: segment.second)
            nodes[fromIdx].edges.append(edge)

            // Also add reverse edge for undirected traversal
            let revEdge = DirectedEdge(
                from: toIdx,
                to: fromIdx,
                fromCoord: segment.second,
                toCoord: segment.first)
            nodes[toIdx].edges.append(revEdge)
        }

        // Sort edges at each node by angle
        for i in 0 ..< nodes.count {
            let coord = nodes[i].coordinate
            nodes[i].edges.sort { a, b in
                angle(from: coord, to: a.toCoord) < angle(from: coord, to: b.toCoord)
            }
        }

        return nodes
    }

    private static func angle(from: Coordinate3D, to: Coordinate3D) -> Double {
        atan2(to.latitude - from.latitude, to.longitude - from.longitude)
    }

    // MARK: - Dangle and cut-edge pruning

    /// Removes dangling edges (degree-1 chains) recursively and then every
    /// bridge. None of those edges can bound a face; leaving them in the graph
    /// lets the ring walk start on them and mark half-edges visited without
    /// producing a ring.
    private static func prune(_ nodes: inout [Node]) {
        pruneDangles(&nodes)

        let bridges = bridgeKeys(nodes)
        guard bridges.isNotEmpty else { return }

        for index in nodes.indices {
            nodes[index].edges.removeAll { edge in
                let key = BridgeKey(a: index, b: edge.to)
                return bridges.contains(key)
            }
        }

        pruneDangles(&nodes)
    }

    private static func pruneDangles(_ nodes: inout [Node]) {
        var queue = nodes.indices.filter { nodes[$0].edges.count <= 1 }
        while let index = queue.popLast() {
            guard nodes[index].edges.count <= 1 else { continue }
            let incident = nodes[index].edges
            nodes[index].edges.removeAll()

            for edge in incident {
                nodes[edge.to].edges.removeAll { $0.to == index }
                if nodes[edge.to].edges.count <= 1 {
                    queue.append(edge.to)
                }
            }
        }
    }

    private struct BridgeKey: Hashable {
        let a: Int
        let b: Int

        init(a: Int, b: Int) {
            self.a = min(a, b)
            self.b = max(a, b)
        }
    }

    /// Tarjan bridge detection over the undirected underlying graph.
    private static func bridgeKeys(_ nodes: [Node]) -> Set<BridgeKey> {
        var discovery = Array(repeating: -1, count: nodes.count)
        var low = Array(repeating: 0, count: nodes.count)
        var timer = 0
        var bridges: Set<BridgeKey> = []

        func visit(_ node: Int, parent: Int) {
            discovery[node] = timer
            low[node] = timer
            timer += 1

            for edge in nodes[node].edges {
                let neighbor = edge.to
                if neighbor == parent { continue }

                if discovery[neighbor] == -1 {
                    visit(neighbor, parent: node)
                    low[node] = min(low[node], low[neighbor])
                    if low[neighbor] > discovery[node] {
                        bridges.insert(BridgeKey(a: node, b: neighbor))
                    }
                }
                else {
                    low[node] = min(low[node], discovery[neighbor])
                }
            }
        }

        for index in nodes.indices where discovery[index] == -1 {
            visit(index, parent: -1)
        }

        return bridges
    }

    // MARK: - Ring finding

    private static func findRings(
        nodes: [Node],
        segments: [LineSegment]
    ) -> [[Coordinate3D]] {
        var rings: [[Coordinate3D]] = []
        var visitedEdges: Set<String> = []

        for startNode in 0 ..< nodes.count {
            for startEdgeIdx in 0 ..< nodes[startNode].edges.count {
                guard !visitedEdges.contains("\(startNode)->\(nodes[startNode].edges[startEdgeIdx].to)") else { continue }

                // Walk the graph always taking the sharpest left turn
                var ring: [Coordinate3D] = [nodes[startNode].coordinate]
                var prevNode = startNode
                var currNode = nodes[startNode].edges[startEdgeIdx].to
                var incomingAngle = angle(
                    from: nodes[prevNode].coordinate,
                    to: nodes[currNode].coordinate)
                var edgeKey = "\(prevNode)->\(currNode)"
                visitedEdges.insert(edgeKey)

                while currNode != startNode {
                    ring.append(nodes[currNode].coordinate)

                    let outgoing = nodes[currNode].edges
                    guard outgoing.isNotEmpty else { break }

                    func normalise(_ a: Double) -> Double {
                        let r = a.truncatingRemainder(dividingBy: 2.0 * .pi)
                        return r < 0 ? r + 2.0 * .pi : r
                    }

                    let baseAngle = normalise(incomingAngle + .pi)
                    var bestIdx: Int?
                    var bestDiff = Double.infinity

                    for (idx, edge) in outgoing.enumerated() {
                        guard edge.to != prevNode else { continue }

                        let ea = normalise(angle(from: nodes[currNode].coordinate, to: nodes[edge.to].coordinate))
                        var diff = ea - baseAngle
                        if diff < 0 {
                            diff += 2.0 * .pi
                        }
                        if diff < bestDiff {
                            bestDiff = diff
                            bestIdx = idx
                        }
                    }

                    guard let nextIdx = bestIdx else { break }

                    let nextNode = outgoing[nextIdx].to

                    edgeKey = "\(currNode)->\(nextNode)"
                    if visitedEdges.contains(edgeKey) {
                        break
                    }
                    visitedEdges.insert(edgeKey)

                    prevNode = currNode
                    currNode = nextNode
                    incomingAngle = angle(
                        from: nodes[prevNode].coordinate,
                        to: nodes[currNode].coordinate)
                }

                if ring.count >= 3,
                   currNode == startNode
                {
                    if ring.first != ring.last {
                        ring.append(ring[0])
                    }
                    rings.append(ring)
                }
            }
        }

        return rings
    }

    // MARK: - Polygon assembly

    /// Classifies the face rings by containment depth and assembles polygons.
    ///
    /// Depth is the number of strictly larger rings containing the ring:
    /// even depths are shells, odd depths are holes. A hole is assigned to the
    /// smallest containing shell, which keeps nested islands (depth 2) as
    /// separate polygons instead of silently turning them into holes.
    private static func assemblePolygons(from rings: [[Coordinate3D]]) -> [Polygon] {
        guard rings.isNotEmpty else { return [] }

        // The half-edge walk visits each bounded face with negative planar
        // area and the unbounded face with positive area (each face also
        // appears with both orientations). Keep the bounded face rings and
        // collapse duplicates by vertex set before classifying them.
        var uniqueRings: [[Coordinate3D]] = []
        var seen: Set<[CoordinateKey]> = []
        for ring in rings {
            guard ring.count >= 4,
                  planarSignedArea(ring) < 0.0
            else { continue }
            let key = canonicalKey(ring)
            guard seen.insert(key).inserted else { continue }
            uniqueRings.append(ring)
        }

        guard uniqueRings.isNotEmpty else { return [] }

        let areas = uniqueRings.map { ring in
            abs(Polygon(unchecked: [ring]).area)
        }

        func contains(outer: [Coordinate3D], inner: [Coordinate3D]) -> Bool {
            guard let point = inner.first,
                  let ring = Ring(outer)
            else { return false }
            return ring.contains(point)
        }

        var depth = Array(repeating: 0, count: uniqueRings.count)
        var containers = Array(repeating: [Int](), count: uniqueRings.count)

        for index in uniqueRings.indices {
            for other in uniqueRings.indices where other != index {
                guard areas[other] > areas[index] * 1.000000001 else { continue }
                if contains(outer: uniqueRings[other], inner: uniqueRings[index]) {
                    containers[index].append(other)
                }
            }
            depth[index] = containers[index].count
        }

        var polygons: [Polygon] = []
        for shellIndex in uniqueRings.indices where depth[shellIndex] % 2 == 0 {
            let holeIndices = uniqueRings.indices.filter { index in
                guard depth[index] % 2 == 1 else { return false }
                let possibleShells = containers[index].filter { depth[$0] % 2 == 0 }
                guard let assignedShell = possibleShells.min(by: {
                    areas[$0] < areas[$1]
                }) else { return false }
                return assignedShell == shellIndex
            }

            var polygonRings: [Ring] = []
            if let shell = Ring(uniqueRings[shellIndex]) {
                polygonRings.append(shell)
            }
            for holeIndex in holeIndices {
                if let hole = Ring(uniqueRings[holeIndex]) {
                    polygonRings.append(hole)
                }
            }

            guard let polygon = Polygon(polygonRings) else { continue }
            polygons.append(polygon.rewinded)
        }

        return polygons
    }

    private static func planarSignedArea(_ ring: [Coordinate3D]) -> Double {
        guard ring.count >= 3 else { return 0.0 }
        var sum = 0.0
        for index in 0 ..< (ring.count - 1) {
            sum += ring[index].x * ring[index + 1].y
                - ring[index + 1].x * ring[index].y
        }
        return sum / 2.0
    }

    private static func canonicalKey(_ ring: [Coordinate3D]) -> [CoordinateKey] {
        var coordinates = ring
        if coordinates.count > 1,
           coordinates.first?.distance(from: coordinates.last ?? coordinates[0]) ?? 0.0
            < GISTool.equalityDelta
        {
            coordinates.removeLast()
        }
        return coordinates.map(CoordinateKey.init).sorted {
            $0.x < $1.x || ($0.x == $1.x && $0.y < $1.y)
        }
    }


}
