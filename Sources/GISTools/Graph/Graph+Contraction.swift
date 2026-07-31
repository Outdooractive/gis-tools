#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Chain contraction

extension Graph {

    /// The result of ``contracted()``: the simplified graph plus a mapping
    /// back to original-node indices for path expansion.
    public struct ContractionResult: Sendable {

        /// The contracted graph with degree-2 chain nodes removed and their
        /// incident edges merged into single edges with summed weights.
        public let graph: Graph

        /// For each node index in the contracted graph, the original node
        /// index it represents. When a chain is collapsed, both endpoints of
        /// the merged edge keep their original identity; intermediate nodes
        /// are dropped.
        ///
        /// Use ``expandPath(_:)`` to lift a contracted-graph path back to the
        /// original graph.
        public let originalIndices: [Int]

        /// Maps an original node index to its representative in the
        /// contracted graph, or `nil` if the node was an intermediate that got
        /// removed.
        public let contractedIndexOfOriginal: [Int?]

    }

    /// Removes degree-2 chain nodes by merging their two incident edges into
    /// a single edge whose weight is the sum of the merged edges' weights.
    ///
    /// Many nodes in a road network are just intermediate points on a straight
    /// road (every vertex of a polyline becomes a node during construction).
    /// Contracting these chains preserves the network's topology and total
    /// route lengths while substantially reducing the node count, which speeds
    /// up all subsequent routing algorithms (Dijkstra, A*, bidirectional,
    /// Yen's) by shrinking the search space.
    ///
    /// - In an undirected graph, a node is contracted when it has exactly two
    ///   incident edges leading to two distinct neighbors (no self-loops).
    /// - In a directed graph, only two-way (undirected-stored) pass-through
    ///   nodes are contracted; one-way edges are left untouched to preserve
    ///   directionality.
    /// - Edges carrying a `feature` keep it only if both merged edges share the
    ///   same feature; otherwise the merged edge has `feature == nil`.
    /// - Node indices in the returned graph are reassigned compactly (the
    ///   ``ContractionResult/originalIndices`` and
    ///   ``ContractionResult/contractedIndexOfOriginal`` arrays provide the
    ///   round-trip mapping).
    ///
    /// - Returns: The contracted graph and the original/contracted index
    ///   mappings, or `nil` if the graph is empty.
    public func contracted() -> ContractionResult? {
        contracted(edgeCompatibility: nil)
    }

    /// Removes degree-2 chain nodes by merging their edges, preserving
    /// boundaries where adjacent edges differ.
    ///
    /// This overload accepts an `edgeCompatibility` predicate: a degree-2 node
    /// is only contracted when its two incident edges are *compatible*
    /// according to the closure. Use this to preserve transitions between road
    /// classes (e.g. "service road" → "trail"), surface types, or any other
    /// feature property — the boundary node is kept so the two edge types stay
    /// distinct in the contracted graph.
    ///
    /// For example, to contract only within a single road class:
    /// ```swift
    /// let result = graph.contracted { edge1, edge2 in
    ///     edge1.feature?.property(for: "type") == edge2.feature?.property(for: "type")
    /// }
    /// ```
    ///
    /// When `edgeCompatibility` is `nil`, all degree-2 pass-through nodes are
    /// contracted regardless of edge properties (the behavior of
    /// ``contracted()``).
    ///
    /// - Parameter edgeCompatibility: An optional closure that decides whether
    ///   two adjacent edges at a degree-2 node may be merged. Return `true` to
    ///   allow contraction at that node, `false` to keep it as a boundary.
    /// - Returns: The contracted graph and the original/contracted index
    ///   mappings, or `nil` if the graph is empty.
    public func contracted(
        edgeCompatibility: ((Edge, Edge) -> Bool)?
    ) -> ContractionResult? {
        guard adjacencyList.isNotEmpty else { return nil }

        // Phase 1: decide which original nodes survive (are kept) and which
        // are removed as intermediate chain nodes.
        //
        // A node is a *candidate* when it is a pure two-way degree-2
        // pass-through whose two neighbors are distinct and not already
        // directly connected, AND (when `edgeCompatibility` is provided) whose
        // two incident edges are compatible. Candidates form maximal paths
        // (and possibly cycles) linked through "anchor" nodes (non-candidates
        // such as junctions, leaves, nodes adjacent to a direct shortcut, or
        // property boundaries).
        //
        // Removal rule:
        // - An *open* candidate path (both ends touch anchors) is collapsed to
        //   its two anchor-adjacent endpoints; the interior nodes are removed.
        // - A *closed* candidate cycle (no anchor, e.g. a pure square) is left
        //   untouched — collapsing it would orphan the chain walk and destroy a
        //   cycle, with no routing benefit.
        var keep = Array(repeating: true, count: adjacencyList.count)
        var candidates = Set<Int>()
        for i in 0..<adjacencyList.count where isContractionCandidate(
            index: i,
            edgeCompatibility: edgeCompatibility)
        {
            candidates.insert(i)
        }

        var visitedCandidates: Set<Int> = []
        var removable: Set<Int> = []
        for start in candidates where !visitedCandidates.contains(start) {
            let chain = walkCandidateChain(
                from: start,
                candidates: candidates,
                visited: &visitedCandidates)
            let path = chain.nodes

            // Open path: the candidates are flanked by two *anchors*
            // (non-candidate neighbors). Remove all candidates in the path,
            // collapsing it to a single merged edge between the anchors — but
            // only if the two anchors are *distinct*. If both ends anchor onto
            // the same node, removing the path would collapse a cycle (e.g. a
            // square pinned at one corner), destroying connectivity; in that
            // case keep everything.
            // Closed cycle: keep everything.
            if chain.hitAnchor {
                // The path's first and last candidates each have one or two
                // non-candidate (anchor) neighbors. Find the anchor at each end;
                // they must be distinct to avoid collapsing a cycle.
                let headAnchor = path.first.flatMap { firstCandidate in
                    chainNeighbors(of: firstCandidate).first {
                        !candidates.contains($0)
                    }
                }
                let tailAnchor = path.last.flatMap { lastCandidate in
                    let neighbors = chainNeighbors(of: lastCandidate)
                    // Prefer the non-candidate neighbor that is NOT the head
                    // anchor (so a single-node path a-b-c picks a and c, not
                    // twice a).
                    if let head = headAnchor,
                        let other = neighbors.first(where: {
                            $0 != head && !candidates.contains($0)
                        })
                    {
                        return other
                    }
                    return neighbors.first { !candidates.contains($0) }
                }
                if let head = headAnchor,
                   let tail = tailAnchor,
                   head != tail
                {
                    removable.formUnion(path)
                }
            }
        }
        for i in removable {
            keep[i] = false
        }

        // Phase 2: build the contracted graph by relabeling kept nodes
        // compactly and, for each kept node, emitting merged edges to other
        // kept nodes (following chains through removed nodes).
        var newIndexForOld: [Int?] = Array(repeating: nil, count: adjacencyList.count)
        var originalIndexForNew: [Int] = []
        var edgeLists: [Graph.EdgeList] = []
        for i in 0..<adjacencyList.count where keep[i] {
            newIndexForOld[i] = edgeLists.count
            originalIndexForNew.append(i)
            let node = adjacencyList[i].node
            edgeLists.append(
                EdgeList(
                    node: Node(
                        index: edgeLists.count,
                        coordinate: node.coordinate)))
        }

        // Phase 3: walk every edge out of each kept node, following chains of
        // removed nodes until reaching another kept node. Emit a merged edge
        // with summed weight. Each undirected pair is emitted in both
        // directions; directed one-way chains in only the permitted direction.
        // To avoid emitting the same merged undirected edge twice from both
        // ends, the forward walk from each kept node handles emission, and we
        // skip an edge if it leads back to a kept node with a smaller index
        // (the smaller-index side will emit it).
        var emittedUndirected: Set<UndirectedEdgeKey> = []
        for i in 0..<adjacencyList.count where keep[i] {
            let newFromIndex = newIndexForOld[i]!
            for edge in adjacencyList[i].edges {
                let firstStepIsDirected = edge.isDirected
                let (destOriginal, totalWeight, mergedFeature) = walkChain(
                    from: i,
                    firstEdge: edge,
                    keep: keep)
                guard let dest = destOriginal, dest != i else { continue }
                guard let newToIndex = newIndexForOld[dest] else { continue }

                if firstStepIsDirected {
                    // One-way chain: emit only in the forward direction.
                    let fromNode = edgeLists[newFromIndex].node
                    let toNode = edgeLists[newToIndex].node
                    edgeLists[newFromIndex].edges.append(
                        Edge(
                            from: fromNode,
                            to: toNode,
                            feature: mergedFeature,
                            isDirected: true,
                            weight: totalWeight))
                }
                else {
                    // Undirected chain: emit both directions once.
                    let key = UndirectedEdgeKey(
                        a: min(newFromIndex, newToIndex),
                        b: max(newFromIndex, newToIndex))
                    guard emittedUndirected.insert(key).inserted else {
                        continue
                    }
                    let fromNode = edgeLists[newFromIndex].node
                    let toNode = edgeLists[newToIndex].node
                    edgeLists[newFromIndex].edges.append(
                        Edge(
                            from: fromNode,
                            to: toNode,
                            feature: mergedFeature,
                            isDirected: false,
                            weight: totalWeight))
                    edgeLists[newToIndex].edges.append(
                        Edge(
                            from: toNode,
                            to: fromNode,
                            feature: mergedFeature,
                            isDirected: false,
                            weight: totalWeight))
                }
            }
        }

        var contracted = Graph(
            nodeTolerance: nodeTolerance,
            isDirected: isDirected,
            onewayProperty: onewayProperty)
        contracted.adjacencyList = edgeLists
        contracted.spatialIndex = SpatialIndex(
            tolerance: nodeTolerance,
            referenceLatitude: edgeLists.first?.node.coordinate.latitude ?? 0.0)
        for newIndex in originalIndexForNew.indices {
            contracted.spatialIndex.insert(
                nodeIndex: newIndex,
                coordinate: edgeLists[newIndex].node.coordinate)
        }

        return ContractionResult(
            graph: contracted,
            originalIndices: originalIndexForNew,
            contractedIndexOfOriginal: newIndexForOld)
    }

    /// Lifts a path of nodes from a contracted graph back to the original
    /// graph by expanding each contracted edge into its intermediate chain.
    ///
    /// For each consecutive pair in `contractedPath`, the intermediate removed
    /// nodes are reconstructed by walking the original chain. The result is a
    /// full node path in the original graph's coordinate space.
    ///
    /// - Parameters:
    ///   - contractedPath: A path in the contracted graph (as returned by a
    ///     routing algorithm on the graph from ``contracted()``).
    /// - Returns: The expanded path as original-graph nodes, or `nil` if the
    ///   path cannot be expanded.
    public func expandPath(
        _ contractedPath: [Node],
        using result: ContractionResult
    ) -> [Node]? {
        guard contractedPath.isNotEmpty else { return [] }

        var expanded: [Node] = []
        for (position, contractedNode) in contractedPath.enumerated() {
            guard contractedNode.index < result.originalIndices.count else {
                return nil
            }
            let originalIndex = result.originalIndices[contractedNode.index]
            expanded.append(adjacencyList[originalIndex].node)

            if position < contractedPath.count - 1 {
                let nextContracted = contractedPath[position + 1]
                guard
                    let intermediates = intermediateNodes(
                        fromOriginal: originalIndex,
                        toContractedIndex: nextContracted.index,
                        result: result)
                else { return nil }
                expanded.append(contentsOf: intermediates)
            }
        }
        return expanded
    }

    // MARK: - Contraction-accelerated routing

    /// Finds the shortest path between two nodes, using chain contraction to
    /// shrink the search space before routing and then expanding the result
    /// back to the original graph.
    ///
    /// This is a convenience wrapper that runs ``contracted()`` once, maps the
    /// endpoints to the contracted graph, runs
    /// ``shortestPath(from:to:blockedNodes:edgeFilter:)`` on the (much smaller)
    /// contracted graph, and lifts the result with ``expandPath(_:using:)``.
    /// Because contraction removes only degree-2 pass-through nodes and
    /// preserves total route length, the returned path has the same cost as a
    /// direct search on the full graph while typically exploring far fewer
    /// nodes — a meaningful speedup on dense road networks where most nodes
    /// are intermediate polyline vertices.
    ///
    /// - Parameters:
    ///   - source: The start node.
    ///   - destination: The target node.
    ///   - blockedNodes: An optional set of nodes to avoid.
    ///   - edgeFilter: An optional predicate that must accept an edge for it
    ///     to be traversable. When non-`nil`, this method falls back to a
    ///     direct (uncontracted) search, because contraction merges edges and
    ///     cannot preserve per-segment feature properties that filters inspect.
    /// - Returns: The shortest path as an ordered array of original-graph
    ///   nodes (including `source` and `destination`), or an empty array if no
    ///   path exists or the endpoints were removed by contraction.
    public func shortestPathViaContraction(
        from source: Node,
        to destination: Node,
        blockedNodes: Set<Node>? = nil,
        edgeFilter: ((Edge) -> Bool)? = nil
    ) -> [Node] {
        contractedRoute(
            from: source,
            to: destination,
            blockedNodes: blockedNodes,
            edgeFilter: edgeFilter,
            search: { graph, s, d, blocked, filter in
                graph.shortestPath(
                    from: s,
                    to: d,
                    blockedNodes: blocked,
                    edgeFilter: filter)
            })
    }

    /// Finds the shortest path between two nodes using A* on a
    /// contraction-simplified graph, then expands the result.
    ///
    /// Combines the heuristic pruning of
    /// ``aStarPath(from:to:blockedNodes:edgeFilter:)`` with the smaller search
    /// space from ``contracted()`` for maximum point-to-point routing speed.
    /// The returned path has the same cost as a direct A* search on the full
    /// graph.
    ///
    /// - Parameters:
    ///   - source: The start node.
    ///   - destination: The target node.
    ///   - blockedNodes: An optional set of nodes to avoid.
    ///   - edgeFilter: An optional predicate that must accept an edge for it
    ///     to be traversable. When non-`nil`, this method falls back to a
    ///     direct (uncontracted) A* search, because contraction merges edges
    ///     and cannot preserve per-segment feature properties.
    /// - Returns: The shortest path as an ordered array of original-graph
    ///   nodes, or an empty array if no path exists or the endpoints were
    ///   removed by contraction.
    public func aStarPathViaContraction(
        from source: Node,
        to destination: Node,
        blockedNodes: Set<Node>? = nil,
        edgeFilter: ((Edge) -> Bool)? = nil
    ) -> [Node] {
        contractedRoute(
            from: source,
            to: destination,
            blockedNodes: blockedNodes,
            edgeFilter: edgeFilter,
            search: { graph, s, d, blocked, filter in
                graph.aStarPath(
                    from: s,
                    to: d,
                    blockedNodes: blocked,
                    edgeFilter: filter)
            })
    }

    /// Finds the shortest path between two nodes using bidirectional Dijkstra
    /// on a contraction-simplified graph, then expands the result.
    ///
    /// Combines the meet-in-the-middle speedup of
    /// ``bidirectionalShortestPath(from:to:blockedNodes:edgeFilter:)`` with
    /// the smaller search space from ``contracted()``. The returned path has
    /// the same cost as a direct search on the full graph.
    ///
    /// - Parameters:
    ///   - source: The start node.
    ///   - destination: The target node.
    ///   - blockedNodes: An optional set of nodes to avoid.
    ///   - edgeFilter: An optional predicate that must accept an edge for it
    ///     to be traversable. When non-`nil`, this method falls back to a
    ///     direct (uncontracted) bidirectional search, because contraction
    ///     merges edges and cannot preserve per-segment feature properties.
    /// - Returns: The shortest path as an ordered array of original-graph
    ///   nodes, or an empty array if no path exists or the endpoints were
    ///   removed by contraction.
    public func bidirectionalShortestPathViaContraction(
        from source: Node,
        to destination: Node,
        blockedNodes: Set<Node>? = nil,
        edgeFilter: ((Edge) -> Bool)? = nil
    ) -> [Node] {
        contractedRoute(
            from: source,
            to: destination,
            blockedNodes: blockedNodes,
            edgeFilter: edgeFilter,
            search: { graph, s, d, blocked, filter in
                graph.bidirectionalShortestPath(
                    from: s,
                    to: d,
                    blockedNodes: blocked,
                    edgeFilter: filter)
            })
    }

    /// Shared core for the contraction-accelerated routing wrappers: contract,
    /// map endpoints, run `search`, and expand the result.
    private func contractedRoute(
        from source: Node,
        to destination: Node,
        blockedNodes: Set<Node>?,
        edgeFilter: ((Edge) -> Bool)?,
        search: (Graph, Node, Node, Set<Node>?, ((Edge) -> Bool)?) -> [Node]
    ) -> [Node] {
        guard source.index >= 0,
              source.index < adjacencyList.count,
              destination.index >= 0,
              destination.index < adjacencyList.count
        else { return [] }

        if source == destination { return [source] }

        // Contraction merges edges and discards per-segment feature properties
        // (a merged edge keeps a feature only when both halves share it). An
        // `edgeFilter` typically inspects `edge.feature`, so routing on the
        // contracted graph would silently break the filter. Fall back to a
        // direct search on the full graph whenever a filter is supplied.
        if edgeFilter != nil {
            return search(self, source, destination, blockedNodes, edgeFilter)
        }

        guard let result = contracted() else { return [] }

        guard let contractedSourceIndex = result.contractedIndexOfOriginal[source.index],
              let contractedDestinationIndex = result.contractedIndexOfOriginal[destination.index]
        else {
            // An endpoint was an intermediate chain node. Fall back to a direct
            // search on the full graph.
            return search(self, source, destination, blockedNodes, edgeFilter)
        }

        // Blocked nodes that were removed by contraction cannot be mapped;
        // fall back to the full search in that case.
        var contractedBlocked: Set<Node> = []
        if let blockedNodes {
            for blocked in blockedNodes {
                guard let mapped = result.contractedIndexOfOriginal[blocked.index] else {
                    return search(self, source, destination, blockedNodes, edgeFilter)
                }
                contractedBlocked.insert(result.graph.node(withIndex: mapped)!)
            }
        }

        let contractedSource = result.graph.node(withIndex: contractedSourceIndex)!
        let contractedDestination = result.graph.node(withIndex: contractedDestinationIndex)!
        let contractedPath = search(
            result.graph,
            contractedSource,
            contractedDestination,
            contractedBlocked.isNotEmpty ? contractedBlocked : nil,
            edgeFilter)

        guard contractedPath.isNotEmpty else { return [] }
        return expandPath(contractedPath, using: result) ?? []
    }

    // MARK: - Chain contraction internals

    /// A node is a *candidate* for contraction when every incident edge is
    /// undirected (two-way) and there are exactly two of them, leading to two
    /// distinct other nodes (no self-loop) that are **not already directly
    /// connected**.
    ///
    /// The "neighbors not adjacent" rule prevents two problems:
    /// - Creating parallel edges when contracting would duplicate an existing
    ///   direct edge.
    /// - Collapsing triangles: in a triangle every node has degree 2 and each
    ///   pair of neighbors is adjacent, so no node is a candidate.
    ///
    /// Being a candidate is necessary but not sufficient: the fixpoint in
    /// ``contracted()`` additionally requires that at least one neighbor is an
    /// anchor (kept), so every maximal chain retains its endpoints.
    ///
    /// One-way edges (in directed graphs) are never contracted: they are
    /// typically short and contracting them would complicate reverse traversal
    /// without meaningful speedup. Only pure two-way pass-through nodes are
    /// removed.
    private func isContractionCandidate(
        index: Int,
        edgeCompatibility: ((Edge, Edge) -> Bool)?
    ) -> Bool {
        let edges = adjacencyList[index].edges
        // All incident edges must be undirected (two-way).
        guard edges.count == 2,
              edges.allSatisfy({ !$0.isDirected })
        else { return false }

        let n0 = edges[0].to.index
        let n1 = edges[1].to.index
        guard n0 != index,
              n1 != index,
              n0 != n1
        else { return false }

        // The two neighbors must not already be directly connected, otherwise
        // contracting this node would create a parallel edge or collapse a
        // triangle.
        guard !areAdjacent(n0, n1) else { return false }

        // When a compatibility predicate is provided, the two incident edges
        // must be compatible for the node to be contractible. This preserves
        // boundaries where edge properties change (e.g. road class, surface).
        if let edgeCompatibility, !edgeCompatibility(edges[0], edges[1]) {
            return false
        }

        return true
    }

    /// The two neighbor indices of a contraction-candidate node, in edge order.
    private func chainNeighbors(of index: Int) -> [Int] {
        let edges = adjacencyList[index].edges
        guard edges.count == 2 else { return [] }
        return [edges[0].to.index, edges[1].to.index]
    }

    /// Builds the maximal candidate path (or cycle) containing `start`, marking
    /// visited candidates, returning the ordered node indices and whether the
    /// result is an open path (`hitAnchor == true`, both ends touch anchors) or
    /// a closed cycle (`hitAnchor == false`).
    ///
    /// Both directions are walked from `start` so that the returned array is
    /// ordered end-to-end (for an open path) or around the cycle (for a cycle).
    private func walkCandidateChain(
        from start: Int,
        candidates: Set<Int>,
        visited: inout Set<Int>
    ) -> (nodes: [Int], hitAnchor: Bool) {
        visited.insert(start)
        let startNeighbors = chainNeighbors(of: start)

        // Walk in one direction. Returns the path and whether it closed a
        // cycle back to `start` (without hitting an anchor).
        func walkDirection(
            _ firstStep: Int
        ) -> (path: [Int], closedCycle: Bool) {
            var path: [Int] = []
            var previous = start
            var current = firstStep
            while candidates.contains(current),
                  !visited.contains(current)
            {
                visited.insert(current)
                path.append(current)
                let neighbors = chainNeighbors(of: current)
                let next = neighbors.first { $0 != previous } ?? neighbors[0]
                if next == start {
                    // Cycle closed back at `start`.
                    return (path, true)
                }
                previous = current
                current = next
                if current == previous { break }  // safety
            }
            return (path, false)
        }

        // If `start` has no candidate neighbors, it's an isolated candidate;
        // treat as a (degenerate) anchored path.
        let candidateNeighbors = startNeighbors.filter {
            candidates.contains($0)
        }
        guard candidateNeighbors.isNotEmpty else {
            return ([start], true)
        }

        let directionA = walkDirection(candidateNeighbors[0])
        if directionA.closedCycle {
            return ([start] + directionA.path, false)
        }

        // Open path: walk the other direction too and combine.
        var path = [start] + directionA.path
        if candidateNeighbors.count > 1 {
            let directionB = walkDirection(candidateNeighbors[1])
            path = directionB.path.reversed() + path
        }
        return (path, true)
    }

    /// Whether an undirected edge exists directly between `a` and `b`.
    private func areAdjacent(_ a: Int, _ b: Int) -> Bool {
        adjacencyList[a].edges.contains { $0.to.index == b && !$0.isDirected }
    }

    /// Follows the chain of removed nodes starting from kept node `from` along
    /// `firstEdge`, accumulating weight and merging features, until reaching a
    /// kept node. Returns the destination original index, summed weight, and
    /// merged feature.
    private func walkChain(
        from: Int,
        firstEdge: Edge,
        keep: [Bool]
    ) -> (destination: Int?, weight: Double, feature: Feature?) {
        // One-way edges are never part of a contracted chain; emit as-is.
        guard !firstEdge.isDirected else {
            return (firstEdge.to.index, firstEdge.weight, firstEdge.feature)
        }

        var totalWeight = firstEdge.weight
        var mergedFeature = firstEdge.feature
        var previous = from
        var current = firstEdge.to.index

        // Follow the chain through removed undirected nodes, always taking the
        // edge that does not backtrack to `previous`.
        while !keep[current] {
            var nextEdge: Edge?
            for edge in adjacencyList[current].edges
            where edge.to.index != previous {
                // Only follow undirected edges; a directed edge in the middle
                // would break the chain's symmetry, so stop.
                if edge.isDirected {
                    nextEdge = nil
                    break
                }
                nextEdge = edge
                break
            }

            guard let edge = nextEdge else {
                // Dead end or directed interruption; stop here.
                return (current, totalWeight, mergedFeature)
            }

            mergedFeature =
                (mergedFeature != nil && edge.feature != nil
                    && mergedFeature == edge.feature)
                ? mergedFeature
                : nil
            totalWeight += edge.weight
            previous = current
            current = edge.to.index

            // Safety against infinite loops in malformed graphs.
            if current == from { return (from, totalWeight, mergedFeature) }
        }

        return (current, totalWeight, mergedFeature)
    }

    /// Reconstructs the intermediate removed nodes along the chain between
    /// `fromOriginal` (a kept original node) and the contracted node at
    /// `toContractedIndex`. Excludes both endpoints.
    private func intermediateNodes(
        fromOriginal: Int,
        toContractedIndex: Int,
        result: ContractionResult
    ) -> [Node]? {
        guard
            let toOriginal =
                result.originalIndices.indices.contains(toContractedIndex)
                ? result.originalIndices[toContractedIndex]
                : nil
        else { return nil }

        // Walk the original adjacency from `fromOriginal` toward `toOriginal`,
        // collecting removed intermediate nodes. Try each outgoing edge; the
        // one whose chain ends at `toOriginal` is the path to expand.
        for edge in adjacencyList[fromOriginal].edges {
            let (dest, _, _) = walkChain(
                from: fromOriginal,
                firstEdge: edge,
                keep: result.contractedIndexOfOriginal.map { $0 != nil })
            if dest == toOriginal {
                return collectIntermediates(
                    from: fromOriginal,
                    to: toOriginal,
                    contractedIndexOfOriginal: result.contractedIndexOfOriginal)
            }
        }
        return nil
    }

    /// Walks the chain from `from` to `to` and returns the intermediate
    /// (removed) original nodes, excluding both endpoints.
    private func collectIntermediates(
        from: Int,
        to: Int,
        contractedIndexOfOriginal: [Int?]
    ) -> [Node] {
        var intermediates: [Node] = []
        var previous = from
        var current = -1

        // Find the first edge from `from` that begins the chain to `to`.
        let startEdge = adjacencyList[from].edges.first { edge in
            let (dest, _, _) = walkChain(
                from: from,
                firstEdge: edge,
                keep: contractedIndexOfOriginal.map { $0 != nil })
            return dest == to
        }
        guard let edge = startEdge else { return intermediates }
        current = edge.to.index

        while current != to {
            if contractedIndexOfOriginal[current] == nil {
                intermediates.append(adjacencyList[current].node)
            }
            var nextEdge: Edge?
            for e in adjacencyList[current].edges where e.to.index != previous {
                if e.isDirected { break }
                nextEdge = e
                break
            }
            guard let e = nextEdge else { break }
            previous = current
            current = e.to.index
            if current == from { break }
        }
        return intermediates
    }

    // MARK: - Contraction support types

    struct UndirectedEdgeKey: Hashable {

        let a: Int
        let b: Int

    }

}
