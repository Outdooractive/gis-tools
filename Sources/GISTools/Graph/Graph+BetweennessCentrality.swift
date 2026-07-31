#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Betweenness centrality (Brandes' algorithm, weighted)

extension Graph {

    /// Computes the *betweenness centrality* of every node: how often it lies
    /// on a shortest path between two other nodes.
    ///
    /// Betweenness centrality identifies the most important intersections in a
    /// road network — nodes with high betweenness carry a lot of through
    /// traffic and are critical for routing. Removing a high-betweenness node
    /// (especially if it is also an ``articulationPoints()|articulation
    /// point``) has outsized impact on reachability.
    ///
    /// The implementation is Brandes' algorithm generalised to weighted graphs:
    /// for each source `s`, run Dijkstra counting the number of shortest paths
    /// `σ[s][t]` to every target `t`, then accumulate dependencies
    /// `δ[s][·]` by traversing predecessors in reverse order. The per-node
    /// centrality is the sum over all sources of these dependencies. Runs in
    /// O(V · (V + E) log V) = O(VE log V) for weighted graphs.
    ///
    /// Edges are treated as directed when the graph is directed (one-way
    /// rules respected); otherwise the graph is undirected. Reported values
    /// are **unnormalised**; callers may normalise by
    /// `1 / ((V - 1) * (V - 2))` for undirected graphs if desired.
    ///
    /// - Parameter edgeFilter: An optional predicate that must accept an edge
    ///   for it to be traversable.
    /// - Returns: A dictionary mapping each node to its betweenness centrality
    ///   score. Isolated nodes (and nodes on no shortest path between others)
    ///   score `0.0`. Returns an empty dictionary if the graph is empty.
    public func betweennessCentrality(
        edgeFilter: ((Edge) -> Bool)? = nil
    ) -> [Node: Double] {
        guard adjacencyList.isNotEmpty else { return [:] }

        let n = adjacencyList.count
        var centrality = Array(repeating: 0.0, count: n)

        for s in 0..<n {
            // Single-source Brandes pass (Dijkstra-based).
            // dist[], sigma[], pred[] (predecessor lists).
            var dist: [Double] = Array(repeating: .infinity, count: n)
            var sigma: [Double] = Array(repeating: 0.0, count: n)
            var pred: [Set<Int>] = Array(repeating: [], count: n)
            var visitedOrder: [Int] = []  // nodes in order of settlement

            dist[s] = 0.0
            sigma[s] = 1.0
            var heap = MinHeap<HeapEntry>()
            heap.push(HeapEntry(distance: 0.0, index: s))

            while let entry = heap.pop() {
                let v = entry.index
                if dist[v] < entry.distance { continue }  // stale entry
                visitedOrder.append(v)

                for edge in adjacencyList[v].edges {
                    if let edgeFilter, !edgeFilter(edge) { continue }
                    let w = edge.to.index
                    let relaxed = dist[v] + edge.weight
                    if relaxed < dist[w] {
                        // Found a shorter path: reset predecessors and sigma.
                        dist[w] = relaxed
                        sigma[w] = sigma[v]
                        pred[w] = [v]
                        heap.push(HeapEntry(distance: relaxed, index: w))
                    }
                    else if relaxed == dist[w] {
                        // Equal-length alternative path: accumulate.
                        sigma[w] += sigma[v]
                        pred[w].insert(v)
                    }
                }
            }

            // Dependency accumulation, in reverse order of settlement.
            var delta = Array(repeating: 0.0, count: n)
            for v in visitedOrder.reversed() {
                for w in pred[v] {
                    let contribution = (sigma[v] / sigma[w]) * (1.0 + delta[v])
                    delta[w] += contribution
                }
                if v != s {
                    centrality[v] += delta[v]
                }
            }
        }

        // For undirected graphs, each pair is counted twice (once per
        // direction); halve to match the standard undirected definition. For
        // directed graphs, leave as-is (directions are distinct).
        if !isDirected {
            for i in 0..<n {
                centrality[i] /= 2.0
            }
        }

        var result: [Node: Double] = [:]
        for i in 0..<n {
            result[adjacencyList[i].node] = centrality[i]
        }
        return result
    }

}
