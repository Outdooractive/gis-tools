#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension Graph {

    /// Merges another graph into the receiver, returning a new graph.
    ///
    /// Nodes from `other` that lie within ``nodeTolerance`` meters of an
    /// existing node are merged (deduplicated). Edges connecting the same
    /// pair of nodes are deduplicated: when both graphs contribute an
    /// undirected edge between the same two merged nodes, only the edge
    /// from the receiver is kept.
    ///
    /// Edges that were cut at buffer boundaries (e.g. an edge in `self` and
    /// a continuing edge in `other` sharing a boundary node) become a
    /// degree-2 chain in the merged graph. Those can be collapsed with
    /// ``contracted()`` afterward if desired.
    ///
    /// - Parameter other: The graph to merge into the receiver.
    /// - Returns: A new graph containing all nodes and edges from both
    ///   graphs, with duplicates removed.
    public func merged(with other: Graph) -> Graph {
        var merged = Graph(
            nodeTolerance: nodeTolerance,
            isDirected: isDirected || other.isDirected,
            onewayProperty: onewayProperty)

        var selfMap: [Int: Int] = [:]
        for edgeList in adjacencyList {
            let newNode = merged.createNode(at: edgeList.node.coordinate)
            selfMap[edgeList.node.index] = newNode.index
        }

        var otherMap: [Int: Int] = [:]
        for edgeList in other.adjacencyList {
            let newNode = merged.createNode(at: edgeList.node.coordinate)
            otherMap[edgeList.node.index] = newNode.index
        }

        var addedUndirected: Set<String> = []
        var addedDirected: Set<String> = []

        addMappedEdges(
            from: adjacencyList, indexMap: selfMap, to: &merged,
            addedUndirected: &addedUndirected, addedDirected: &addedDirected)
        addMappedEdges(
            from: other.adjacencyList, indexMap: otherMap, to: &merged,
            addedUndirected: &addedUndirected, addedDirected: &addedDirected)

        return merged
    }

    // MARK: - Private

    private func addMappedEdges(
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
