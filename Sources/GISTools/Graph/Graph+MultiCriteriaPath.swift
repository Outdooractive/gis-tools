#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Multi-criteria shortest path

extension Graph {

    /// A cost function that combines multiple edge attributes into a single
    /// scalar cost for multi-criteria routing.
    ///
    /// Use this to weight edges by a combination of distance, travel time,
    /// elevation gain, road class, surface quality, or any other feature
    /// property — for example a cycling route that avoids steep hills, or a
    /// time-minimizing route that prefers faster road classes.
    ///
    /// Returning a non-finite cost (`.infinity`) excludes an edge entirely,
    /// equivalent to filtering it out.
    public typealias EdgeCostFunction = (Edge) -> Double

    /// Finds the lowest-cost path between two nodes using a weighted cost
    /// function instead of plain edge distance.
    ///
    /// This is a Dijkstra search whose edge relaxation uses `costFunction`
    /// rather than ``Edge/weight``. The result is the path that minimizes the
    /// sum of edge costs. Because the cost is a single scalar, multi-criteria
    /// optimisation (e.g. `0.6 * distance + 0.4 * elevationGain`) is reduced to
    /// an ordinary shortest-path problem.
    ///
    /// - Parameters:
    ///   - source: The start node.
    ///   - destination: The target node.
    ///   - costFunction: A closure returning the cost of traversing an edge.
    ///     Edges returning `.infinity` are excluded. Use a combination of
    ///     `edge.weight` (geodesic distance), feature properties such as
    ///     `edge.feature?.property(for:)`, or any other derived quantity.
    ///   - blockedNodes: An optional set of nodes to avoid.
    /// - Returns: The minimum-cost path as an ordered array of nodes
    ///   (including `source` and `destination`), or an empty array if no path
    ///   exists.
    public func shortestPath(
        from source: Node,
        to destination: Node,
        costFunction: @escaping EdgeCostFunction,
        blockedNodes: Set<Node>? = nil
    ) -> [Node] {
        guard source.index >= 0, source.index < adjacencyList.count,
            destination.index >= 0, destination.index < adjacencyList.count
        else { return [] }

        if source == destination { return [source] }

        let blockedSet: Set<Int> = Set(blockedNodes?.map(\.index) ?? [])

        var costs: [Double] = Array(
            repeating: .infinity, count: adjacencyList.count)
        var predecessors: [Int] = Array(
            repeating: -1, count: adjacencyList.count)
        var visited: Set<Int> = []

        costs[source.index] = 0.0

        var heap = MinHeap<HeapEntry>()
        heap.push(HeapEntry(distance: 0.0, index: source.index))

        while let entry = heap.pop() {
            if visited.contains(entry.index) { continue }
            if entry.index == destination.index { break }
            visited.insert(entry.index)

            let currentCost = entry.distance

            for edge in adjacencyList[entry.index].edges {
                let neighborIndex = edge.to.index

                if blockedSet.contains(neighborIndex) { continue }

                let edgeCost = costFunction(edge)
                if edgeCost.isInfinite || edgeCost.isNaN { continue }

                let relaxed = currentCost + edgeCost
                if relaxed < costs[neighborIndex] {
                    costs[neighborIndex] = relaxed
                    predecessors[neighborIndex] = entry.index
                    heap.push(
                        HeapEntry(distance: relaxed, index: neighborIndex))
                }
            }
        }

        guard costs[destination.index] < .infinity else { return [] }

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
