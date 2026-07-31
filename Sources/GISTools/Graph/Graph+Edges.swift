#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Edge access

extension Graph {

    /// All unique undirected edges (each edge appears once, A->B without B->A).
    ///
    /// For directed graphs, one-way edges appear once and two-way edges appear
    /// once (in their stored forward direction).
    public var edges: [Edge] {
        var seen: Set<Int> = []
        var result: [Edge] = []

        for edgeList in adjacencyList {
            for edge in edgeList.edges {
                let a = min(edge.from.index, edge.to.index)
                let b = max(edge.from.index, edge.to.index)
                // Directed edges have a deterministic direction; include them
                // as-is. Undirected edges are deduped by unordered pair.
                if edge.isDirected {
                    let id = edge.from.index &* 1_000_003 &+ edge.to.index
                    if seen.insert(id).inserted {
                        result.append(edge)
                    }
                }
                else {
                    let id = a &* 1_000_003 &+ b
                    if seen.insert(id).inserted {
                        result.append(edge)
                    }
                }
            }
        }

        return result
    }

    /// The total number of directed edge instances stored internally.
    /// Each undirected edge creates 2 directed instances, so divide by 2
    /// to get the number of undirected edges.
    public var directedEdgeCount: Int {
        adjacencyList.reduce(0) { $0 + $1.edges.count }
    }

    /// The degree (number of incident edges) of the given node, or 0 if the
    /// node is not in the graph.
    public func degree(of node: Node) -> Int {
        guard node.index >= 0,
              node.index < adjacencyList.count
        else { return 0 }
        return adjacencyList[node.index].edges.count
    }

    /// Returns the neighbors of the given node.
    public func neighbors(for source: Node) -> [Node] {
        guard source.index >= 0,
              source.index < adjacencyList.count
        else { return [] }
        return adjacencyList[source.index].edges.map { adjacencyList[$0.to.index].node }
    }

    /// Returns the edges from the given node.
    public func edges(for source: Node) -> [Edge] {
        guard source.index >= 0,
              source.index < adjacencyList.count
        else { return [] }
        return adjacencyList[source.index].edges
    }

    /// Returns the weight of the edge from source to destination, or `nil` if
    /// there is no edge.
    public func weight(
        from source: Node,
        to destination: Node
    ) -> Double? {
        guard source.index >= 0,
              source.index < adjacencyList.count
        else { return nil }
        return adjacencyList[source.index].edges.first(where: { $0.to == destination })?.weight
    }

    /// Returns the feature associated with the edge from source to destination,
    /// or `nil`.
    public func feature(
        from source: Node,
        to destination: Node
    ) -> Feature? {
        guard source.index >= 0,
              source.index < adjacencyList.count
        else { return nil }
        return adjacencyList[source.index].edges.first(where: { $0.to == destination })?.feature
    }

    // MARK: - Edge manipulation

    /// Adds a directed edge between two nodes.
    public mutating func addDirectedEdge(
        from: Node,
        to: Node,
        feature: Feature? = nil,
        isDirected: Bool = false
    ) {
        let edge = Edge(from: from, to: to, feature: feature, isDirected: isDirected)
        adjacencyList[from.index].edges.append(edge)
    }

    /// Removes a directed edge between two nodes.
    public mutating func removeDirectedEdge(
        from: Node,
        to: Node
    ) {
        guard from.index >= 0,
              from.index < adjacencyList.count
        else { return }
        adjacencyList[from.index].edges.removeAll { $0.to == to }
    }

    /// Adds an undirected edge (both directions) between two nodes.
    public mutating func addUndirectedEdge(
        from: Node,
        to: Node,
        feature: Feature? = nil
    ) {
        addDirectedEdge(from: from, to: to, feature: feature, isDirected: false)
        addDirectedEdge(from: to, to: from, feature: feature, isDirected: false)
    }

    /// Removes an undirected edge (both directions) between two nodes.
    public mutating func removeUndirectedEdge(
        from: Node,
        to: Node
    ) {
        removeDirectedEdge(from: from, to: to)
        removeDirectedEdge(from: to, to: from)
    }

}
