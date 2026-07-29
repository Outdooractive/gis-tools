#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Node access

extension Graph {

    /// All nodes in the graph.
    public var nodes: [Node] {
        adjacencyList.map(\.node)
    }

    /// The number of nodes in the graph.
    public var nodeCount: Int {
        adjacencyList.count
    }

    /// Returns the node with the given index, or `nil` if out of range.
    public func node(withIndex index: Int) -> Node? {
        guard index >= 0, index < adjacencyList.count else { return nil }
        return adjacencyList[index].node
    }

    /// Whether the given node belongs to this graph.
    public func contains(node: Node) -> Bool {
        node.index >= 0
            && node.index < adjacencyList.count
            && adjacencyList[node.index].node == node
    }

    /// Finds the nearest node to the given coordinate within a tolerance.
    /// - Parameters:
    ///   - coordinate: The search coordinate.
    ///   - tolerance: The maximum distance (in meters) for a match.
    /// - Returns: The nearest node within tolerance, or `nil`.
    public func node(
        at coordinate: Coordinate3D,
        tolerance: CLLocationDistance = 1.0
    ) -> Node? {
        var bestNode: Node?
        var bestDistance: CLLocationDistance = tolerance

        for candidateIndex in spatialIndex.candidates(near: coordinate) {
            let node = adjacencyList[candidateIndex].node
            let distance = node.coordinate.distance(from: coordinate)
            if distance < bestDistance {
                bestDistance = distance
                bestNode = node
            }
        }

        return bestNode
    }

    // MARK: - Node creation / removal

    /// Finds or creates a node at the given coordinate.
    ///
    /// Nodes within ``nodeTolerance`` meters of an existing node are merged.
    /// - Returns: The existing or newly created node.
    @discardableResult
    public mutating func createNode(at coordinate: Coordinate3D) -> Node {
        for candidateIndex in spatialIndex.candidates(near: coordinate) {
            let candidate = adjacencyList[candidateIndex].node
            if candidate.coordinate.distance(from: coordinate) < nodeTolerance {
                return candidate
            }
        }

        let node = Node(index: adjacencyList.count, coordinate: coordinate)
        adjacencyList.append(EdgeList(node: node))
        spatialIndex.insert(nodeIndex: node.index, coordinate: coordinate)
        return node
    }

    /// Removes the given node and all its incident edges from the graph.
    ///
    /// The node slot is preserved (indices stay stable); only its edges and
    /// references from other nodes are removed.
    public mutating func removeNode(_ node: Node) {
        guard node.index >= 0, node.index < adjacencyList.count else { return }

        for edge in adjacencyList[node.index].edges {
            removeDirectedEdge(from: edge.to, to: node)
        }

        adjacencyList[node.index].edges.removeAll()
    }

}
