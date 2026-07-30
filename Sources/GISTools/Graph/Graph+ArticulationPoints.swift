#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Articulation points (Tarjan's low-link DFS)

extension Graph {

    /// Returns the *articulation points* (cut vertices) of the graph: nodes
    /// whose removal increases the number of (weakly) connected components.
    ///
    /// An articulation point is a critical intersection: once removed, part of
    /// the network becomes unreachable from the rest. Together with
    /// ``bridges()``, this is the foundation of road-network vulnerability
    /// analysis.
    ///
    /// Detection uses Tarjan's single-pass low-link DFS over the *undirected
    /// underlying* graph (every stored edge — including one-way edges in
    /// directed graphs — is treated as an undirected connection). The
    /// algorithm runs in O(V + E). A node `u` is an articulation point iff:
    /// - `u` is the DFS root and has **two or more** tree children, or
    /// - `u` is not the root and has some child `v` with
    ///   `low[v] >= disc[u]` — i.e. `v` cannot reach an ancestor of `u` via
    ///   any back edge.
    ///
    /// Parallel edges are handled correctly via parent-edge tracking with
    /// one-occurrence skipping (same technique as ``bridges()``).
    ///
    /// - Returns: The articulation-point nodes, deduplicated. Returns an empty
    ///   array if the graph has no articulation points or is empty.
    public func articulationPoints() -> [Node] {
        guard adjacencyList.isNotEmpty else { return [] }

        let n = adjacencyList.count
        var disc: [Int] = Array(repeating: -1, count: n)
        var low: [Int] = Array(repeating: 0, count: n)
        var timer = 0
        var result: Set<Int> = []

        for start in 0..<n where disc[start] == -1 {
            // Iterative DFS. Each frame records the node, its parent, the
            // undirected key of the arriving edge (for parent skipping), the
            // next neighbor index, the count of tree children (for the root
            // rule), and a skippedParent flag for parallel-edge handling.
            var stack: [ArticulationFrame] = [
                ArticulationFrame(
                    node: start, parent: -1, parentKey: nil, nextEdge: 0)
            ]
            disc[start] = timer
            low[start] = timer
            timer += 1
            var rootTreeChildren = 0

            while let frame = stack.last {
                let u = frame.node
                let edges = adjacencyList[u].edges

                if frame.nextEdge < edges.count {
                    // Advance the cursor before processing.
                    stack[stack.count - 1].nextEdge += 1
                    let edge = edges[frame.nextEdge]
                    let v = edge.to.index
                    let key = ArticulationEdgeKey(a: u, b: v)

                    // Skip the edge we arrived on (parent edge), once.
                    if let parent = frame.parentKey, key == parent,
                        !frame.skippedParent
                    {
                        stack[stack.count - 1].skippedParent = true
                        continue
                    }

                    if disc[v] == -1 {
                        // Tree edge: descend.
                        if u == start { rootTreeChildren += 1 }
                        stack[stack.count - 1].treeChildren += 1
                        disc[v] = timer
                        low[v] = timer
                        timer += 1
                        stack.append(
                            ArticulationFrame(
                                node: v, parent: u, parentKey: key, nextEdge: 0)
                        )
                    } else {
                        // Back edge: update low[u] via the neighbor's discovery.
                        low[u] = min(low[u], disc[v])
                    }
                } else {
                    // All neighbors processed: pop and propagate low to parent.
                    stack.removeLast()
                    guard let parent = stack.last else { continue }
                    let pu = parent.node
                    low[pu] = min(low[pu], low[u])

                    // Root rule is handled separately (via rootTreeChildren).
                    if pu == start { continue }

                    // Non-root rule: pu is an articulation point if some
                    // child u has low[u] >= disc[pu].
                    if low[u] >= disc[pu] {
                        result.insert(pu)
                    }
                }
            }

            // Root rule: the DFS root is an articulation point iff it has
            // two or more tree children.
            if rootTreeChildren >= 2 {
                result.insert(start)
            }
        }

        return result.map { adjacencyList[$0].node }
    }

    // MARK: - Articulation point support

    struct ArticulationFrame {
        let node: Int
        let parent: Int
        let parentKey: ArticulationEdgeKey?
        var nextEdge: Int
        var treeChildren: Int = 0
        var skippedParent: Bool = false
    }

    /// An undirected, normalized edge key used for parent skipping.
    struct ArticulationEdgeKey: Hashable {

        let a: Int
        let b: Int

        init(a: Int, b: Int) {
            self.a = min(a, b)
            self.b = max(a, b)
        }

    }

}
