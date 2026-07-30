#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Traveling salesperson approximation (nearest neighbor + 2-opt)

extension Graph {

    /// The result of an approximate traveling-salesperson tour.
    public struct TspTour: Sendable {

        /// The ordered nodes of the tour, including the return to the start so
        /// the tour is closed.
        public let nodes: [Node]

        /// The total length (sum of edge weights / shortest-path distances) of
        /// the tour, in meters.
        public let totalLength: Double

    }

    /// Computes an approximate solution to the traveling salesperson problem
    /// (TSP) over the given set of nodes: a closed tour visiting every node
    /// once with small total length.
    ///
    /// TSP is NP-hard, so this returns a heuristic approximation. The
    /// construction phase uses the *nearest-neighbor* greedy heuristic (start
    /// at a node, repeatedly visit the nearest unvisited node, then return to
    /// the start), then a *2-opt* local search improves the tour by reversing
    /// segments that reduce the total length until no improving swap remains.
    ///
    /// Distances between the selected nodes are the true shortest-path
    /// distances through the graph (computed via Dijkstra from each node), so
    /// the tour is valid even when the nodes are not directly connected. The
    /// returned `nodes` array lists the visit order **including the return to
    /// the start** (so it contains `count + 1` entries, the first and last
    /// equal).
    ///
    /// Use cases: delivery route planning, inspection routes, any scenario
    /// where a set of locations must be visited with minimal travel.
    ///
    /// - Parameters:
    ///   - nodes: The nodes to visit (must all belong to this graph). Duplicate
    ///     and empty/single inputs are handled (an empty input yields an empty
    ///     tour; a single node yields `[node, node]`).
    ///   - start: An optional node at which to start and end the tour. If
    ///     `nil` (the default), the first node of `nodes` is used.
    /// - Returns: The approximate TSP tour, or an empty tour if `nodes` is
    ///   empty or the nodes are unreachable from each other.
    public func travelingSalespersonTour(
        nodes: [Node],
        start: Node? = nil
    ) -> TspTour {
        // Deduplicate while preserving order.
        var seen = Set<Int>()
        let uniqueNodes = nodes.filter { node in
            node.index >= 0 && node.index < adjacencyList.count
                && seen.insert(node.index).inserted
        }
        guard uniqueNodes.isNotEmpty else {
            return TspTour(nodes: [], totalLength: 0.0)
        }

        if uniqueNodes.count == 1 {
            let only = uniqueNodes[0]
            return TspTour(nodes: [only, only], totalLength: 0.0)
        }

        // Determine the start node.
        let startIndex: Int
        if let start = start, let idx = uniqueNodes.firstIndex(of: start) {
            startIndex = idx
        } else {
            startIndex = 0
        }

        // Compute all-pairs shortest-path distances between the unique nodes.
        let distances = tspDistances(between: uniqueNodes)
        // If any required distance is infinite, the nodes are not all mutually
        // reachable; no tour exists.
        for i in 0..<distances.count {
            for j in 0..<distances.count where i != j {
                if distances[i][j].isInfinite {
                    return TspTour(nodes: [], totalLength: 0.0)
                }
            }
        }

        // Nearest-neighbor construction starting at `startIndex`.
        var order = nearestNeighborOrder(
            uniqueNodes: uniqueNodes,
            distances: distances,
            startIndex: startIndex)

        // 2-opt local search.
        twoOpt(order: &order, distances: distances)

        // Build the closed tour and compute total length.
        var tourNodes: [Node] = []
        for idx in order {
            tourNodes.append(uniqueNodes[idx])
        }
        tourNodes.append(uniqueNodes[order[0]])

        var total = 0.0
        for i in 0..<order.count {
            let from = order[i]
            let to = order[(i + 1) % order.count]
            total += distances[from][to]
        }

        return TspTour(nodes: tourNodes, totalLength: total)
    }

    // MARK: - TSP support

    /// Computes all-pairs shortest-path distances among `nodes`, returning a
    /// square matrix indexed in the same order.
    private func tspDistances(between nodes: [Node]) -> [[Double]] {
        var result: [[Double]] = Array(
            repeating: Array(repeating: .infinity, count: nodes.count),
            count: nodes.count)
        for (i, source) in nodes.enumerated() {
            let dist = dijkstraDistances(from: source.index)
            for (j, target) in nodes.enumerated() {
                result[i][j] = dist[target.index]
            }
            // Zero distance from a node to itself.
            result[i][i] = 0.0
        }
        return result
    }

    /// Greedy nearest-neighbor tour construction starting at `startIndex`,
    /// returning a permutation of node indices.
    private func nearestNeighborOrder(
        uniqueNodes: [Node],
        distances: [[Double]],
        startIndex: Int
    ) -> [Int] {
        let n = uniqueNodes.count
        var visited = Array(repeating: false, count: n)
        var order: [Int] = [startIndex]
        visited[startIndex] = true
        var current = startIndex
        for _ in 0..<(n - 1) {
            var best = -1
            var bestDist = Double.infinity
            for candidate in 0..<n where !visited[candidate] {
                let d = distances[current][candidate]
                if d < bestDist {
                    bestDist = d
                    best = candidate
                }
            }
            if best < 0 { break }
            order.append(best)
            visited[best] = true
            current = best
        }
        return order
    }

    /// Improves the tour `order` in place via 2-opt: repeatedly reverse any
    /// segment whose reversal strictly reduces the total tour length, until
    /// no improving swap remains. Terminates because each accepted swap
    /// strictly decreases the (non-negative) total length.
    private func twoOpt(order: inout [Int], distances: [[Double]]) {
        let n = order.count
        guard n >= 4 else { return }  // 2-opt needs at least 4 nodes
        let epsilon = 0.0000001
        var improved = true
        while improved {
            improved = false
            for i in 0..<(n - 1) {
                for j in (i + 1)..<n {
                    // Skip the full reversal (i == 0 and j == n-1): it just
                    // reverses the entire tour, leaving length unchanged.
                    if i == 0, j == n - 1 { continue }
                    // Edges (pred(i), i) and (j, succ(j)) become
                    // (pred(i), j) and (i, succ(j)) after reversing [i, j].
                    let a = order[i == 0 ? n - 1 : i - 1]
                    let b = order[i]
                    let c = order[j]
                    let d = order[(j + 1) % n]
                    let before = distances[a][b] + distances[c][d]
                    let after = distances[a][c] + distances[b][d]
                    if after < before - epsilon {
                        order[i...j].reverse()
                        improved = true
                    }
                }
            }
        }
    }

}
