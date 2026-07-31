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
    /// directed.
    ///
    /// - Parameter graphs: The graphs to merge. Must be non-empty.
    /// - Returns: A new graph containing all nodes and edges from all
    ///   input graphs, with duplicates removed.
    public static func merged(_ graphs: [Graph]) -> Graph {
        guard let first = graphs.first else { return Graph() }
        guard graphs.count > 1 else { return first }

        let directed = graphs.contains(where: { $0.isDirected })
        let totalNodeEstimate = graphs.reduce(0) { $0 + $1.nodeCount }

        var merged = Graph(
            nodeTolerance: first.nodeTolerance,
            isDirected: directed,
            onewayProperty: first.onewayProperty)
        merged.adjacencyList.reserveCapacity(totalNodeEstimate)
        merged.spatialIndex.cells.reserveCapacity(totalNodeEstimate / 4)

        var addedUndirected: Set<String> = []
        var addedDirected: Set<String> = []
        addedUndirected.reserveCapacity(graphs.reduce(0) { $0 + $1.edges.count })
        addedDirected.reserveCapacity(graphs.reduce(0) { $0 + $1.directedEdgeCount })

        for graph in graphs {
            var indexMap: [Int: Int] = [:]
            indexMap.reserveCapacity(graph.nodeCount)

            for edgeList in graph.adjacencyList {
                let newNode = merged.createNode(at: edgeList.node.coordinate)
                indexMap[edgeList.node.index] = newNode.index
            }

            addMappedEdges(
                from: graph.adjacencyList, indexMap: indexMap, to: &merged,
                addedUndirected: &addedUndirected, addedDirected: &addedDirected)
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
        indexMap: [Int: Int],
        to target: inout Graph,
        addedUndirected: inout Set<String>,
        addedDirected: inout Set<String>
    ) {
        for edgeList in sourceList {
            guard let fromNewIndex = indexMap[edgeList.node.index] else { continue }
            let fromNode = target.adjacencyList[fromNewIndex].node

            for edge in edgeList.edges {
                guard let toNewIndex = indexMap[edge.to.index] else { continue }

                if edge.isDirected {
                    let key = "d:\(fromNewIndex)->\(toNewIndex)"
                    guard addedDirected.insert(key).inserted else { continue }
                    let toNode = target.adjacencyList[toNewIndex].node
                    target.addDirectedEdge(
                        from: fromNode,
                        to: toNode,
                        feature: edge.feature,
                        isDirected: true)
                }
                else {
                    let a = min(fromNewIndex, toNewIndex)
                    let b = max(fromNewIndex, toNewIndex)
                    let key = "u:\(a)-\(b)"
                    guard addedUndirected.insert(key).inserted else { continue }
                    let toNode = target.adjacencyList[toNewIndex].node
                    target.addUndirectedEdge(
                        from: fromNode,
                        to: toNode,
                        feature: edge.feature)
                }
            }
        }
    }

}
