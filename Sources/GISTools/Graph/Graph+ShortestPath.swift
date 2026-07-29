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
        guard source.index >= 0, source.index < adjacencyList.count,
              destination.index >= 0, destination.index < adjacencyList.count
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

    // MARK: - Heap support types

    struct HeapEntry: Comparable {

        let distance: Double
        let index: Int

        static func < (lhs: HeapEntry, rhs: HeapEntry) -> Bool {
            if lhs.distance != rhs.distance {
                return lhs.distance < rhs.distance
            }
            return lhs.index < rhs.index
        }

    }

    /// A simple binary min-heap. Not Sendable; used only as a local scratch
    /// structure inside ``shortestPath(from:to:blockedNodes:edgeFilter:)``.
    struct MinHeap<Element: Comparable> {

        private var storage: [Element] = []

        var isEmpty: Bool {
            storage.isEmpty
        }

        mutating func push(_ element: Element) {
            storage.append(element)
            siftUp(storage.count - 1)
        }

        mutating func pop() -> Element? {
            guard storage.isNotEmpty else { return nil }

            storage.swapAt(0, storage.count - 1)
            let result = storage.removeLast()
            if !storage.isEmpty {
                siftDown(0)
            }
            return result
        }

        private mutating func siftUp(_ index: Int) {
            var i = index
            while i > 0 {
                let parent = (i - 1) / 2
                if storage[i] < storage[parent] {
                    storage.swapAt(i, parent)
                    i = parent
                }
                else {
                    return
                }
            }
        }

        private mutating func siftDown(_ index: Int) {
            var i = index
            let n = storage.count
            while true {
                let left = 2 * i + 1
                let right = 2 * i + 2
                var smallest = i
                if left < n, storage[left] < storage[smallest] {
                    smallest = left
                }
                if right < n, storage[right] < storage[smallest] {
                    smallest = right
                }
                if smallest == i {
                    return
                }
                storage.swapAt(i, smallest)
                i = smallest
            }
        }
    }

}
