#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: K-shortest paths (Yen's algorithm)

extension Graph {

    /// Finds the `k` shortest *simple* paths between two nodes using Yen's
    /// algorithm.
    ///
    /// Yen's algorithm repeatedly computes the shortest path, then for each
    /// node along that path (the "spur node") reruns a shortest-path search
    /// with the root prefix locked and the previously-used spur edge blocked,
    /// producing divergent alternative routes. It returns loop-free paths in
    /// non-decreasing order of total cost.
    ///
    /// This is the foundation of "alternative routes" in navigation apps.
    /// The cost of a path is the sum of its edge weights (geodesic distance by
    /// default). Set `k` higher for more alternatives at the cost of more work;
    /// fewer than `k` paths are returned when the graph does not contain that
    /// many distinct simple paths.
    ///
    /// - Parameters:
    ///   - source: The start node.
    ///   - destination: The target node.
    ///   - k: The maximum number of shortest paths to return (must be >= 1).
    ///   - blockedNodes: An optional set of nodes to avoid.
    ///   - edgeFilter: An optional predicate that must accept an edge for it
    ///     to be traversable.
    /// - Returns: Up to `k` shortest simple paths, each an ordered array of
    ///   nodes (including `source` and `destination`), ordered by increasing
    ///   total cost. An empty array is returned if no path exists.
    public func kShortestPaths(
        from source: Node,
        to destination: Node,
        k: Int,
        blockedNodes: Set<Node>? = nil,
        edgeFilter: ((Edge) -> Bool)? = nil
    ) -> [[Node]] {
        guard source.index >= 0, source.index < adjacencyList.count,
            destination.index >= 0, destination.index < adjacencyList.count,
            k >= 1
        else { return [] }

        if source == destination { return [[source]] }

        // The first shortest path seeds the algorithm.
        guard
            let firstPath = shortestPathOrDefault(
                from: source,
                to: destination,
                blockedNodeIndices: blockedNodes?.map(\.index) ?? [],
                blockedEdges: [],
                edgeFilter: edgeFilter),
            firstPath.isNotEmpty
        else { return [] }

        var foundPaths: [[Node]] = [firstPath]
        var foundPathKeys: Set<PathKey> = [PathKey(firstPath)]
        // Candidate heap ordered by total path cost.
        var candidates = MinHeap<CandidatePath>()
        var candidateKeys: Set<PathKey> = []

        while foundPaths.count < k {
            let previousPath = foundPaths[foundPaths.count - 1]

            // For each spur node along the previously found path (except the
            // destination, which has no outgoing spur edge).
            for i in 0..<(previousPath.count - 1) {
                let spurNode = previousPath[i]
                let rootPath = Array(previousPath[0...i])

                // Block root-path nodes (except the spur node) so the spur
                // search cannot revisit them — keeps paths simple.
                let blockedNodeIndices =
                    (blockedNodes?.map(\.index) ?? [])
                    + rootPath.dropLast().map(\.index)

                // Block the spur edge used by every already-found path that
                // shares this root prefix, forcing the spur to diverge.
                var blockedEdges: [EdgeKey] = []
                for foundPath in foundPaths {
                    guard foundPath.count > i else { continue }
                    let foundRoot = Array(foundPath[0...i])
                    if foundRoot == rootPath {
                        let fromIndex = foundPath[i].index
                        let toIndex = foundPath[i + 1].index
                        blockedEdges.append(
                            EdgeKey(from: fromIndex, to: toIndex))
                    }
                }

                guard
                    let spurPath = shortestPathOrDefault(
                        from: spurNode,
                        to: destination,
                        blockedNodeIndices: blockedNodeIndices,
                        blockedEdges: blockedEdges,
                        edgeFilter: edgeFilter),
                    spurPath.isNotEmpty
                else { continue }

                // Concatenate root (without spur node duplication) + spur path.
                let totalPath = rootPath.dropLast() + spurPath
                let totalArray = Array(totalPath)
                guard totalArray.isNotEmpty else { continue }

                let key = PathKey(totalArray)
                if foundPathKeys.contains(key) || candidateKeys.contains(key) {
                    continue
                }

                let cost = pathCost(totalArray)
                candidates.push(CandidatePath(cost: cost, path: totalArray))
                candidateKeys.insert(key)
            }

            // No more divergent candidates -> stop.
            guard let next = candidates.pop() else { break }

            // A candidate may have been superseded; skip duplicates already
            // promoted to the found set.
            let nextKey = PathKey(next.path)
            if foundPathKeys.contains(nextKey) { continue }

            foundPaths.append(next.path)
            foundPathKeys.insert(nextKey)
            candidateKeys.remove(nextKey)
        }

        return foundPaths
    }

    // MARK: - Yen support

    /// A directed edge key used to block a specific traversal during spur
    /// searches.
    struct EdgeKey: Hashable {

        let from: Int
        let to: Int

    }

    /// A canonical, direction-aware key for a path, used to deduplicate
    /// candidate paths. Built from the node indices.
    struct PathKey: Hashable {

        let indices: [Int]

        init(_ path: [Node]) {
            indices = path.map(\.index)
        }

    }

    struct CandidatePath: Comparable {

        let cost: Double
        let path: [Node]

        static func < (lhs: CandidatePath, rhs: CandidatePath) -> Bool {
            if lhs.cost != rhs.cost {
                return lhs.cost < rhs.cost
            }
            // Tie-break lexicographically on index sequence for determinism.
            let lhsIndices = lhs.path.map(\.index)
            let rhsIndices = rhs.path.map(\.index)
            for i in 0..<min(lhsIndices.count, rhsIndices.count) {
                if lhsIndices[i] != rhsIndices[i] {
                    return lhsIndices[i] < rhsIndices[i]
                }
            }
            return lhsIndices.count < rhsIndices.count
        }

    }

    /// Sum of edge weights along a path, or `.infinity` if any consecutive pair
    /// has no connecting edge.
    private func pathCost(_ path: [Node]) -> Double {
        guard path.count >= 2 else { return 0.0 }
        var total: Double = 0.0
        for i in 1..<path.count {
            guard let weight = weight(from: path[i - 1], to: path[i]) else {
                return .infinity
            }
            total += weight
        }
        return total
    }

    /// Constrained Dijkstra: shortest path that avoids the given node indices
    /// and directed edge pairs. Returns `nil` if no path exists.
    ///
    /// This is the spur-search primitive used by Yen's algorithm.
    fileprivate func shortestPathOrDefault(
        from source: Node,
        to destination: Node,
        blockedNodeIndices: [Int],
        blockedEdges: [EdgeKey],
        edgeFilter: ((Edge) -> Bool)?
    ) -> [Node]? {
        guard source.index >= 0, source.index < adjacencyList.count,
            destination.index >= 0, destination.index < adjacencyList.count
        else { return nil }

        if source == destination { return [source] }

        let blockedNodesSet: Set<Int> = Set(blockedNodeIndices)
        let blockedEdgesSet: Set<EdgeKey> = Set(blockedEdges)

        var distances: [Double] = Array(
            repeating: .infinity, count: adjacencyList.count)
        var predecessors: [Int] = Array(
            repeating: -1, count: adjacencyList.count)
        var visited: Set<Int> = []

        distances[source.index] = 0.0

        var heap = MinHeap<HeapEntry>()
        heap.push(HeapEntry(distance: 0.0, index: source.index))

        while let entry = heap.pop() {
            if visited.contains(entry.index) { continue }
            if entry.index == destination.index { break }
            visited.insert(entry.index)

            let currentDistance = entry.distance

            for edge in adjacencyList[entry.index].edges {
                let neighborIndex = edge.to.index

                if blockedNodesSet.contains(neighborIndex) { continue }
                if blockedEdgesSet.contains(
                    EdgeKey(from: entry.index, to: neighborIndex))
                {
                    continue
                }
                if let edgeFilter, !edgeFilter(edge) { continue }

                let relaxed = currentDistance + edge.weight
                if relaxed < distances[neighborIndex] {
                    distances[neighborIndex] = relaxed
                    predecessors[neighborIndex] = entry.index
                    heap.push(
                        HeapEntry(distance: relaxed, index: neighborIndex))
                }
            }
        }

        guard distances[destination.index] < .infinity else { return nil }

        var pathIndices: [Int] = [destination.index]
        var index = predecessors[destination.index]
        while index != -1, index != source.index {
            pathIndices.append(index)
            index = predecessors[index]
        }
        pathIndices.append(source.index)

        return pathIndices.reversed().map { adjacencyList[$0].node }
    }

}
