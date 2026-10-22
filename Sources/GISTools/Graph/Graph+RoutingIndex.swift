import Foundation

// MARK: - Reusable routing index

extension Graph {

    /// A precomputed contraction index for repeated point-to-point queries.
    ///
    /// Building the index runs ``contracted()`` once. Queries then map their
    /// endpoints into the contracted graph, run the selected search there and
    /// expand the result back to the original graph.
    ///
    /// Use this when many routes will be computed on the same graph. For a
    /// single query, a direct ``aStarPath(from:to:blockedNodes:edgeFilter:)``
    /// avoids the preprocessing cost.
    ///
    /// Searches with `blockedNodes` or `edgeFilter` cannot use the contracted
    /// index because contraction merges edge properties, so those calls fall
    /// back to the original graph.
    public struct RoutingIndex: Sendable {

        private let original: Graph
        private let contraction: ContractionResult

        /// Builds a routing index for a graph.
        ///
        /// Returns `nil` when the graph is empty.
        public init?(_ graph: Graph) {
            guard let contraction = graph.contracted(cachingChains: true) else {
                return nil
            }

            self.original = graph
            self.contraction = contraction
        }

        /// The number of nodes in the original graph.
        public var originalNodeCount: Int {
            original.nodeCount
        }

        /// The number of nodes after contraction.
        public var contractedNodeCount: Int {
            contraction.graph.nodeCount
        }

        /// Finds a shortest path using Dijkstra on the contracted graph.
        public func shortestPath(from source: Node, to destination: Node) -> [Node] {
            route(from: source, to: destination) {
                $0.shortestPath(from: $1, to: $2)
            }
        }

        /// Finds a shortest path using A* on the contracted graph.
        public func aStarPath(from source: Node, to destination: Node) -> [Node] {
            route(from: source, to: destination) {
                $0.aStarPath(from: $1, to: $2)
            }
        }

        /// Finds a shortest path using bidirectional Dijkstra on the contracted
        /// graph.
        public func bidirectionalShortestPath(
            from source: Node,
            to destination: Node
        ) -> [Node] {
            route(from: source, to: destination) {
                $0.bidirectionalShortestPath(from: $1, to: $2)
            }
        }

        /// Dijkstra search with constraints. Falls back to the original graph.
        public func shortestPath(
            from source: Node,
            to destination: Node,
            blockedNodes: Set<Node>?,
            edgeFilter: ((Edge) -> Bool)? = nil
        ) -> [Node] {
            guard blockedNodes == nil, edgeFilter == nil else {
                return original.shortestPath(
                    from: source,
                    to: destination,
                    blockedNodes: blockedNodes,
                    edgeFilter: edgeFilter)
            }

            return shortestPath(from: source, to: destination)
        }

        /// A* search with constraints. Falls back to the original graph.
        public func aStarPath(
            from source: Node,
            to destination: Node,
            blockedNodes: Set<Node>?,
            edgeFilter: ((Edge) -> Bool)? = nil
        ) -> [Node] {
            guard blockedNodes == nil, edgeFilter == nil else {
                return original.aStarPath(
                    from: source,
                    to: destination,
                    blockedNodes: blockedNodes,
                    edgeFilter: edgeFilter)
            }

            return aStarPath(from: source, to: destination)
        }

        /// Bidirectional search with constraints. Falls back to the original
        /// graph.
        public func bidirectionalShortestPath(
            from source: Node,
            to destination: Node,
            blockedNodes: Set<Node>?,
            edgeFilter: ((Edge) -> Bool)? = nil
        ) -> [Node] {
            guard blockedNodes == nil, edgeFilter == nil else {
                return original.bidirectionalShortestPath(
                    from: source,
                    to: destination,
                    blockedNodes: blockedNodes,
                    edgeFilter: edgeFilter)
            }

            return bidirectionalShortestPath(from: source, to: destination)
        }

        // MARK: - Private

        private func route(
            from source: Node,
            to destination: Node,
            search: (Graph, Node, Node) -> [Node]
        ) -> [Node] {
            guard source.index >= 0,
                  source.index < original.nodeCount,
                  destination.index >= 0,
                  destination.index < original.nodeCount
            else { return [] }
            guard source == destination else {
                guard let sourceIndex = contraction.contractedIndexOfOriginal[source.index],
                      let destinationIndex = contraction.contractedIndexOfOriginal[
                          destination.index
                      ],
                      let contractedSource = contraction.graph.node(withIndex: sourceIndex),
                      let contractedDestination = contraction.graph.node(
                          withIndex: destinationIndex)
                else {
                    return search(original, source, destination)
                }

                let contractedPath = search(
                    contraction.graph,
                    contractedSource,
                    contractedDestination)

                guard contractedPath.isNotEmpty,
                      let expanded = original.expandPath(
                          contractedPath,
                          using: contraction)
                else {
                    return search(original, source, destination)
                }

                return expanded
            }

            return [source]
        }

    }

    /// Returns a reusable routing index for this graph.
    public func routingIndex() -> RoutingIndex? {
        RoutingIndex(self)
    }

}
