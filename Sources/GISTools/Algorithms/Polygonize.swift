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

        // Normalise antimeridian-crossing coordinates so that longitudes
        // are contiguous (shift negative values by +360°).
        // Only applies to EPSG:4326.
        let spansAntimeridian: Bool
        if projection == .epsg4326 {
            let minLon = lineStrings.flatMap(\.coordinates).map(\.longitude).min() ?? 0
            let maxLon = lineStrings.flatMap(\.coordinates).map(\.longitude).max() ?? 0
            spansAntimeridian = (maxLon - minLon) > 180.0
        }
        else {
            spansAntimeridian = false
        }

        let normalised: [LineString]
        if spansAntimeridian {
            normalised = lineStrings.map { ls in
                let coords = ls.coordinates.map { c in
                    Coordinate3D(x: c.longitude < 0 ? c.longitude + 360.0 : c.longitude,
                                 y: c.latitude,
                                 z: c.altitude,
                                 m: c.m,
                                 projection: projection)
                }
                // Use unchecked init: the shifted coords are still the same shape
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

        // Step 2: build the graph
        let nodes = buildGraph(from: splitSegments)
        guard nodes.isNotEmpty else { return FeatureCollection() }

        // Step 3: find rings
        let rings = findRings(nodes: nodes, segments: splitSegments)

        // Step 4: assemble polygons
        let polygons = assemblePolygons(from: rings)

        // Unshift coordinates back to original range
        let unshifted: [Polygon]
        if spansAntimeridian {
            unshifted = polygons.map { poly in
                let coords = poly.coordinates.map { ring in
                    ring.map { c in
                        Coordinate3D(x: c.longitude > 180.0 ? c.longitude - 360.0 : c.longitude,
                                     y: c.latitude,
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

        for i in 0..<segments.count {
            for j in (i + 1)..<segments.count {
                if let intersection = segments[i].intersection(segments[j]) {
                    splitPoints[i, default: []].insert(intersection)
                    splitPoints[j, default: []].insert(intersection)
                }
            }
        }

        // Split segments at intersection points
        var result: [LineSegment] = []
        for (i, segment) in segments.enumerated() {
            guard let points = splitPoints[i],
                  points.isNotEmpty
            else {
                result.append(segment)
                continue
            }

            // Collect all points along this segment and sort by distance from start
            var allPoints = [segment.first, segment.second] + Array(points)
            allPoints.sort { segment.first.distance(from: $0) < segment.first.distance(from: $1) }

            // Create sub-segments between consecutive points
            for k in 0..<(allPoints.count - 1) {
                guard allPoints[k] != allPoints[k + 1] else { continue }
                result.append(LineSegment(first: allPoints[k], second: allPoints[k + 1]))
            }
        }

        return result
    }

    // MARK: - Graph building

    private static func buildGraph(from segments: [LineSegment]) -> [Node] {
        // Deduplicate coordinates (graph nodes)
        var coordToIndex: [Coordinate3D: Int] = [:]
        var nodes: [Node] = []

        func index(for coord: Coordinate3D) -> Int {
            if let existing = coordToIndex[coord] { return existing }
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
        for i in 0..<nodes.count {
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

    // MARK: - Ring finding

    private static func findRings(
        nodes: [Node],
        segments: [LineSegment]
    ) -> [[Coordinate3D]] {
        var rings: [[Coordinate3D]] = []
        var visitedEdges: Set<String> = []

        for startNode in 0..<nodes.count {
            for startEdgeIdx in 0..<nodes[startNode].edges.count {
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
                        if diff < 0 { diff += 2.0 * .pi }
                        if diff < bestDiff {
                            bestDiff = diff
                            bestIdx = idx
                        }
                    }

                    guard let nextIdx = bestIdx else { break }
                    let nextNode = outgoing[nextIdx].to

                    edgeKey = "\(currNode)->\(nextNode)"
                    if visitedEdges.contains(edgeKey) { break }
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

    private static func assemblePolygons(from rings: [[Coordinate3D]]) -> [Polygon] {
        guard rings.isNotEmpty else { return [] }

        // Compute signed area to determine clockwise vs counter-clockwise
        func signedArea(_ ring: [Coordinate3D]) -> Double {
            let coords = ring
            var area: Double = 0.0
            for i in 0..<coords.count {
                let j = (i + 1) % coords.count
                area += coords[i].longitude * coords[j].latitude
                area -= coords[j].longitude * coords[i].latitude
            }
            return area
        }

        // Check if ring A contains ring B (using a point-in-polygon test)
        func contains(outer: [Coordinate3D], inner: [Coordinate3D]) -> Bool {
            guard let firstPt = inner.first else { return false }
            let ring = Ring(outer)
            return ring?.contains(firstPt, ignoringBoundary: true) ?? false
        }

        // CW rings are outer rings (in shapefile convention / our implementation)
        let outerRings = rings.filter { signedArea($0) < 0 }
        let innerRings = rings.filter { signedArea($0) > 0 }

        var polygons: [Polygon] = []
        for outer in outerRings {
            // Find holes contained in this outer ring
            let holes = innerRings.filter { contains(outer: outer, inner: $0) }

            var allRings: [Ring] = []
            if let outerRing = Ring(outer) {
                allRings.append(outerRing)
            }
            for hole in holes {
                if let holeRing = Ring(hole) {
                    allRings.append(holeRing)
                }
            }

            let polygon = Polygon(unchecked: allRings)
            polygons.append(polygon)
        }

        // Handle case where there are only inner rings (CCW in our convention)
        // — they form polygon shells
        if polygons.isEmpty {
            for inner in innerRings {
                if let polygon = Polygon([inner]) {
                    polygons.append(polygon)
                }
            }
        }

        return polygons
    }

}
