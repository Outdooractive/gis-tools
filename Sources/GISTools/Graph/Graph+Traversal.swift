#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Traversal

extension Graph {

    /// Performs a breadth-first search from the given node, returning nodes in
    /// visit order.
    public func breadthFirstSearch(from start: Node) -> [Node] {
        guard start.index >= 0,
              start.index < adjacencyList.count
        else { return [] }

        var visited: Set<Int> = [start.index]
        var queue: [Int] = [start.index]
        var result: [Node] = [start]

        while queue.isNotEmpty {
            let current = queue.removeFirst()
            for edge in adjacencyList[current].edges {
                if visited.insert(edge.to.index).inserted {
                    queue.append(edge.to.index)
                    result.append(adjacencyList[edge.to.index].node)
                }
            }
        }

        return result
    }

    /// Performs a depth-first search from the given node, returning nodes in
    /// visit order.
    public func depthFirstSearch(from start: Node) -> [Node] {
        guard start.index >= 0,
              start.index < adjacencyList.count
        else { return [] }

        var visited: Set<Int> = []
        var result: [Node] = []

        var stack: [Int] = [start.index]
        while let current = stack.popLast() {
            guard visited.insert(current).inserted else { continue }

            result.append(adjacencyList[current].node)
            // Push neighbors in reverse so they're visited in natural order.
            let edges = adjacencyList[current].edges
            for edge in edges.reversed() {
                if !visited.contains(edge.to.index) {
                    stack.append(edge.to.index)
                }
            }
        }

        return result
    }

    /// Partitions the graph into connected components.
    ///
    /// Each component is an array of nodes that are connected via edges.
    /// Isolated nodes each form their own component.
    public var connectedComponents: [[Node]] {
        var visited: Set<Int> = []
        var components: [[Node]] = []

        for index in 0 ..< adjacencyList.count {
            guard visited.insert(index).inserted else { continue }

            var component: [Node] = [adjacencyList[index].node]
            var queue: [Int] = [index]

            while !queue.isEmpty {
                let current = queue.removeFirst()
                for edge in adjacencyList[current].edges {
                    if visited.insert(edge.to.index).inserted {
                        queue.append(edge.to.index)
                        component.append(adjacencyList[edge.to.index].node)
                    }
                }
            }

            components.append(component)
        }

        return components
    }

}
