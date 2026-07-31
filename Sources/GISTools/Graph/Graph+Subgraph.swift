#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension Graph {

    /// Returns a new graph containing only the specified nodes and the edges
    /// between them.
    ///
    /// Node indices are remapped to a fresh zero-based range. Feature
    /// references on edges are preserved. The returned graph inherits
    /// ``nodeTolerance``, ``isDirected``, and ``onewayProperty`` from the
    /// receiver.
    ///
    /// - Parameter nodeIndices: The indices of nodes to include.
    /// - Returns: A new graph with the induced subgraph.
    public func subgraph(containing nodeIndices: Set<Int>) -> Graph {
        var subgraph = Graph(
            nodeTolerance: nodeTolerance,
            isDirected: isDirected,
            onewayProperty: onewayProperty)

        var indexMap: [Int: Int] = [:]

        for oldIndex in nodeIndices.sorted() {
            let node = adjacencyList[oldIndex].node
            let newNode = subgraph.createNode(at: node.coordinate)
            indexMap[oldIndex] = newNode.index
        }

        var addedUndirected: Set<String> = []

        for oldIndex in nodeIndices {
            guard let fromNewIndex = indexMap[oldIndex] else { continue }
            let fromNode = subgraph.adjacencyList[fromNewIndex].node

            for edge in adjacencyList[oldIndex].edges {
                guard let toNewIndex = indexMap[edge.to.index] else { continue }

                if edge.isDirected {
                    let toNode = subgraph.adjacencyList[toNewIndex].node
                    subgraph.addDirectedEdge(
                        from: fromNode,
                        to: toNode,
                        feature: edge.feature,
                        isDirected: true)
                }
                else {
                    let a = min(fromNewIndex, toNewIndex)
                    let b = max(fromNewIndex, toNewIndex)
                    let key = "\(a)-\(b)"
                    if addedUndirected.insert(key).inserted {
                        let toNode = subgraph.adjacencyList[toNewIndex].node
                        subgraph.addUndirectedEdge(
                            from: fromNode,
                            to: toNode,
                            feature: edge.feature)
                    }
                }
            }
        }

        return subgraph
    }

}
