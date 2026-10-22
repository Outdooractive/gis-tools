#if EnableGraphAPI
#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension Graph {

    /// Merges multiple graphs into one, returning a new graph.
    ///
    /// Nodes across all graphs that lie within ``nodeTolerance`` meters of
    /// each other are merged (deduplicated). Edges connecting the same pair
    /// of nodes are deduplicated: when two input graphs contribute an
    /// undirected edge between the same two merged nodes, only the edge from
    /// the first graph contributing that pair is kept.
    ///
    /// Edges that were cut at buffer boundaries (e.g. an edge in one tile
    /// and a continuing edge in an adjacent tile sharing a boundary node)
    /// become degree-2 chains in the merged graph. Those can be collapsed
    /// with ``contracted()`` afterward if desired.
    ///
    /// The first graph's ``nodeTolerance`` and ``onewayProperty`` are used
    /// for the merged graph. The result is directed if any input graph is
    /// directed or contains one-way edges.
    ///
    /// Dangling endpoints left by clipped or overlapping inputs are stitched
    /// to nearby, nearly collinear edges within `stitchingTolerance`. This
    /// turns a T-junction at a segment interior into a proper graph node. Pass
    /// `0.0` to disable stitching.
    ///
    /// - Note: Collinear overlapping edges are split at each other's vertices
    ///   and then deduplicated. Non-collinear crossings and arbitrary
    ///   near-overlapping geometry are not automatically joined.
    ///
    /// - Parameters:
    ///   - graphs: The graphs to merge. Must be non-empty.
    ///   - stitchingTolerance: Maximum distance in meters for stitching a
    ///     dangling endpoint to a nearby edge. Defaults to the first graph's
    ///     ``nodeTolerance``.
    /// - Returns: A new graph containing all nodes and edges from all
    ///   input graphs, with duplicates removed.
    public static func merged(
        _ graphs: [Graph],
        stitchingTolerance: CLLocationDistance? = nil
    ) -> Graph {
        guard let first = graphs.first else { return Graph() }
        guard graphs.count > 1 else { return first }

        let directed = graphs.contains {
            $0.isDirected || $0.hasDirectedEdges
        }
        let totalNodeEstimate = graphs.reduce(0) { $0 + $1.nodeCount }

        var merged = Graph(
            nodeTolerance: first.nodeTolerance,
            isDirected: directed,
            onewayProperty: first.onewayProperty)
        merged.adjacencyList.reserveCapacity(totalNodeEstimate)
        merged.spatialIndex.cells.reserveCapacity(totalNodeEstimate / 4)

        merged.hasDirectedEdges = graphs.contains(where: { $0.hasDirectedEdges })

        let totalDirectedEdges = graphs.reduce(0) { $0 + $1.directedEdgeCount }
        var addedUndirected: Set<MergeEdgeKey> = []
        var addedDirected: Set<MergeEdgeKey> = []
        addedUndirected.reserveCapacity(totalDirectedEdges / 2)
        addedDirected.reserveCapacity(totalDirectedEdges / 4)

        for graph in graphs {
            var indexMap = [Int](
                repeating: -1,
                count: graph.nodeCount
            )

            for edgeList in graph.adjacencyList {
                let newNode = merged.createNode(at: edgeList.node.coordinate)
                indexMap[edgeList.node.index] = newNode.index
            }

            addMappedEdges(
                from: graph.adjacencyList,
                indexMap: indexMap,
                to: &merged,
                addedUndirected: &addedUndirected,
                addedDirected: &addedDirected)
        }

        let tolerance = stitchingTolerance ?? first.nodeTolerance
        if tolerance > 0.0 {
            stitchAndNodeEdges(in: &merged, tolerance: tolerance)
        }

        return merged
    }

    /// Merges another graph into the receiver, returning a new graph.
    ///
    /// - Parameter other: The graph to merge into the receiver.
    /// - Returns: A new graph containing all nodes and edges from both
    ///   graphs, with duplicates removed.
    public func merged(with other: Graph) -> Graph {
        Graph.merged([self, other])
    }

    // MARK: - Private

    private static func addMappedEdges(
        from sourceList: [EdgeList],
        indexMap: [Int],
        to target: inout Graph,
        addedUndirected: inout Set<MergeEdgeKey>,
        addedDirected: inout Set<MergeEdgeKey>
    ) {
        for edgeList in sourceList {
            let fromNewIndex = indexMap[edgeList.node.index]
            guard fromNewIndex >= 0 else { continue }

            let fromNode = target.adjacencyList[fromNewIndex].node

            for edge in edgeList.edges {
                let toNewIndex = indexMap[edge.to.index]
                guard toNewIndex >= 0 else { continue }

                if edge.isDirected {
                    let key = MergeEdgeKey(
                        from: fromNewIndex,
                        to: toNewIndex)
                    guard addedDirected.insert(key).inserted else { continue }

                    let toNode = target.adjacencyList[toNewIndex].node
                    target.adjacencyList[fromNewIndex].edges.append(
                        Edge(
                            from: fromNode,
                            to: toNode,
                            feature: edge.feature,
                            isDirected: true,
                            weight: fromNode.coordinate.distance(
                                from: toNode.coordinate)))
                }
                else {
                    let key = MergeEdgeKey(
                        from: min(fromNewIndex, toNewIndex),
                        to: max(fromNewIndex, toNewIndex))
                    guard addedUndirected.insert(key).inserted else { continue }

                    let toNode = target.adjacencyList[toNewIndex].node
                    let weight = fromNode.coordinate.distance(
                        from: toNode.coordinate)
                    target.adjacencyList[fromNewIndex].edges.append(
                        Edge(
                            from: fromNode,
                            to: toNode,
                            feature: edge.feature,
                            isDirected: false,
                            weight: weight))
                    target.adjacencyList[toNewIndex].edges.append(
                        Edge(
                            from: toNode,
                            to: fromNode,
                            feature: edge.feature,
                            isDirected: false,
                            weight: weight))
                }
            }
        }
    }

    // MARK: - Seam stitching

    /// A unique edge in the merged graph, used as a stitching target.
    private struct StitchingEdge {

        let from: Int
        let to: Int
        let isDirected: Bool
        let feature: Feature?
        let weight: Double

    }

    private static func stitchAndNodeEdges(
        in graph: inout Graph,
        tolerance: CLLocationDistance
    ) {
        guard graph.nodeCount > 1 else { return }

        var records: [StitchingEdge] = []
        records.reserveCapacity(graph.directedEdgeCount)

        var segments: [LineSegment] = []
        segments.reserveCapacity(graph.directedEdgeCount)

        for edgeList in graph.adjacencyList {
            for edge in edgeList.edges {
                if !edge.isDirected, edge.from.index > edge.to.index {
                    continue
                }

                let index = records.count
                records.append(
                    StitchingEdge(
                        from: edge.from.index,
                        to: edge.to.index,
                        isDirected: edge.isDirected,
                        feature: edge.feature,
                        weight: edge.weight))
                segments.append(
                    LineSegment(
                        first: edge.from.coordinate,
                        second: edge.to.coordinate,
                        index: index,
                        calculateBoundingBox: true))
            }
        }

        guard records.isNotEmpty else { return }

        // RTree's line/bbox intersection is not reliable for geocentric
        // coordinates. Index all segments in EPSG:4326 instead; the original
        // segments are still used for the geometric checks.
        let sourceProjection = segments.first?.projection ?? .epsg4326
        let indexProjection: Projection = sourceProjection == .noSRID
            ? .noSRID
            : .epsg4326
        let tree = RTree(segments.map { $0.projected(to: indexProjection) })

        var incidentRecords: [[Int]] = Array(
            repeating: [],
            count: graph.nodeCount)
        for (index, record) in records.enumerated() {
            incidentRecords[record.from].append(index)
            incidentRecords[record.to].append(index)
        }

        var splitsByRecord: [Int: [(node: Int, parameter: Double)]] = [:]

        for nodeIndex in 0 ..< graph.nodeCount {
            guard incidentRecords[nodeIndex].isNotEmpty else { continue }

            let node = graph.adjacencyList[nodeIndex].node
            let searchCoordinate = node.coordinate.projected(to: indexProjection)
            let searchBox: BoundingBox

            if indexProjection == .noSRID {
                searchBox = BoundingBox(
                    southWest: Coordinate3D(
                        x: searchCoordinate.longitude - tolerance,
                        y: searchCoordinate.latitude - tolerance,
                        projection: indexProjection),
                    northEast: Coordinate3D(
                        x: searchCoordinate.longitude + tolerance,
                        y: searchCoordinate.latitude + tolerance,
                        projection: indexProjection))
            }
            else if let box = BoundingBox(
                coordinates: [searchCoordinate],
                padding: tolerance)
            {
                searchBox = box
            }
            else {
                continue
            }

            let sourceIndexes = incidentRecords[nodeIndex]

            for indexedSegment in tree.search(inBoundingBox: searchBox) {
                guard let recordIndex = indexedSegment.index,
                      records.indices.contains(recordIndex)
                else { continue }

                let segment = segments[recordIndex]
                let target = records[recordIndex]
                if target.from == nodeIndex || target.to == nodeIndex {
                    continue
                }

                guard let foot = segment.perpendicularFoot(
                    from: node.coordinate,
                    clampToEnds: false)
                else { continue }

                let distance = node.coordinate.distance(from: foot)
                if distance > tolerance {
                    continue
                }

                // A clipped continuation should run in the same direction as
                // the edge it lands on. This avoids turning nearby crossings
                // or parallel side roads into junctions.
                guard sourceIndexes.contains(where: { sourceIndex in
                    sourceIndex != recordIndex
                        && segments[sourceIndex].isParallel(
                            to: segment,
                            tolerance: 30.0,
                            undirectedEdge: true)
                }) else { continue }

                let parameter = stitchParameter(
                    of: node.coordinate,
                    on: segment)

                splitsByRecord[recordIndex, default: []].append(
                    (node: nodeIndex, parameter: parameter))
            }
        }

        guard !splitsByRecord.isEmpty else { return }

        for (recordIndex, candidateSplits) in splitsByRecord {
            let record = records[recordIndex]
            var sorted = candidateSplits.sorted {
                $0.parameter < $1.parameter
            }

            var seenNodes: Set<Int> = []
            sorted = sorted.filter { seenNodes.insert($0.node).inserted }
            guard sorted.isNotEmpty else { continue }

            removeStitchingEdge(record, from: &graph)

            var previousNode = record.from
            var previousParameter = 0.0

            for split in sorted where split.parameter > previousParameter {
                let weight = record.weight * (split.parameter - previousParameter)
                appendStitchingEdge(
                    record,
                    from: previousNode,
                    to: split.node,
                    weight: weight,
                    in: &graph)
                previousNode = split.node
                previousParameter = split.parameter
            }

            appendStitchingEdge(
                record,
                from: previousNode,
                to: record.to,
                weight: record.weight * (1.0 - previousParameter),
                in: &graph)
        }

        deduplicateEdges(in: &graph)
    }

    private static func deduplicateEdges(in graph: inout Graph) {
        var seen: Set<EdgeIdentity> = []

        for from in graph.adjacencyList.indices {
            guard graph.adjacencyList[from].edges.isNotEmpty else { continue }

            var uniqueEdges: [Edge] = []
            uniqueEdges.reserveCapacity(graph.adjacencyList[from].edges.count)

            for edge in graph.adjacencyList[from].edges {
                let identity = EdgeIdentity(
                    from: from,
                    to: edge.to.index,
                    isDirected: edge.isDirected)

                if seen.insert(identity).inserted {
                    uniqueEdges.append(edge)
                }
            }

            graph.adjacencyList[from].edges = uniqueEdges
        }
    }

    private struct EdgeIdentity: Hashable {

        let from: Int
        let to: Int
        let isDirected: Bool

    }

    private static func stitchParameter(
        of coordinate: Coordinate3D,
        on segment: LineSegment
    ) -> Double {
        let coordinate = coordinate.projected(to: segment.projection)
        let dx = segment.second.longitude - segment.first.longitude
        let dy = segment.second.latitude - segment.first.latitude
        let denominator = dx * dx + dy * dy

        guard denominator > 0.0 else { return 0.0 }

        return (
            (coordinate.longitude - segment.first.longitude) * dx
                + (coordinate.latitude - segment.first.latitude) * dy
        ) / denominator
    }

    private static func removeStitchingEdge(
        _ record: StitchingEdge,
        from graph: inout Graph
    ) {
        if record.isDirected {
            graph.adjacencyList[record.from].edges.removeAll {
                $0.to.index == record.to && $0.isDirected
            }
        }
        else {
            graph.adjacencyList[record.from].edges.removeAll {
                $0.to.index == record.to && !$0.isDirected
            }
            graph.adjacencyList[record.to].edges.removeAll {
                $0.to.index == record.from && !$0.isDirected
            }
        }
    }

    private static func appendStitchingEdge(
        _ record: StitchingEdge,
        from: Int,
        to: Int,
        weight: Double,
        in graph: inout Graph
    ) {
        if graph.adjacencyList[from].edges.contains(where: {
            $0.to.index == to && $0.isDirected == record.isDirected
        }) {
            return
        }

        let fromNode = graph.adjacencyList[from].node
        let toNode = graph.adjacencyList[to].node

        graph.adjacencyList[from].edges.append(
            Edge(
                from: fromNode,
                to: toNode,
                feature: record.feature,
                isDirected: record.isDirected,
                weight: weight))

        if !record.isDirected {
            graph.adjacencyList[to].edges.append(
                Edge(
                    from: toNode,
                    to: fromNode,
                    feature: record.feature,
                    isDirected: false,
                    weight: weight))
        }
    }

    private struct MergeEdgeKey: Hashable {

        let from: Int
        let to: Int

    }

}
#endif
