#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Traversal

extension Graph {

    /// Performs a breadth-first search from the given node, returning nodes in
    /// visit order.
    public func breadthFirstSearch(from start: Node) -> [Node] {
        var result: [Node] = []
        breadthFirstSearch(from: start) { node in
            result.append(node)
            return true
        }
        return result
    }

    /// Performs a breadth-first search from the given node, calling `visitor`
    /// for each visited node in BFS order.
    ///
    /// The visitor is invoked exactly once per reachable node. Return `false`
    /// from the closure to stop the traversal early.
    ///
    /// - Parameters:
    ///   - start: The starting node.
    ///   - visitor: A closure called with each visited node in BFS order.
    ///     Return `false` to stop the traversal immediately.
    public func breadthFirstSearch(
        from start: Node,
        visitor: (Node) -> Bool
    ) {
        guard start.index >= 0,
              start.index < adjacencyList.count
        else { return }

        var visited: Set<Int> = [start.index]
        var queue: [Int] = [start.index]

        if !visitor(adjacencyList[start.index].node) { return }

        while queue.isNotEmpty {
            let current = queue.removeFirst()
            for edge in adjacencyList[current].edges {
                if visited.insert(edge.to.index).inserted {
                    queue.append(edge.to.index)
                    if !visitor(adjacencyList[edge.to.index].node) { return }
                }
            }
        }
    }

    /// Performs a depth-first search from the given node, returning nodes in
    /// visit order.
    public func depthFirstSearch(from start: Node) -> [Node] {
        var result: [Node] = []
        depthFirstSearch(from: start) { node in
            result.append(node)
            return true
        }
        return result
    }

    /// Performs a depth-first search from the given node, calling `visitor`
    /// for each visited node in DFS order.
    ///
    /// The visitor is invoked exactly once per reachable node. Return `false`
    /// from the closure to stop the traversal early.
    ///
    /// - Parameters:
    ///   - start: The starting node.
    ///   - visitor: A closure called with each visited node in DFS order.
    ///     Return `false` to stop the traversal immediately.
    public func depthFirstSearch(
        from start: Node,
        visitor: (Node) -> Bool
    ) {
        guard start.index >= 0,
              start.index < adjacencyList.count
        else { return }

        var visited: Set<Int> = []
        var stack: [Int] = [start.index]

        while let current = stack.popLast() {
            guard visited.insert(current).inserted else { continue }

            if !visitor(adjacencyList[current].node) { return }

            // Push neighbors in reverse so they're visited in natural order.
            let edges = adjacencyList[current].edges
            for edge in edges.reversed() {
                if !visited.contains(edge.to.index) {
                    stack.append(edge.to.index)
                }
            }
        }
    }

    /// Partitions the graph into connected components.
    ///
    /// Each component is an array of nodes that are connected via edges.
    /// Isolated nodes each form their own component.
    public var connectedComponents: [[Node]] {
        var visited: Set<Int> = []
        var components: [[Node]] = []

        for index in 0 ..< adjacencyList.count {
            guard visited.insert(index).inserted else { continue }

            var component: [Node] = [adjacencyList[index].node]
            var queue: [Int] = [index]

            while !queue.isEmpty {
                let current = queue.removeFirst()
                for edge in adjacencyList[current].edges {
                    if visited.insert(edge.to.index).inserted {
                        queue.append(edge.to.index)
                        component.append(adjacencyList[edge.to.index].node)
                    }
                }
            }

            components.append(component)
        }

        return components
    }

    /// Partitions the graph into connected components, returning each
    /// component as a standalone ``Graph``.
    ///
    /// This is the graph-valued counterpart to ``connectedComponents``: every
    /// node and edge of the original graph ends up in exactly one returned
    /// subgraph. Isolated nodes produce single-node graphs with no edges.
    /// Node indices are remapped compactly within each subgraph.
    ///
    /// - Returns: One `Graph` per connected component, or an empty array if the
    ///   graph is empty.
    public var connectedComponentGraphs: [Graph] {
        connectedComponents.map { subgraph(containing: $0) }
    }

    /// Returns a new graph containing only the given nodes and the edges
    /// between them.
    ///
    /// Node indices are remapped compactly (the first node in `nodes` becomes
    /// index 0 in the result). Edges whose endpoints are both in `nodes` are
    /// preserved with their original weights, features, and direction. Edges
    /// to nodes outside the set are dropped. Duplicates in `nodes` are
    /// ignored.
    ///
    /// - Parameter nodes: The nodes to include in the subgraph. Nodes not in
    ///   the original graph are skipped.
    /// - Returns: A new `Graph` containing only those nodes and their internal
    ///   edges.
    public func subgraph(containing nodes: [Node]) -> Graph {
        var included: Set<Int> = []

        var orderedIndices: [Int] = []
        orderedIndices.reserveCapacity(nodes.count)
        for node in nodes {
            guard node.index >= 0,
                  node.index < adjacencyList.count
            else { continue }

            if included.insert(node.index).inserted {
                orderedIndices.append(node.index)
            }
        }

        var newIndexForOld: [Int?] = Array(repeating: nil, count: adjacencyList.count)
        var edgeLists: [Graph.EdgeList] = []
        for originalIndex in orderedIndices {
            newIndexForOld[originalIndex] = edgeLists.count
            let node = adjacencyList[originalIndex].node
            edgeLists.append(
                EdgeList(
                    node: Node(
                        index: edgeLists.count,
                        coordinate: node.coordinate)))
        }

        for originalIndex in orderedIndices {
            guard let newFromIndex = newIndexForOld[originalIndex] else { continue }

            let fromNode = edgeLists[newFromIndex].node
            for edge in adjacencyList[originalIndex].edges {
                guard let newToIndex = newIndexForOld[edge.to.index] else { continue }

                let toNode = edgeLists[newToIndex].node
                edgeLists[newFromIndex].edges.append(
                    Edge(
                        from: fromNode,
                        to: toNode,
                        feature: edge.feature,
                        isDirected: edge.isDirected,
                        weight: edge.weight))
            }
        }

        var result = Graph(
            nodeTolerance: nodeTolerance,
            isDirected: isDirected,
            onewayProperty: onewayProperty)
        result.adjacencyList = edgeLists
        result.spatialIndex = SpatialIndex(
            tolerance: nodeTolerance,
            referenceLatitude: edgeLists.first?.node.coordinate.latitude ?? 0.0)
        for newIndex in edgeLists.indices {
            result.spatialIndex.insert(
                nodeIndex: newIndex,
                coordinate: edgeLists[newIndex].node.coordinate)
        }
        return result
    }

}
