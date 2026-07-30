#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Shortest path (A* with straight-line heuristic)

extension Graph {

    /// Finds the shortest path between two nodes using the A* algorithm.
    ///
    /// A* is a best-first search that guides Dijkstra's exploration with a
    /// heuristic estimate of the remaining cost. Here the heuristic is the
    /// straight-line (great-circle for EPSG:4326, Euclidean for the planar
    /// projections) distance from each node to the destination, which is
    /// admissible and consistent because edge weights are computed with the
    /// same distance function. This makes A* dramatically faster than
    /// ``shortestPath(from:to:blockedNodes:edgeFilter:)`` for point-to-point
    /// routing while still returning the optimal path.
    ///
    /// - Parameters:
    ///   - source: The start node.
    ///   - destination: The target node.
    ///   - blockedNodes: An optional set of nodes to avoid.
    ///   - edgeFilter: An optional predicate that must accept an edge for it
    ///     to be traversable. Use this to restrict routing to certain feature
    ///     types (e.g. footways for hiking, cycleways for cycling).
    /// - Returns: The shortest path as an ordered array of nodes (including
    ///   `source` and `destination`), or an empty array if no path exists.
    public func aStarPath(
        from source: Node,
        to destination: Node,
        blockedNodes: Set<Node>? = nil,
        edgeFilter: ((Edge) -> Bool)? = nil
    ) -> [Node] {
        guard source.index >= 0, source.index < adjacencyList.count,
            destination.index >= 0, destination.index < adjacencyList.count
        else { return [] }

        if source == destination { return [source] }

        let blockedSet: Set<Int> = Set(blockedNodes?.map(\.index) ?? [])
        let destinationCoordinate = adjacencyList[destination.index].node
            .coordinate

        // Heuristic: straight-line distance from `index` to the destination.
        func heuristic(_ index: Int) -> Double {
            adjacencyList[index].node.coordinate.distance(
                from: destinationCoordinate)
        }

        var gScore: [Double] = Array(
            repeating: .infinity, count: adjacencyList.count)
        var predecessors: [Int] = Array(
            repeating: -1, count: adjacencyList.count)
        var visited: Set<Int> = []

        gScore[source.index] = 0.0

        // Min-heap ordered by f = g + h. O((V+E) log V).
        var heap = MinHeap<AStarEntry>()
        heap.push(
            AStarEntry(fScore: heuristic(source.index), index: source.index))

        while let entry = heap.pop() {
            if visited.contains(entry.index) { continue }
            if entry.index == destination.index { break }
            visited.insert(entry.index)

            let currentG = gScore[entry.index]

            for edge in adjacencyList[entry.index].edges {
                let neighborIndex = edge.to.index

                if blockedSet.contains(neighborIndex) { continue }
                if let edgeFilter, !edgeFilter(edge) { continue }

                let relaxed = currentG + edge.weight
                if relaxed < gScore[neighborIndex] {
                    gScore[neighborIndex] = relaxed
                    predecessors[neighborIndex] = entry.index
                    let f = relaxed + heuristic(neighborIndex)
                    heap.push(AStarEntry(fScore: f, index: neighborIndex))
                }
            }
        }

        guard gScore[destination.index] < .infinity else { return [] }

        var pathIndices: [Int] = [destination.index]
        var index = predecessors[destination.index]
        while index != -1, index != source.index {
            pathIndices.append(index)
            index = predecessors[index]
        }
        pathIndices.append(source.index)

        return pathIndices.reversed().map { adjacencyList[$0].node }
    }

    // MARK: - A* heap support

    struct AStarEntry: Comparable {

        /// The estimated total cost `f = g + h` for the node at ``index``.
        let fScore: Double
        let index: Int

        static func < (lhs: AStarEntry, rhs: AStarEntry) -> Bool {
            if lhs.fScore != rhs.fScore {
                return lhs.fScore < rhs.fScore
            }
            return lhs.index < rhs.index
        }

    }

}
