#if EnableGraphAPI
#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Multi-level Dijkstra (hierarchical overlay routing)

extension Graph {

    /// A reusable multi-level Dijkstra (MLD) routing index.
    ///
    /// The index partitions the graph into a hierarchy of rectangular cells,
    /// precomputes a sparse overlay graph for every level and answers queries
    /// with a level-aware bidirectional search. The search uses original edges
    /// in the endpoint cells and the overlay of the highest level at which each
    /// visited node is separated from both endpoints.
    ///
    /// Level `0` is a `baseRows × baseColumns` grid over the graph's bounding
    /// box. Every higher level merges `2 × 2` blocks of the previous level, so
    /// the partitions are nested by construction. The requested level count is
    /// clamped to the levels below the single `1 × 1` top cell.
    ///
    /// The overlay for a level contains all boundary nodes (nodes incident to
    /// an edge that crosses a cell boundary) and:
    /// - one shortcut per boundary node and cell for each boundary node that
    ///   is reachable inside the cell without passing through another boundary
    ///   node, and
    /// - the original cross-cell edges.
    ///
    /// This keeps the overlay sparse while preserving exact distances.
    ///
    /// - Important: The index is a snapshot of the graph. Rebuild it after
    ///   changing nodes, edges, or edge weights.
    /// - Note: Queries with `blockedNodes` or an `edgeFilter` cannot use the
    ///   overlays and fall back to ``Graph/shortestPath(from:to:blockedNodes:edgeFilter:)``.
    public struct MultiLevelIndex: Sendable {

        // MARK: - Stored state

        private let graph: Graph
        private let baseCellRow: [Int]
        private let baseCellColumn: [Int]
        private let levels: [Level]
        private let nodeLevel: [Int]
        private let reverseAdjacency: [[ReverseLink]]?

        // MARK: - Initialization

        /// Builds a multi-level routing index.
        ///
        /// - Parameters:
        ///   - graph: The graph to index.
        ///   - levels: The maximum number of hierarchy levels (default 3).
        ///     Level 0 is always built; higher levels are added while the
        ///     merged cell grid still has more than one cell.
        ///   - baseRows: Number of rows in the level-0 grid (default 8).
        ///   - baseColumns: Number of columns in the level-0 grid (default 8).
        /// - Returns: `nil` for an empty graph or an invalid configuration.
        public init?(
            _ graph: Graph,
            levels: Int = 3,
            baseRows: Int = 8,
            baseColumns: Int = 8,
        ) {
            guard graph.nodeCount > 0,
                  levels >= 1,
                  baseRows >= 1,
                  baseColumns >= 1,
                  let tiling = RectangularTiling(
                      nodes: graph.nodes,
                      rows: baseRows,
                      columns: baseColumns)
            else { return nil }

            let nodeCount = graph.nodeCount

            var baseCellRow = [Int](repeating: 0, count: nodeCount)
            var baseCellColumn = [Int](repeating: 0, count: nodeCount)
            for (index, node) in graph.nodes.enumerated() {
                let cell = tiling.tile(for: node.coordinate)
                baseCellRow[index] = cell.row
                baseCellColumn[index] = cell.column
            }

            var availableLevels = 1
            while Self.rows(atLevel: availableLevels, baseRows: baseRows) > 1
                || Self.columns(atLevel: availableLevels, baseColumns: baseColumns) > 1
            {
                availableLevels += 1
            }
            let levelCount = min(levels, availableLevels)

            var builtLevels: [Level] = []
            builtLevels.reserveCapacity(levelCount)
            for levelIndex in 0 ..< levelCount {
                builtLevels.append(
                    Self.buildLevel(
                        index: levelIndex,
                        graph: graph,
                        baseCellRow: baseCellRow,
                        baseCellColumn: baseCellColumn,
                        baseRows: baseRows,
                        baseColumns: baseColumns))
            }

            var nodeLevel = [Int](repeating: 0, count: nodeCount)
            for level in builtLevels {
                for (node, ordinal) in level.boundaryOrdinal.enumerated()
                    where ordinal >= 0
                {
                    nodeLevel[node] = max(nodeLevel[node], level.index)
                }
            }

            let reverseAdjacency: [[ReverseLink]]?
            if graph.hasDirectedEdges {
                var reverse = Array(
                    repeating: [ReverseLink](),
                    count: nodeCount)
                for edgeList in graph.adjacencyList {
                    for edge in edgeList.edges {
                        reverse[edge.to.index].append(
                            ReverseLink(
                                from: edge.from.index,
                                weight: edge.weight,
                                edge: edge))
                    }
                }
                reverseAdjacency = reverse
            }
            else {
                reverseAdjacency = nil
            }

            self.graph = graph
            self.baseCellRow = baseCellRow
            self.baseCellColumn = baseCellColumn
            self.levels = builtLevels
            self.nodeLevel = nodeLevel
            self.reverseAdjacency = reverseAdjacency
        }

        // MARK: - Public properties

        /// The number of hierarchy levels in the index.
        public var levelCount: Int {
            levels.count
        }

        /// The number of nodes in the original graph.
        public var originalNodeCount: Int {
            graph.nodeCount
        }

        // MARK: - Public query methods

        /// Finds a shortest path using the multi-level index.
        ///
        /// - Parameters:
        ///   - source: The start node.
        ///   - destination: The target node.
        /// - Returns: The shortest path as an ordered array of nodes (including
        ///   `source` and `destination`), or an empty array if no path exists.
        public func shortestPath(
            from source: Node,
            to destination: Node,
        ) -> [Node] {
            guard source.index >= 0,
                  source.index < graph.nodeCount,
                  destination.index >= 0,
                  destination.index < graph.nodeCount
            else { return [] }

            if source == destination {
                return [source]
            }

            guard let indices = pathIndices(
                from: source.index,
                to: destination.index)
            else { return [] }

            return indices.map { graph.adjacencyList[$0].node }
        }

        /// Finds a shortest path using the multi-level index.
        ///
        /// Because blocked nodes and edge filters change the graph topology,
        /// those queries are answered by the original graph instead of the
        /// precomputed overlays.
        ///
        /// - Parameters:
        ///   - source: The start node.
        ///   - destination: The target node.
        ///   - blockedNodes: An optional set of nodes to avoid.
        ///   - edgeFilter: An optional predicate that must accept an edge for
        ///     it to be traversable.
        /// - Returns: The shortest path as an ordered array of nodes (including
        ///   `source` and `destination`), or an empty array if no path exists.
        public func shortestPath(
            from source: Node,
            to destination: Node,
            blockedNodes: Set<Node>?,
            edgeFilter: ((Edge) -> Bool)? = nil,
        ) -> [Node] {
            guard blockedNodes == nil,
                  edgeFilter == nil
            else {
                return graph.shortestPath(
                    from: source,
                    to: destination,
                    blockedNodes: blockedNodes,
                    edgeFilter: edgeFilter)
            }

            return shortestPath(from: source, to: destination)
        }

        // MARK: - Query internals

        private func pathIndices(
            from source: Int,
            to destination: Int,
        ) -> [Int]? {
            guard levels.isNotEmpty else { return nil }

            let nodeCount = graph.nodeCount
            var forwardDist = [Double](repeating: .infinity, count: nodeCount)
            var forwardPred = [Int](repeating: -1, count: nodeCount)
            var forwardStepLevel = [Int](repeating: -1, count: nodeCount)
            var forwardStepCell = [Int](repeating: -1, count: nodeCount)
            var backwardDist = [Double](repeating: .infinity, count: nodeCount)
            var backwardPred = [Int](repeating: -1, count: nodeCount)
            var backwardStepLevel = [Int](repeating: -1, count: nodeCount)
            var backwardStepCell = [Int](repeating: -1, count: nodeCount)
            var forwardSettled = NodeBitSet(count: nodeCount)
            var backwardSettled = NodeBitSet(count: nodeCount)

            let sourceBaseCell = cellID(of: source, level: levels[0])
            let targetBaseCell = cellID(of: destination, level: levels[0])
            let sourceReferenceCells = levels.map {
                cellID(of: source, level: $0)
            }
            let targetReferenceCells = levels.map {
                cellID(of: destination, level: $0)
            }

            func queryLevel(of node: Int) -> Int {
                var divergingFromSource = 0
                var divergingFromTarget = 0
                for levelIndex in 0 ..< levels.count {
                    let cell = cellID(of: node, level: levels[levelIndex])
                    if cell != sourceReferenceCells[levelIndex] {
                        divergingFromSource = levelIndex
                    }
                    if cell != targetReferenceCells[levelIndex] {
                        divergingFromTarget = levelIndex
                    }
                }

                return min(
                    nodeLevel[node],
                    min(divergingFromSource, divergingFromTarget))
            }

            func isInEndpointCell(_ node: Int) -> Bool {
                let cell = cellID(of: node, level: levels[0])
                return cell == sourceBaseCell || cell == targetBaseCell
            }

            var forwardHeap = MinHeap<HeapEntry>()
            var backwardHeap = MinHeap<HeapEntry>()
            forwardDist[source] = 0.0
            backwardDist[destination] = 0.0
            forwardHeap.push(HeapEntry(distance: 0.0, index: source))
            backwardHeap.push(HeapEntry(distance: 0.0, index: destination))

            var best = Double.infinity
            var bestMeeting = -1

            func considerMeeting(_ node: Int) {
                let candidate = forwardDist[node] + backwardDist[node]
                guard candidate < best else { return }

                best = candidate
                bestMeeting = node
            }

            func relaxForward(
                _ neighbor: Int,
                from node: Int,
                weight: Double,
                level: Int,
                cell: Int,
                distance: Double,
            ) {
                let relaxed = distance + weight
                guard relaxed < forwardDist[neighbor] else { return }

                forwardDist[neighbor] = relaxed
                forwardPred[neighbor] = node
                forwardStepLevel[neighbor] = level
                forwardStepCell[neighbor] = cell
                forwardHeap.push(
                    HeapEntry(distance: relaxed, index: neighbor))
                if backwardDist[neighbor].isFinite {
                    considerMeeting(neighbor)
                }
            }

            func relaxBackward(
                _ neighbor: Int,
                from node: Int,
                weight: Double,
                level: Int,
                cell: Int,
                distance: Double,
            ) {
                let relaxed = distance + weight
                guard relaxed < backwardDist[neighbor] else { return }

                backwardDist[neighbor] = relaxed
                backwardPred[neighbor] = node
                backwardStepLevel[neighbor] = level
                backwardStepCell[neighbor] = cell
                backwardHeap.push(
                    HeapEntry(distance: relaxed, index: neighbor))
                if forwardDist[neighbor].isFinite {
                    considerMeeting(neighbor)
                }
            }

            while !forwardHeap.isEmpty || !backwardHeap.isEmpty {
                let topForward = forwardHeap.peek?.distance ?? .infinity
                let topBackward = backwardHeap.peek?.distance ?? .infinity
                if topForward + topBackward >= best {
                    break
                }

                let expandForward: Bool =
                    if forwardHeap.isEmpty {
                        false
                    }
                    else if backwardHeap.isEmpty {
                        true
                    }
                    else {
                        topForward <= topBackward
                    }

                if expandForward, let entry = forwardHeap.pop() {
                    let node = entry.index
                    if entry.distance > forwardDist[node] {
                        continue
                    }
                    if forwardSettled[node] {
                        continue
                    }
                    forwardSettled[node] = true

                    if backwardDist[node].isFinite {
                        considerMeeting(node)
                    }

                    let levelIndex = queryLevel(of: node)
                    let level = levels[levelIndex]

                    if isInEndpointCell(node) {
                        for edge in graph.adjacencyList[node].edges {
                            relaxForward(
                                edge.to.index,
                                from: node,
                                weight: edge.weight,
                                level: -1,
                                cell: -1,
                                distance: entry.distance)
                        }
                    }

                    let ordinal = level.boundaryOrdinal[node]
                    guard ordinal >= 0 else { continue }

                    for edge in level.forward[ordinal] {
                        relaxForward(
                            edge.to,
                            from: node,
                            weight: edge.weight,
                            level: levelIndex,
                            cell: edge.cellID,
                            distance: entry.distance)
                    }
                }
                else if !expandForward, let entry = backwardHeap.pop() {
                    let node = entry.index
                    if entry.distance > backwardDist[node] {
                        continue
                    }
                    if backwardSettled[node] {
                        continue
                    }
                    backwardSettled[node] = true

                    if forwardDist[node].isFinite {
                        considerMeeting(node)
                    }

                    let levelIndex = queryLevel(of: node)
                    let level = levels[levelIndex]

                    if isInEndpointCell(node) {
                        if let reverseAdjacency {
                            for link in reverseAdjacency[node] {
                                relaxBackward(
                                    link.from,
                                    from: node,
                                    weight: link.weight,
                                    level: -1,
                                    cell: -1,
                                    distance: entry.distance)
                            }
                        }
                        else {
                            for edge in graph.adjacencyList[node].edges {
                                relaxBackward(
                                    edge.to.index,
                                    from: node,
                                    weight: edge.weight,
                                    level: -1,
                                    cell: -1,
                                    distance: entry.distance)
                            }
                        }
                    }

                    let ordinal = level.boundaryOrdinal[node]
                    guard ordinal >= 0 else { continue }

                    if let backward = level.backward {
                        for edge in backward[ordinal] {
                            relaxBackward(
                                edge.from,
                                from: node,
                                weight: edge.weight,
                                level: levelIndex,
                                cell: edge.cellID,
                                distance: entry.distance)
                        }
                    }
                    else {
                        for edge in level.forward[ordinal] {
                            relaxBackward(
                                edge.to,
                                from: node,
                                weight: edge.weight,
                                level: levelIndex,
                                cell: edge.cellID,
                                distance: entry.distance)
                        }
                    }
                }
                else {
                    break
                }
            }

            guard bestMeeting >= 0,
                  best.isFinite
            else { return nil }

            var forwardSteps: [(from: Int, to: Int, level: Int, cell: Int)] = []
            var node = bestMeeting
            while forwardPred[node] != -1 {
                let previous = forwardPred[node]
                forwardSteps.append(
                    (
                        from: previous,
                        to: node,
                        level: forwardStepLevel[node],
                        cell: forwardStepCell[node]
                    ))
                node = previous
            }
            guard node == source else { return nil }

            forwardSteps.reverse()

            var backwardSteps: [(from: Int, to: Int, level: Int, cell: Int)] = []
            node = bestMeeting
            while backwardPred[node] != -1 {
                let next = backwardPred[node]
                backwardSteps.append(
                    (
                        from: node,
                        to: next,
                        level: backwardStepLevel[node],
                        cell: backwardStepCell[node]
                    ))
                node = next
            }
            guard node == destination else { return nil }

            let needsExpansion = forwardSteps.contains {
                $0.level >= 0 && $0.cell >= 0
            } || backwardSteps.contains {
                $0.level >= 0 && $0.cell >= 0
            }
            var expansionDist: [Double] = needsExpansion
                ? Array(repeating: .infinity, count: nodeCount)
                : []
            var expansionPred: [Int] = needsExpansion
                ? Array(repeating: -1, count: nodeCount)
                : []
            var expansionTouched: [Int] = []
            expansionTouched.reserveCapacity(min(nodeCount, 1024))

            var result: [Int] = [source]

            for step in forwardSteps {
                guard let expanded = expand(
                    step,
                    dist: &expansionDist,
                    pred: &expansionPred,
                    touched: &expansionTouched)
                else { return nil }

                result.append(contentsOf: expanded)
            }

            for step in backwardSteps {
                guard let expanded = expand(
                    step,
                    dist: &expansionDist,
                    pred: &expansionPred,
                    touched: &expansionTouched)
                else { return nil }

                result.append(contentsOf: expanded)
            }

            var deduplicated: [Int] = []
            deduplicated.reserveCapacity(result.count)
            for node in result where deduplicated.last != node {
                deduplicated.append(node)
            }
            return deduplicated
        }

        private func cellID(of node: Int, level: Level) -> Int {
            ((baseCellRow[node] >> level.index) * level.columns)
                + (baseCellColumn[node] >> level.index)
        }

        private func expand(
            _ step: (from: Int, to: Int, level: Int, cell: Int),
            dist: inout [Double],
            pred: inout [Int],
            touched: inout [Int],
        ) -> [Int]? {
            if step.level < 0 || step.cell < 0 {
                return [step.to]
            }

            guard let path = cellPath(
                from: step.from,
                to: step.to,
                level: levels[step.level],
                cell: step.cell,
                dist: &dist,
                pred: &pred,
                touched: &touched)
            else { return nil }

            return Array(path.dropFirst())
        }

        private func cellPath(
            from source: Int,
            to destination: Int,
            level: Level,
            cell: Int,
            dist: inout [Double],
            pred: inout [Int],
            touched: inout [Int],
        ) -> [Int]? {
            for node in touched {
                dist[node] = .infinity
                pred[node] = -1
            }
            touched.removeAll(keepingCapacity: true)

            if source == destination {
                return [source]
            }

            dist[source] = 0.0
            touched.append(source)

            var heap = MinHeap<HeapEntry>()
            heap.push(HeapEntry(distance: 0.0, index: source))
            var found = false

            while let entry = heap.pop() {
                let node = entry.index
                if entry.distance > dist[node] {
                    continue
                }
                if node == destination {
                    found = true
                    break
                }
                if node != source,
                   level.boundaryOrdinal[node] >= 0
                {
                    // Match the shortcut construction: stop at the first
                    // boundary node instead of expanding through it.
                    continue
                }

                for edge in graph.adjacencyList[node].edges {
                    let neighbor = edge.to.index
                    guard cellID(of: neighbor, level: level) == cell else {
                        continue
                    }

                    let relaxed = entry.distance + edge.weight
                    guard relaxed < dist[neighbor] else { continue }

                    if !dist[neighbor].isFinite {
                        touched.append(neighbor)
                    }
                    dist[neighbor] = relaxed
                    pred[neighbor] = node
                    heap.push(
                        HeapEntry(distance: relaxed, index: neighbor))
                }
            }

            guard found else { return nil }

            var path: [Int] = [destination]
            var node = destination
            while node != source {
                let previous = pred[node]
                guard previous != -1 else { return nil }

                path.append(previous)
                node = previous
            }
            return path.reversed()
        }

        // MARK: - Level construction

        private static func rows(
            atLevel level: Int,
            baseRows: Int,
        ) -> Int {
            ((baseRows - 1) >> level) + 1
        }

        private static func columns(
            atLevel level: Int,
            baseColumns: Int,
        ) -> Int {
            ((baseColumns - 1) >> level) + 1
        }

        private static func buildLevel(
            index levelIndex: Int,
            graph: Graph,
            baseCellRow: [Int],
            baseCellColumn: [Int],
            baseRows: Int,
            baseColumns: Int,
        ) -> Level {
            let rows = rows(atLevel: levelIndex, baseRows: baseRows)
            let columns = columns(
                atLevel: levelIndex,
                baseColumns: baseColumns)
            let cellCount = rows * columns
            let nodeCount = graph.nodeCount

            var cellNodes = Array(repeating: [Int](), count: cellCount)
            var cellOf = [Int](repeating: 0, count: nodeCount)
            for node in 0 ..< nodeCount {
                let cell = ((baseCellRow[node] >> levelIndex) * columns)
                    + (baseCellColumn[node] >> levelIndex)
                cellOf[node] = cell
                cellNodes[cell].append(node)
            }

            var isBoundary = [Bool](repeating: false, count: nodeCount)
            for node in 0 ..< nodeCount {
                for edge in graph.adjacencyList[node].edges {
                    let neighbor = edge.to.index
                    if cellOf[node] != cellOf[neighbor] {
                        isBoundary[node] = true
                        isBoundary[neighbor] = true
                    }
                }
            }

            var cellBoundaryNodes = Array(
                repeating: [Int](),
                count: cellCount)
            for cell in 0 ..< cellCount {
                var boundary: [Int] = []
                for node in cellNodes[cell] where isBoundary[node] {
                    boundary.append(node)
                }
                cellBoundaryNodes[cell] = boundary
            }

            var boundaryOrdinal = [Int](repeating: -1, count: nodeCount)
            var ordinalCount = 0
            for cell in 0 ..< cellCount {
                for node in cellBoundaryNodes[cell] {
                    boundaryOrdinal[node] = ordinalCount
                    ordinalCount += 1
                }
            }

            var forward = Array(
                repeating: [OverlayEdge](),
                count: ordinalCount)

            // Cross-cell edges connect the cells at this level.
            struct NodePair: Hashable {

                let from: Int
                let to: Int

            }

            var cutWeights: [NodePair: Double] = [:]
            for node in 0 ..< nodeCount {
                for edge in graph.adjacencyList[node].edges {
                    let neighbor = edge.to.index
                    if cellOf[node] == cellOf[neighbor] {
                        continue
                    }
                    let pair = NodePair(from: node, to: neighbor)
                    if let existing = cutWeights[pair],
                       existing <= edge.weight
                    {
                        continue
                    }
                    cutWeights[pair] = edge.weight
                }
            }

            let sortedCutPairs = cutWeights.keys.sorted {
                $0.from == $1.from ? $0.to < $1.to : $0.from < $1.from
            }
            for pair in sortedCutPairs {
                guard let weight = cutWeights[pair],
                      boundaryOrdinal[pair.from] >= 0
                else { continue }

                forward[boundaryOrdinal[pair.from]].append(
                    OverlayEdge(
                        from: pair.from,
                        to: pair.to,
                        weight: weight,
                        cellID: -1))
            }

            // Sparse first-boundary shortcuts.
            var distances = [Double](repeating: .infinity, count: nodeCount)
            var touched: [Int] = []
            touched.reserveCapacity(min(nodeCount, 1024))

            for cell in 0 ..< cellCount {
                let boundary = cellBoundaryNodes[cell]
                guard boundary.count > 1 else { continue }

                for source in boundary {
                    let sourceOrdinal = boundaryOrdinal[source]
                    guard sourceOrdinal >= 0 else { continue }

                    for node in touched {
                        distances[node] = .infinity
                    }
                    touched.removeAll(keepingCapacity: true)

                    distances[source] = 0.0
                    touched.append(source)

                    var heap = MinHeap<HeapEntry>()
                    heap.push(HeapEntry(distance: 0.0, index: source))

                    while let entry = heap.pop() {
                        let node = entry.index
                        if entry.distance > distances[node] {
                            continue
                        }

                        if node != source, isBoundary[node] {
                            forward[sourceOrdinal].append(
                                OverlayEdge(
                                    from: source,
                                    to: node,
                                    weight: entry.distance,
                                    cellID: cell))
                            continue
                        }

                        for edge in graph.adjacencyList[node].edges {
                            let neighbor = edge.to.index
                            if cellOf[neighbor] != cell {
                                continue
                            }
                            let relaxed = entry.distance + edge.weight
                            guard relaxed < distances[neighbor] else {
                                continue
                            }

                            if !distances[neighbor].isFinite {
                                touched.append(neighbor)
                            }
                            distances[neighbor] = relaxed
                            heap.push(
                                HeapEntry(
                                    distance: relaxed,
                                    index: neighbor))
                        }
                    }
                }
            }

            var backward: [[OverlayEdge]]?
            if graph.hasDirectedEdges {
                var reverse = Array(
                    repeating: [OverlayEdge](),
                    count: ordinalCount)
                for edges in forward {
                    for edge in edges {
                        let targetOrdinal = boundaryOrdinal[edge.to]
                        guard targetOrdinal >= 0 else { continue }

                        reverse[targetOrdinal].append(edge)
                    }
                }
                backward = reverse
            }
            else {
                backward = nil
            }

            return Level(
                index: levelIndex,
                rows: rows,
                columns: columns,
                cellBoundaryNodes: cellBoundaryNodes,
                boundaryOrdinal: boundaryOrdinal,
                forward: forward,
                backward: backward)
        }

        // MARK: - Level and overlay types

        struct Level: Sendable {

            /// The level index, used for the base-cell shift.
            let index: Int

            /// Number of cell rows at this level.
            let rows: Int

            /// Number of cell columns at this level.
            let columns: Int

            /// Boundary node indices for each cell id.
            let cellBoundaryNodes: [[Int]]

            /// Maps a node index to its overlay ordinal, or `-1` when the node
            /// is not a boundary node at this level.
            let boundaryOrdinal: [Int]

            /// Overlay edges indexed by boundary ordinal.
            let forward: [[OverlayEdge]]

            /// Reverse overlay edges for directed graphs, indexed by boundary
            /// ordinal. `nil` for undirected graphs.
            let backward: [[OverlayEdge]]?

        }

        struct OverlayEdge: Sendable {

            let from: Int
            let to: Int
            let weight: Double

            /// The cell whose intra-cell shortest path this shortcut
            /// represents, or `-1` for an original cross-cell edge.
            let cellID: Int

        }

    }

    // MARK: - Convenience

    /// Builds a reusable multi-level Dijkstra index.
    ///
    /// Prefer this over ``shortestPathViaMultiLevel(from:to:levels:baseRows:baseColumns:)``
    /// when more than one route will be computed on the same graph.
    ///
    /// - Parameters:
    ///   - levels: The maximum number of hierarchy levels (default 3).
    ///   - baseRows: Number of rows in the level-0 grid (default 8).
    ///   - baseColumns: Number of columns in the level-0 grid (default 8).
    /// - Returns: `nil` for an empty graph or an invalid configuration.
    public func multiLevelIndex(
        levels: Int = 3,
        baseRows: Int = 8,
        baseColumns: Int = 8,
    ) -> MultiLevelIndex? {
        MultiLevelIndex(
            self,
            levels: levels,
            baseRows: baseRows,
            baseColumns: baseColumns)
    }

    /// Finds a shortest path using a multi-level Dijkstra index built for this
    /// single call.
    ///
    /// For repeated queries, build a ``Graph/MultiLevelIndex`` once with
    /// ``multiLevelIndex(levels:baseRows:baseColumns:)`` and reuse it.
    ///
    /// - Parameters:
    ///   - source: The start node.
    ///   - destination: The target node.
    ///   - levels: The maximum number of hierarchy levels (default 3).
    ///   - baseRows: Number of rows in the level-0 grid (default 8).
    ///   - baseColumns: Number of columns in the level-0 grid (default 8).
    /// - Returns: The shortest path as an ordered array of nodes (including
    ///   `source` and `destination`), or an empty array if no path exists.
    public func shortestPathViaMultiLevel(
        from source: Node,
        to destination: Node,
        levels: Int = 3,
        baseRows: Int = 8,
        baseColumns: Int = 8,
    ) -> [Node] {
        guard let index = multiLevelIndex(
            levels: levels,
            baseRows: baseRows,
            baseColumns: baseColumns)
        else { return [] }

        return index.shortestPath(from: source, to: destination)
    }

}
#endif
