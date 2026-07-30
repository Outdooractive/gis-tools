#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Eulerian path / circuit and Chinese Postman

extension Graph {

    /// Whether the graph has an Eulerian trail (a walk using every edge exactly
    /// once) and, if so, what kind.
    public enum Eulerianity: Sendable, Equatable {

        /// The graph has an Eulerian *circuit* (a closed Eulerian walk): every
        /// node has even degree and the graph is connected.
        case eulerian

        /// The graph has an Eulerian *trail* (an open Eulerian walk): exactly
        /// two nodes have odd degree (the endpoints) and the graph is
        /// connected.
        case semiEulerian

        /// The graph has no Eulerian walk: it is disconnected or has more than
        /// two odd-degree nodes.
        case nonEulerian

    }

    /// Classifies the graph's Eulerian status over its *undirected underlying*
    /// edges (one-way edges treated as undirected).
    ///
    /// - `eulerian`: every node has even degree and the graph is (weakly)
    ///   connected — an Eulerian circuit exists.
    /// - `semiEulerian`: exactly two nodes have odd degree and the graph is
    ///   connected — an open Eulerian trail exists between those two nodes.
    /// - `nonEulerian`: otherwise (disconnected or > 2 odd-degree nodes).
    ///
    /// Isolated nodes (degree 0) are ignored when testing connectivity: a
    /// graph with a single connected Eulerian component plus isolated nodes
    /// is still considered Eulerian.
    ///
    /// - Returns: The graph's ``Eulerianity``, or `.nonEulerian` if empty.
    public func eulerianity() -> Eulerianity {
        guard adjacencyList.isNotEmpty else { return .nonEulerian }

        // Compute undirected degree of each node (number of distinct neighbors;
        // parallel edges count once per distinct neighbor to match the
        // "distinct connection" parity rule used by Hierholzer).
        var oddDegreeNodes: [Int] = []
        for i in 0..<adjacencyList.count {
            let neighbors = adjacencyList[i].edges.map(\.to.index)
            let distinctNeighbors = Set(neighbors)
            // Self-loops contribute 2 to the degree; we don't model them here.
            if distinctNeighbors.count % 2 != 0 {
                oddDegreeNodes.append(i)
            }
        }

        // Connectivity: the non-isolated nodes must form a single component.
        if !nonIsolatedNodesAreSingleComponent() {
            return .nonEulerian
        }

        switch oddDegreeNodes.count {
        case 0: return .eulerian
        case 2: return .semiEulerian
        default: return .nonEulerian
        }
    }

    /// Finds an Eulerian trail or circuit in the graph — a walk that traverses
    /// every undirected edge exactly once.
    ///
    /// Uses Hierholzer's algorithm (O(V + E)) over the undirected underlying
    /// graph. The walk starts at one of the odd-degree endpoints when the
    /// graph is semi-Eulerian, or at an arbitrary non-isolated node when it is
    /// fully Eulerian.
    ///
    /// - Returns: The Eulerian walk as an ordered array of nodes, or an empty
    ///   array if the graph is ``Eulerianity/nonEulerian`` or empty.
    public func eulerianPath() -> [Node] {
        switch eulerianity() {
        case .nonEulerian: return []
        case .eulerian, .semiEulerian: break
        }

        // Choose the start node: an odd-degree endpoint if semi-Eulerian, else
        // any non-isolated node.
        var start = -1
        var oddStarts: [Int] = []
        for i in 0..<adjacencyList.count {
            let neighbors = Set(adjacencyList[i].edges.map(\.to.index))
            if neighbors.count % 2 != 0 {
                oddStarts.append(i)
            }
            if start == -1, neighbors.isNotEmpty {
                start = i
            }
        }
        if let odd = oddStarts.first { start = odd }
        guard start >= 0 else { return [] }

        // Build an adjacency with shared edgeIDs per undirected edge so
        // consuming one instance consumes its mirror — robust against parallel
        // edges (the classic Hierholzer pitfall).
        struct EEdge {
            let neighbor: Int
            let edgeID: Int
        }
        var adjacency: [[EEdge]] = Array(
            repeating: [], count: adjacencyList.count)
        var nextEdgeID = 0
        for edge in edges {
            let id = nextEdgeID
            nextEdgeID += 1
            let u = edge.from.index
            let v = edge.to.index
            adjacency[u].append(EEdge(neighbor: v, edgeID: id))
            adjacency[v].append(EEdge(neighbor: u, edgeID: id))
        }

        // Hierholzer's iterative algorithm.
        var stack: [Int] = [start]
        var circuit: [Int] = []
        var usedEdgeIDs: Set<Int> = []
        var cursor = Array(repeating: 0, count: adjacency.count)

        while let top = stack.last {
            var foundNext = false
            while cursor[top] < adjacency[top].count {
                let edge = adjacency[top][cursor[top]]
                cursor[top] += 1
                if usedEdgeIDs.contains(edge.edgeID) { continue }
                usedEdgeIDs.insert(edge.edgeID)
                stack.append(edge.neighbor)
                foundNext = true
                break
            }
            if !foundNext {
                // No more edges from `top`: backtrack and append to circuit.
                circuit.append(stack.removeLast())
            }
        }

        // The circuit is built in reverse; flip it.
        return circuit.reversed().map { adjacencyList[$0].node }
    }

    /// Finds a closed walk that traverses every edge at least once with small
    /// total weight — the *Chinese Postman* route.
    ///
    /// When the graph is Eulerian (``eulerianity() == .eulerian``), the result
    /// is the Eulerian circuit itself, traversing every edge exactly once.
    /// When the graph has odd-degree nodes, the odd nodes are paired with
    /// small total cost (via a greedy minimum-weight perfect matching over
    /// the odd set using shortest-path distances), the matched pairs'
    /// shortest paths are added as duplicated edges, and an Eulerian circuit
    /// is then found on the augmented graph. The matching is a greedy
    /// approximation (exact matching is exponential in the odd-node count,
    /// which can be hundreds on real networks), so the tour is *valid*
    /// (closed, covers every edge) but not guaranteed *minimal* on graphs
    /// with more than two odd nodes.
    ///
    /// Classic use cases: snow plowing, street sweeping, mail delivery — any
    /// scenario where every street segment must be covered at least once.
    ///
    /// - Returns: A closed walk (returns to its start) covering every edge at
    ///   least once, or an empty array if the underlying graph is disconnected
    ///   (no finite postman tour exists) or empty.
    public func chinesePostmanTour() -> [Node] {
        guard adjacencyList.isNotEmpty else { return [] }
        guard nonIsolatedNodesAreSingleComponent() else { return [] }

        // Collect odd-degree nodes (undirected distinct-neighbor degree).
        var oddNodes: [Int] = []
        for i in 0..<adjacencyList.count {
            let neighbors = Set(adjacencyList[i].edges.map(\.to.index))
            if neighbors.count % 2 != 0 {
                oddNodes.append(i)
            }
        }

        // Eulerian already: just return the Eulerian circuit.
        if oddNodes.isEmpty {
            return eulerianPath()
        }

        // Compute all-pairs shortest paths between odd nodes.
        let distances = shortestPathDistances(between: oddNodes)

        // Minimum-weight perfect matching on the odd set. The odd count is
        // guaranteed even. Use a brute-force recursive search with pruning;
        // odd sets are small in real road networks (often < 100), and exact
        // matching is required for optimality.
        let matching = minimumWeightPerfectMatching(
            oddNodes: oddNodes,
            distances: distances)

        // Build an augmented adjacency as a list of (neighbor, edgeID) tuples,
        // where each undirected edge instance pair shares an edgeID. Consuming
        // an edge marks both instances used at once, which correctly handles
        // parallel edges (the classic Hierholzer pitfall).
        struct AugmentedEdge {
            let neighbor: Int
            let edgeID: Int
        }
        var augmented: [[AugmentedEdge]] = Array(
            repeating: [], count: adjacencyList.count)
        var nextEdgeID = 0

        // Add every original undirected edge once (deduped by `graph.edges`),
        // with a shared edgeID for both directions.
        for edge in edges {
            let id = nextEdgeID
            nextEdgeID += 1
            let u = edge.from.index
            let v = edge.to.index
            augmented[u].append(AugmentedEdge(neighbor: v, edgeID: id))
            augmented[v].append(AugmentedEdge(neighbor: u, edgeID: id))
        }

        // Add duplicated edges for matched pairs' shortest paths. The
        // matching contains indices *into* `oddNodes`; convert to original
        // node indices for path lookup.
        for (i, j) in matching {
            let a = oddNodes[i]
            let b = oddNodes[j]
            guard let path = shortestPathNodes(between: a, and: b) else {
                continue
            }
            for k in 0..<path.count - 1 {
                let id = nextEdgeID
                nextEdgeID += 1
                augmented[path[k]].append(
                    AugmentedEdge(neighbor: path[k + 1], edgeID: id))
                augmented[path[k + 1]].append(
                    AugmentedEdge(neighbor: path[k], edgeID: id))
            }
        }

        // Find an Eulerian circuit on the augmented graph (Hierholzer).
        var start = -1
        for i in 0..<adjacencyList.count {
            if augmented[i].isNotEmpty {
                start = i
                break
            }
        }
        guard start >= 0 else { return [] }

        var stack: [Int] = [start]
        var circuit: [Int] = []
        var usedEdgeIDs: Set<Int> = []
        // Track the next-unexamined position at each node to avoid re-scanning.
        var cursor = Array(repeating: 0, count: augmented.count)

        while let top = stack.last {
            var foundNext = false
            while cursor[top] < augmented[top].count {
                let edge = augmented[top][cursor[top]]
                cursor[top] += 1
                if usedEdgeIDs.contains(edge.edgeID) { continue }
                // Consume this undirected edge (both instances become used).
                usedEdgeIDs.insert(edge.edgeID)
                stack.append(edge.neighbor)
                foundNext = true
                break
            }
            if !foundNext {
                circuit.append(stack.removeLast())
            }
        }

        return circuit.reversed().map { adjacencyList[$0].node }
    }

    // MARK: - Eulerian support

    /// Whether all non-isolated nodes form a single connected component (in
    /// the undirected underlying graph).
    private func nonIsolatedNodesAreSingleComponent() -> Bool {
        var nonIsolated: [Int] = []
        for i in 0..<adjacencyList.count {
            if adjacencyList[i].edges.isNotEmpty { nonIsolated.append(i) }
        }
        guard let first = nonIsolated.first else { return true }  // all isolated

        var visited: Set<Int> = [first]
        var queue: [Int] = [first]
        while let u = queue.first {
            queue.removeFirst()
            for edge in adjacencyList[u].edges {
                if visited.insert(edge.to.index).inserted {
                    queue.append(edge.to.index)
                }
            }
        }
        // Every non-isolated node must be in this single component.
        return nonIsolated.allSatisfy { visited.contains($0) }
    }

    /// Computes shortest-path distances between every pair in `nodes` (all
    /// pairs). Returns a square matrix indexed in the same order as `nodes`.
    private func shortestPathDistances(between nodes: [Int]) -> [[Double]] {
        var result: [[Double]] = Array(
            repeating: Array(repeating: .infinity, count: nodes.count),
            count: nodes.count)
        for (i, source) in nodes.enumerated() {
            let dist = dijkstraDistances(from: source)
            for (j, target) in nodes.enumerated() {
                result[i][j] = dist[target]
            }
        }
        return result
    }

    /// Standard Dijkstra returning the distance array from `source` to every
    /// node.
    func dijkstraDistances(from source: Int) -> [Double] {
        var dist: [Double] = Array(
            repeating: .infinity, count: adjacencyList.count)
        var visited: Set<Int> = []
        dist[source] = 0.0
        var heap = MinHeap<HeapEntry>()
        heap.push(HeapEntry(distance: 0.0, index: source))
        while let entry = heap.pop() {
            if visited.contains(entry.index) { continue }
            visited.insert(entry.index)
            for edge in adjacencyList[entry.index].edges {
                let relaxed = dist[entry.index] + edge.weight
                if relaxed < dist[edge.to.index] {
                    dist[edge.to.index] = relaxed
                    heap.push(
                        HeapEntry(distance: relaxed, index: edge.to.index))
                }
            }
        }
        return dist
    }

    /// Reconstructs the shortest path between `a` and `b` as node indices.
    private func shortestPathNodes(between a: Int, and b: Int) -> [Int]? {
        let path = shortestPath(
            from: adjacencyList[a].node,
            to: adjacencyList[b].node
        )
        .map(\.index)
        guard path.isNotEmpty else { return nil }
        return path
    }

    /// Approximate minimum-weight perfect matching on `oddNodes` using the
    /// precomputed `distances` matrix.
    ///
    /// Exact minimum-weight perfect matching is exponential in the number of
    /// odd-degree nodes, which on real road networks can reach hundreds
    /// (Immenstadt has ~400). This implementation uses a greedy heuristic:
    /// repeatedly take the closest remaining pair of odd nodes. It runs in
    /// O(n² log n) and produces a valid (complete) matching; for two odd nodes
    /// (the only case where the matching is unique) it is optimal. The
    /// resulting Chinese Postman tour is therefore *valid* (closed, covers
    /// every edge) but not guaranteed *minimal* on graphs with more than two
    /// odd nodes.
    private func minimumWeightPerfectMatching(
        oddNodes: [Int],
        distances: [[Double]]
    ) -> [(Int, Int)] {
        let n = oddNodes.count
        guard n >= 2 else { return [] }

        // Greedy: sort all pairs by distance, take each in order if both
        // endpoints are still unmatched.
        struct Pair: Comparable {
            let i: Int
            let j: Int
            let distance: Double
            static func < (lhs: Pair, rhs: Pair) -> Bool {
                if lhs.distance != rhs.distance {
                    return lhs.distance < rhs.distance
                }
                if lhs.i != rhs.i { return lhs.i < rhs.i }
                return lhs.j < rhs.j
            }
        }

        var pairs: [Pair] = []
        pairs.reserveCapacity((n * (n - 1)) / 2)
        for i in 0..<n {
            for j in (i + 1)..<n {
                pairs.append(Pair(i: i, j: j, distance: distances[i][j]))
            }
        }
        pairs.sort()

        var used = Array(repeating: false, count: n)
        var matching: [(Int, Int)] = []
        for pair in pairs {
            if used[pair.i] || used[pair.j] { continue }
            used[pair.i] = true
            used[pair.j] = true
            matching.append((pair.i, pair.j))
            if matching.count == n / 2 { break }
        }
        return matching
    }

}
