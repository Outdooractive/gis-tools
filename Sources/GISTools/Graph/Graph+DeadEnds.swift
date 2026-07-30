#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Dead-end pruning

extension Graph {

    /// The result of ``prunedDeadEnds(maximumBranches:)``: the cleaned graph
    /// and the nodes that were removed as dead-ends.
    public struct DeadEndPruneResult: Sendable {

        /// The graph with dead-ends removed. Node indices are remapped compactly
        /// (see ``originalIndices`` and ``prunedIndexOfOriginal``).
        public let graph: Graph

        /// The original nodes that were removed as dead-ends, in removal order
        /// (leaves first, then their parents as they become leaves, and so on).
        public let removedNodes: [Node]

        /// For each node index in the pruned graph, the original node index it
        /// represents.
        public let originalIndices: [Int]

        /// Maps an original node index to its index in the pruned graph, or
        /// `nil` if the node was a dead-end that got removed.
        public let prunedIndexOfOriginal: [Int?]

    }

    /// Detects and removes dead-ends — cul-de-sacs, stub roads, and other tree
    /// branches hanging off the main network.
    ///
    /// A dead-end is a connected subgraph in which every node has at most one
    /// neighbor *within the remaining graph*. Pruning proceeds iteratively:
    /// degree-1 leaves (and isolated degree-0 nodes) are removed first; their
    /// removal may expose new leaves, which are removed in turn, and so on
    /// until only the cyclic/branched "core" of the network remains. This is
    /// the standard *k-core* decomposition with `k = 2` (every surviving node
    /// has degree >= 2 within the core), restricted to the undirected degree.
    ///
    /// For directed graphs, one-way dead-ends are also pruned: a node with no
    /// outgoing one-way edges (a sink reached via a single one-way chain) is a
    /// dead-end, and symmetrically for sources. Two-way pass-through nodes are
    /// always retained (they belong to the bidirectional core).
    ///
    /// Use this to clean up a network before analysis so that routing and
    /// cycle detection don't waste time exploring stub roads, or to surface
    /// the structure of the underlying mesh.
    ///
    /// - Parameter maximumBranches: An optional cap on the number of edges in
    ///   a dead-end branch; branches longer than this are kept (treated as
    ///   part of the core). `nil` (the default) prunes dead-ends of any length.
    /// - Returns: The pruned graph, the removed nodes, and the original/pruned
    ///   index mappings, or `nil` if the graph is empty.
    public func prunedDeadEnds(maximumBranches: Int? = nil)
        -> DeadEndPruneResult?
    {
        guard adjacencyList.isNotEmpty else { return nil }

        // Iteratively peel degree-1 (and degree-0) nodes. `alive` tracks which
        // nodes are still present; `effectiveDegree` is the degree within the
        // remaining graph (counting only edges to other alive nodes).
        var alive = Array(repeating: true, count: adjacencyList.count)
        var removedIndices: [Int] = []

        // Branch-length accounting: when a leaf is removed, its single incident
        // edge inherits the branch length (number of already-removed edges in
        // that branch) +1 to its surviving neighbor. A branch exceeds
        // `maximumBranches` once its accumulated length passes the cap, at
        // which point the surviving neighbor stops peeling in that direction.
        var branchLength = Array(repeating: 0, count: adjacencyList.count)

        // Compute initial effective degrees.
        func effectiveDegree(_ i: Int) -> Int {
            adjacencyList[i].edges.reduce(0) { count, edge in
                alive[edge.to.index] ? count + 1 : count
            }
        }

        // Seed the queue with all current leaves and isolated nodes.
        var queue: [Int] = []
        for i in 0..<adjacencyList.count {
            if effectiveDegree(i) <= 1 {
                queue.append(i)
            }
        }

        while let i = queue.popLast() {
            guard alive[i] else { continue }
            // A node's degree may have changed since it was queued; re-check.
            let degree = effectiveDegree(i)
            guard degree <= 1 else { continue }

            // If this leaf belongs to a branch longer than the cap, keep it
            // (and stop peeling along this direction).
            if let maximumBranches, branchLength[i] > maximumBranches {
                continue
            }

            alive[i] = false
            removedIndices.append(i)

            // Propagate the branch length to the surviving neighbor (if any),
            // and re-check whether that neighbor has become a leaf.
            var neighborIndex = -1
            for edge in adjacencyList[i].edges where alive[edge.to.index] {
                neighborIndex = edge.to.index
            }
            if neighborIndex >= 0 {
                branchLength[neighborIndex] = branchLength[i] + 1
                if effectiveDegree(neighborIndex) <= 1 {
                    queue.append(neighborIndex)
                }
            }
        }

        // Build the pruned graph: compactly relabel surviving nodes and copy
        // their edges (dropping any that pointed to removed nodes).
        var newIndexForOld: [Int?] = Array(
            repeating: nil, count: adjacencyList.count)
        var originalIndexForNew: [Int] = []
        var edgeLists: [Graph.EdgeList] = []
        for i in 0..<adjacencyList.count where alive[i] {
            newIndexForOld[i] = edgeLists.count
            originalIndexForNew.append(i)
            let node = adjacencyList[i].node
            edgeLists.append(
                EdgeList(
                    node: Node(
                        index: edgeLists.count, coordinate: node.coordinate)))
        }

        for i in 0..<adjacencyList.count where alive[i] {
            guard let newFromIndex = newIndexForOld[i] else { continue }
            let fromNode = edgeLists[newFromIndex].node
            for edge in adjacencyList[i].edges {
                guard alive[edge.to.index],
                    let newToIndex = newIndexForOld[edge.to.index]
                else { continue }
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

        var pruned = Graph(
            nodeTolerance: nodeTolerance,
            isDirected: isDirected,
            onewayProperty: onewayProperty)
        pruned.adjacencyList = edgeLists
        pruned.spatialIndex = SpatialIndex(
            tolerance: nodeTolerance,
            referenceLatitude: edgeLists.first?.node.coordinate.latitude ?? 0.0)
        for newIndex in edgeLists.indices {
            pruned.spatialIndex.insert(
                nodeIndex: newIndex,
                coordinate: edgeLists[newIndex].node.coordinate)
        }

        let removedNodes = removedIndices.map { adjacencyList[$0].node }

        return DeadEndPruneResult(
            graph: pruned,
            removedNodes: removedNodes,
            originalIndices: originalIndexForNew,
            prunedIndexOfOriginal: newIndexForOld)
    }

    /// Returns the dead-end nodes of the graph without removing them.
    ///
    /// This is the detection-only counterpart to
    /// ``prunedDeadEnds(maximumBranches:)``; it returns the same set of nodes
    /// that the pruning would remove, leaving the graph unchanged. Useful for
    /// inspection and analysis before deciding whether to clean up.
    ///
    /// - Parameter maximumBranches: An optional cap on dead-end branch length;
    ///   branches longer than this are excluded from the result. `nil` (the
    ///   default) reports dead-ends of any length.
    /// - Returns: The dead-end nodes in peel order (leaves first), or an empty
    ///   array if the graph is empty or has no dead-ends.
    public func deadEnds(maximumBranches: Int? = nil) -> [Node] {
        guard adjacencyList.isNotEmpty,
            let result = prunedDeadEnds(maximumBranches: maximumBranches)
        else { return [] }
        return result.removedNodes
    }

}
