#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Minimum spanning tree (Kruskal's algorithm with union-find)

extension Graph {

    /// A minimum spanning forest of the graph's *undirected* edges, found via
    /// Kruskal's algorithm.
    ///
    /// The minimum spanning tree (MST) connects nodes with the smallest total
    /// edge weight such that every node is reachable from every other. When the
    /// graph has multiple connected components, the result is a *minimum
    /// spanning forest* — one MST per component. This is useful for utility
    /// network design, trail planning, and as a sparse backbone for
    /// approximation algorithms.
    ///
    /// The algorithm:
    /// - Sorts all unique undirected edges by weight (ascending).
    /// - Adds each edge iff its endpoints are in different disjoint sets,
    ///   merging the sets (union-find with path compression + union by rank).
    ///
    /// Runs in O(E log E) = O(E log V). For directed graphs the spanning
    /// structure is computed over the *undirected underlying* graph (one-way
    /// edges are treated as undirected); each included undirected edge is
    /// reported once.
    ///
    /// - Returns: The MST/forest edges, one per included undirected connection,
    ///   or an empty array if the graph is empty. The result connects every
    ///   node of every connected component with minimal total weight.
    public func minimumSpanningTree() -> [Edge] {
        guard adjacencyList.isNotEmpty else { return [] }

        // Collect unique undirected edges (dedup by normalized endpoint pair,
        // keeping the lowest-weight instance to handle parallel edges).
        var bestByPair: [MSTEdgeKey: Edge] = [:]
        for edgeList in adjacencyList {
            for edge in edgeList.edges {
                let key = MSTEdgeKey(a: edge.from.index, b: edge.to.index)
                if let existing = bestByPair[key],
                    existing.weight <= edge.weight
                {
                    continue
                }
                bestByPair[key] = edge
            }
        }

        // Sort by weight ascending; tie-break deterministically by endpoints.
        let sortedEdges = bestByPair.values.sorted { lhs, rhs in
            if lhs.weight != rhs.weight { return lhs.weight < rhs.weight }
            if lhs.from.index != rhs.from.index {
                return lhs.from.index < rhs.from.index
            }
            return lhs.to.index < rhs.to.index
        }

        var uf = UnionFind(count: adjacencyList.count)
        var tree: [Edge] = []
        for edge in sortedEdges {
            let a = edge.from.index
            let b = edge.to.index
            if uf.union(a, b) {
                tree.append(edge)
            }
        }
        return tree
    }

    // MARK: - MST support

    /// Normalized undirected edge key for deduplication.
    struct MSTEdgeKey: Hashable {

        let a: Int
        let b: Int

        init(a: Int, b: Int) {
            self.a = min(a, b)
            self.b = max(a, b)
        }

    }

    /// A disjoint-set / union-find structure with path compression and union
    /// by rank, used by ``minimumSpanningTree()``.
    struct UnionFind {

        private var parent: [Int]
        private var rank: [Int]

        init(count: Int) {
            parent = Array(0..<count)
            rank = Array(repeating: 0, count: count)
        }

        mutating func find(_ x: Int) -> Int {
            var root = x
            while parent[root] != root {
                root = parent[root]
            }
            // Path compression: point every node along the path at the root.
            var current = x
            while parent[current] != root {
                let next = parent[current]
                parent[current] = root
                current = next
            }
            return root
        }

        mutating func union(_ x: Int, _ y: Int) -> Bool {
            let rx = find(x)
            let ry = find(y)
            if rx == ry { return false }
            // Union by rank: attach the shorter tree under the taller.
            if rank[rx] < rank[ry] {
                parent[rx] = ry
            } else if rank[rx] > rank[ry] {
                parent[ry] = rx
            } else {
                parent[ry] = rx
                rank[rx] += 1
            }
            return true
        }

    }

}
