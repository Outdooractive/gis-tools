#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Strongly connected components (Tarjan's algorithm)

extension Graph {

    /// The strongly connected components (SCCs) of the graph, found via
    /// Tarjan's single-pass low-link DFS.
    ///
    /// A strongly connected component is a maximal group of nodes that are all
    /// *mutually reachable* via directed edges: from any node in the component
    /// you can reach any other and return. This is strictly stronger than the
    /// weak connectivity used by ``connectedComponents`` and applies only to
    /// directed graphs — in an undirected graph every connected component is
    /// also strongly connected.
    ///
    /// SCCs are the standard tool for analyzing one-way street systems: each
    /// SCC is a region where every intersection is reachable from every other
    /// (following one-way rules), and the *condensation* (the DAG of SCCs)
    /// reveals which regions can reach which others. Nodes in trivial
    /// (singleton) SCCs that point outward but receive no return path mark
    /// unreachable areas under the one-way regime.
    ///
    /// The algorithm runs in O(V + E) and uses an iterative DFS to avoid stack
    /// overflow on large networks.
    ///
    /// - Returns: The strongly connected components as arrays of nodes, one
    ///   per component. Order within a component is unspecified; components are
    ///   returned in reverse topological order (a component appears before any
    ///   component that can reach it). Returns an empty array if the graph is
    ///   empty.
    public func stronglyConnectedComponents() -> [[Node]] {
        guard adjacencyList.isNotEmpty else { return [] }

        let n = adjacencyList.count
        var disc: [Int] = Array(repeating: -1, count: n)
        var low: [Int] = Array(repeating: 0, count: n)
        var onStack: [Bool] = Array(repeating: false, count: n)
        var stack: [Int] = []
        var timer = 0
        var components: [[Node]] = []

        for start in 0..<n where disc[start] == -1 {
            // Iterative Tarjan DFS. Each frame records the node and the next
            // outgoing edge index to process.
            var dfsStack: [SCCFrame] = [SCCFrame(node: start, nextEdge: 0)]
            disc[start] = timer
            low[start] = timer
            timer += 1
            stack.append(start)
            onStack[start] = true

            while let frame = dfsStack.last {
                let u = frame.node
                let edges = adjacencyList[u].edges

                if frame.nextEdge < edges.count {
                    dfsStack[dfsStack.count - 1].nextEdge += 1
                    let v = edges[frame.nextEdge].to.index

                    if disc[v] == -1 {
                        // Tree edge: descend.
                        disc[v] = timer
                        low[v] = timer
                        timer += 1
                        stack.append(v)
                        onStack[v] = true
                        dfsStack.append(SCCFrame(node: v, nextEdge: 0))
                    } else if onStack[v] {
                        // Back edge to a node on the current recursion stack:
                        // update low[u] via its discovery.
                        low[u] = min(low[u], disc[v])
                    }
                    // Else: cross/forward edge to an already-popped node —
                    // ignore (cannot contribute to a SCC with u).
                } else {
                    // All neighbors processed: pop and propagate low to parent.
                    dfsStack.removeLast()
                    if let parent = dfsStack.last {
                        low[parent.node] = min(low[parent.node], low[u])
                    }

                    // If u is the root of an SCC (low == disc), pop the stack
                    // down to and including u to form the component.
                    if low[u] == disc[u] {
                        var component: [Node] = []
                        while let w = stack.popLast() {
                            onStack[w] = false
                            component.append(adjacencyList[w].node)
                            if w == u { break }
                        }
                        components.append(component)
                    }
                }
            }
        }

        return components
    }

    // MARK: - SCC support

    struct SCCFrame {
        let node: Int
        var nextEdge: Int
    }

}
