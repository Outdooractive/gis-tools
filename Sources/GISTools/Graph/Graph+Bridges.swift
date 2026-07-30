#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Bridge detection (Tarjan's low-link DFS)

extension Graph {

    /// Returns the *bridges* of the graph: edges whose removal increases the
    /// number of (weakly) connected components.
    ///
    /// A bridge is a road segment with no alternative route — once removed,
    /// part of the network becomes unreachable from the rest. Identifying
    /// bridges is the foundation of vulnerability analysis for road networks.
    ///
    /// Detection uses Tarjan's single-pass low-link DFS over the *undirected
    /// underlying* graph (every stored edge — including one-way edges in
    /// directed graphs — is treated as an undirected connection, since a
    /// one-way road that is the only link between two areas is still a
    /// weak-connectivity bridge). The algorithm runs in O(V + E):
    /// for each tree edge `u -> v`, it is a bridge iff
    /// `low[v] > disc[u]` — i.e. `v` cannot reach `u` or an ancestor of `u`
    /// via any back edge.
    ///
    /// Parallel edges (multiple distinct edges between the same pair of
    /// nodes) are handled correctly: they are never bridges, because
    /// removing one leaves the others as an alternate route. The parent edge
    /// is tracked by its undirected endpoint pair with one-occurrence
    /// skipping, so a parallel edge back to the parent is treated as a back
    /// edge rather than the tree edge we arrived on.
    ///
    /// - Returns: The bridge edges, deduplicated so each undirected bridge is
    ///   reported exactly once (directed one-way bridges appear once). Returns
    ///   an empty array if the graph has no bridges or is empty.
    public func bridges() -> [Edge] {
        guard adjacencyList.isNotEmpty else { return [] }

        let n = adjacencyList.count
        var disc: [Int] = Array(repeating: -1, count: n)
        var low: [Int] = Array(repeating: 0, count: n)
        var timer = 0
        var bridges: [Edge] = []
        var reportedKeys: Set<BridgeEdgeKey> = []

        for start in 0..<n where disc[start] == -1 {
            // Iterative DFS stack. Each frame records the node, the undirected
            // key of the edge used to reach it (for parent skipping), and the
            // next neighbor index to process.
            var stack: [DFSFrame] = [
                DFSFrame(node: start, parentKey: nil, nextEdge: 0)
            ]
            disc[start] = timer
            low[start] = timer
            timer += 1

            while let frame = stack.last {
                let u = frame.node
                let edges = adjacencyList[u].edges

                if frame.nextEdge < edges.count {
                    // Advance the top frame's edge cursor before processing so
                    // the next iteration continues from the following edge.
                    stack[stack.count - 1].nextEdge += 1
                    let edge = edges[frame.nextEdge]
                    let v = edge.to.index
                    let key = BridgeEdgeKey(a: u, b: v)

                    // Skip the edge we arrived on (the parent edge). For
                    // parallel edges with the same key, skip only the first
                    // occurrence so subsequent ones act as back edges.
                    if let parent = frame.parentKey, key == parent,
                        !frame.skippedParent
                    {
                        stack[stack.count - 1].skippedParent = true
                        continue
                    }

                    if disc[v] == -1 {
                        // Tree edge: descend into v.
                        disc[v] = timer
                        low[v] = timer
                        timer += 1
                        stack.append(
                            DFSFrame(node: v, parentKey: key, nextEdge: 0))
                    } else {
                        // Back edge (or forward/cross edge in the undirected
                        // view): update low[u] via the neighbor's discovery.
                        low[u] = min(low[u], disc[v])
                    }
                } else {
                    // All neighbors processed: pop and propagate low to parent.
                    stack.removeLast()
                    if let parent = stack.last {
                        let pu = parent.node
                        low[pu] = min(low[pu], low[u])
                        // Bridge condition: v (= u) cannot reach pu or above.
                        if low[u] > disc[pu] {
                            // The edge pu -> u is a bridge. Report it. Find
                            // the actual stored edge from pu to u.
                            if let edge = adjacencyList[pu].edges.first(where: {
                                $0.to.index == u
                            }),
                                reportedKeys.insert(BridgeEdgeKey(a: pu, b: u))
                                    .inserted
                            {
                                bridges.append(edge)
                            }
                        }
                    }
                }
            }
        }

        return bridges
    }

    // MARK: - Bridge support

    struct DFSFrame {
        let node: Int
        let parentKey: BridgeEdgeKey?
        var nextEdge: Int
        var skippedParent: Bool = false
    }

    /// An undirected, normalized edge key (min/max endpoints) used for parent
    /// skipping and bridge deduplication.
    struct BridgeEdgeKey: Hashable {

        let a: Int
        let b: Int

        init(a: Int, b: Int) {
            self.a = min(a, b)
            self.b = max(a, b)
        }

    }

}
