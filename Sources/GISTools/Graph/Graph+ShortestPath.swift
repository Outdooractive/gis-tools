#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Shortest path (Dijkstra with binary heap)

extension Graph {

    /// Finds the shortest path between two nodes using Dijkstra's algorithm.
    ///
    /// - Parameters:
    ///   - source: The start node.
    ///   - destination: The target node.
    ///   - blockedNodes: An optional set of nodes to avoid.
    ///   - edgeFilter: An optional predicate that must accept an edge for it to
    ///     be traversable. Use this to restrict routing to certain feature
    ///     types (e.g. footways for hiking, cycleways for cycling).
    /// - Returns: The shortest path as an ordered array of nodes (including
    ///   `source` and `destination`), or an empty array if no path exists.
    public func shortestPath(
        from source: Node,
        to destination: Node,
        blockedNodes: Set<Node>? = nil,
        edgeFilter: ((Edge) -> Bool)? = nil
    ) -> [Node] {
        guard source.index >= 0,
            source.index < adjacencyList.count,
            destination.index >= 0,
            destination.index < adjacencyList.count
        else { return [] }

        if source == destination { return [source] }

        let blocked = blockedNodes?.map(\.index) ?? []
        let blockedSet: Set<Int> = Set(blocked)

        var distances: [Double] = Array(repeating: .infinity, count: adjacencyList.count)
        var predecessors: [Int] = Array(repeating: -1, count: adjacencyList.count)
        var visited: Set<Int> = []

        distances[source.index] = 0.0

        // Min-heap of (distance, index). O((V+E) log V).
        var heap = MinHeap<HeapEntry>()
        heap.push(HeapEntry(distance: 0.0, index: source.index))

        while let entry = heap.pop() {
            if visited.contains(entry.index) { continue }
            if entry.index == destination.index { break }
            visited.insert(entry.index)

            let currentDistance = entry.distance

            for edge in adjacencyList[entry.index].edges {
                let neighborIndex = edge.to.index

                if blockedSet.contains(neighborIndex) { continue }
                if let edgeFilter, !edgeFilter(edge) { continue }

                let relaxed = currentDistance + edge.weight
                if relaxed < distances[neighborIndex] {
                    distances[neighborIndex] = relaxed
                    predecessors[neighborIndex] = entry.index
                    heap.push(HeapEntry(distance: relaxed, index: neighborIndex))
                }
            }
        }

        guard distances[destination.index] < .infinity else { return [] }

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
