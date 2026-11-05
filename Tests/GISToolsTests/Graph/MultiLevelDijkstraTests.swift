#if EnableGraphAPI
#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph/MultiLevelIndex`` tests.
///
/// The dedicated suite covers synthetic grids in every projection, weighted and
/// parallel edges, directed graphs, same-cell routes that leave and re-enter
/// their cell, the real-world Immenstadt fixtures and antimeridian data. The
/// exhaustive Floyd-Warshall oracle in ``ShortestPathTests`` additionally
/// checks every ordered pair on seeded random graphs.
struct MultiLevelDijkstraTests {

    // MARK: - Helpers

    private func makeGridGraph(
        rows: Int,
        columns: Int,
        projection: Projection,
        step: Double = 0.01,
    ) -> Graph {
        var graph = Graph(nodeTolerance: 0.000001)
        var nodes: [[Node]] = []
        for row in 0 ..< rows {
            var rowNodes: [Node] = []
            for column in 0 ..< columns {
                let coordinate = Coordinate3D(
                    latitude: 10.0 + (Double(row) * step),
                    longitude: 20.0 + (Double(column) * step))
                    .projected(to: projection)
                rowNodes.append(graph.createNode(at: coordinate))
            }
            nodes.append(rowNodes)
        }

        for row in 0 ..< rows {
            for column in 0 ..< columns {
                if column + 1 < columns {
                    graph.addUndirectedEdge(
                        from: nodes[row][column],
                        to: nodes[row][column + 1])
                }
                if row + 1 < rows {
                    graph.addUndirectedEdge(
                        from: nodes[row][column],
                        to: nodes[row + 1][column])
                }
            }
        }
        return graph
    }

    private func addUndirectedEdge(
        from source: Node,
        to destination: Node,
        weight: Double,
        in graph: inout Graph,
    ) {
        graph.adjacencyList[source.index].edges.append(
            Edge(from: source, to: destination, weight: weight))
        graph.adjacencyList[destination.index].edges.append(
            Edge(from: destination, to: source, weight: weight))
    }

    private func addDirectedEdge(
        from source: Node,
        to destination: Node,
        weight: Double,
        in graph: inout Graph,
    ) {
        graph.adjacencyList[source.index].edges.append(
            Edge(
                from: source,
                to: destination,
                isDirected: true,
                weight: weight))
        graph.hasDirectedEdges = true
    }

    private func minWeight(
        from source: Node,
        to destination: Node,
        in graph: Graph,
    ) -> Double? {
        graph.adjacencyList[source.index]
            .edges
            .filter { $0.to == destination }
            .map(\.weight)
            .min()
    }

    private func pathCost(_ path: [Node], in graph: Graph) -> Double? {
        if path.isEmpty {
            return nil
        }
        if path.count == 1 {
            return 0.0
        }

        var total = 0.0
        for index in 1 ..< path.count {
            guard let weight = minWeight(
                from: path[index - 1],
                to: path[index],
                in: graph)
            else { return nil }

            total += weight
        }
        return total
    }

    private func assertParity(
        _ graph: Graph,
        index: Graph.MultiLevelIndex,
        source: Node,
        destination: Node,
        label: String,
    ) throws {
        let expected = graph.shortestPath(from: source, to: destination)
        let actual = index.shortestPath(from: source, to: destination)
        let expectedCost = pathCost(expected, in: graph)

        if let expectedCost {
            #expect(actual.isNotEmpty, "\(label): expected a path")
            #expect(actual.first == source, "\(label): wrong start")
            #expect(actual.last == destination, "\(label): wrong end")
            let actualCost = try #require(
                pathCost(actual, in: graph),
                "\(label): invalid path \(actual.map(\.index))",
            )
            #expect(
                abs(actualCost - expectedCost) < 0.000001,
                "\(label): cost \(actualCost) != \(expectedCost)",
            )
        }
        else {
            #expect(
                actual.isEmpty,
                "\(label): expected no path, got \(actual.map(\.index))",
            )
        }
    }

    // MARK: - Projections and synthetic graphs

    @Test
    func gridMatchesDijkstraAcrossProjections() throws {
        let projections: [Projection] = [
            .epsg4326,
            .epsg3857,
            .epsg4978,
            .noSRID,
        ]

        for projection in projections {
            let graph = makeGridGraph(
                rows: 6,
                columns: 6,
                projection: projection)
            let index = try #require(
                graph.multiLevelIndex(
                    levels: 3,
                    baseRows: 3,
                    baseColumns: 3),
                "projection \(projection)",
            )

            for source in graph.nodes {
                for destination in graph.nodes {
                    try assertParity(
                        graph,
                        index: index,
                        source: source,
                        destination: destination,
                        label: "projection \(projection)")
                }
            }
        }
    }

    @Test
    func deepHierarchyMatchesDijkstra() throws {
        let graph = makeGridGraph(
            rows: 10,
            columns: 10,
            projection: .epsg4326)
        let index = try #require(
            graph.multiLevelIndex(
                levels: 3,
                baseRows: 5,
                baseColumns: 5),
        )
        #expect(index.levelCount == 3)

        for source in graph.nodes {
            for destination in graph.nodes {
                try assertParity(
                    graph,
                    index: index,
                    source: source,
                    destination: destination,
                    label: "deep hierarchy")
            }
        }
    }

    @Test
    func weightedEdgesAndParallelEdgesAreRespected() throws {
        var graph = Graph(nodeTolerance: 0.000001)
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.001))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.002))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.003))

        addUndirectedEdge(from: a, to: b, weight: 10.0, in: &graph)
        addUndirectedEdge(from: b, to: c, weight: 10.0, in: &graph)
        addUndirectedEdge(from: c, to: d, weight: 1.0, in: &graph)
        addUndirectedEdge(from: a, to: c, weight: 100.0, in: &graph)
        // Parallel edge: the cheaper one must win.
        addUndirectedEdge(from: a, to: b, weight: 1.0, in: &graph)

        let index = try #require(
            graph.multiLevelIndex(
                levels: 3,
                baseRows: 2,
                baseColumns: 2),
        )

        try assertParity(
            graph,
            index: index,
            source: a,
            destination: d,
            label: "weighted")
        let path = index.shortestPath(from: a, to: d)
        let cost = try #require(pathCost(path, in: graph))
        #expect(abs(cost - 12.0) < 0.000001)
    }

    @Test
    func sameCellRouteMayLeaveAndReenterCell() throws {
        var graph = Graph(nodeTolerance: 0.000001)
        let source = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let destination = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.001))
        let outside = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.02))

        addUndirectedEdge(
            from: source,
            to: destination,
            weight: 100.0,
            in: &graph)
        addUndirectedEdge(from: source, to: outside, weight: 1.0, in: &graph)
        addUndirectedEdge(
            from: outside,
            to: destination,
            weight: 1.0,
            in: &graph)

        // A 1x2 base grid puts source and destination in the same cell and
        // `outside` in the neighbouring cell.
        let index = try #require(
            graph.multiLevelIndex(
                levels: 2,
                baseRows: 1,
                baseColumns: 2),
        )

        try assertParity(
            graph,
            index: index,
            source: source,
            destination: destination,
            label: "same cell out-and-back")

        let path = index.shortestPath(from: source, to: destination)
        let cost = try #require(pathCost(path, in: graph))
        #expect(abs(cost - 2.0) < 0.000001, "cost \(cost)")
        #expect(path.contains(outside), "expected the outside route: \(path)")
    }

    @Test
    func directedSameCellRouteRespectsOneWayEdges() throws {
        var graph = Graph(nodeTolerance: 0.000001)
        let source = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let destination = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.001))
        let outside = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.02))

        addDirectedEdge(
            from: source,
            to: destination,
            weight: 100.0,
            in: &graph)
        addDirectedEdge(from: source, to: outside, weight: 1.0, in: &graph)
        addDirectedEdge(
            from: outside,
            to: destination,
            weight: 1.0,
            in: &graph)

        let index = try #require(
            graph.multiLevelIndex(
                levels: 2,
                baseRows: 1,
                baseColumns: 2),
        )

        try assertParity(
            graph,
            index: index,
            source: source,
            destination: destination,
            label: "directed same cell")

        let path = index.shortestPath(from: source, to: destination)
        let cost = try #require(pathCost(path, in: graph))
        #expect(abs(cost - 2.0) < 0.000001, "cost \(cost)")

        // No path in the reverse direction.
        #expect(index.shortestPath(from: destination, to: source).isEmpty)
    }

    @Test
    func directedGridMatchesDijkstra() throws {
        var graph = Graph(nodeTolerance: 0.000001)
        let rows = 10
        let columns = 10
        var nodes: [[Node]] = []
        for row in 0 ..< rows {
            var rowNodes: [Node] = []
            for column in 0 ..< columns {
                rowNodes.append(
                    graph.createNode(
                        at: Coordinate3D(
                            latitude: 10.0 + (Double(row) * 0.01),
                            longitude: 20.0 + (Double(column) * 0.01))))
            }
            nodes.append(rowNodes)
        }

        for row in 0 ..< rows {
            for column in 0 ..< columns {
                if column + 1 < columns {
                    addDirectedEdge(
                        from: nodes[row][column],
                        to: nodes[row][column + 1],
                        weight: 1.0,
                        in: &graph)
                }
                if row + 1 < rows {
                    addDirectedEdge(
                        from: nodes[row][column],
                        to: nodes[row + 1][column],
                        weight: 1.0,
                        in: &graph)
                }
                // A few two-way connections for branch coverage.
                if row + 1 < rows, column + 1 < columns {
                    addUndirectedEdge(
                        from: nodes[row][column],
                        to: nodes[row + 1][column + 1],
                        weight: 3.0,
                        in: &graph)
                }
            }
        }

        let index = try #require(
            graph.multiLevelIndex(
                levels: 3,
                baseRows: 5,
                baseColumns: 5),
        )
        #expect(index.levelCount == 3)

        for source in graph.nodes {
            for destination in graph.nodes {
                try assertParity(
                    graph,
                    index: index,
                    source: source,
                    destination: destination,
                    label: "directed grid")
            }
        }
    }

    // MARK: - Real data

    struct LCG {

        var state: UInt64

        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }

        mutating func int(_ upperBound: Int) -> Int {
            Int(next() % UInt64(upperBound))
        }

        mutating func double() -> Double {
            Double(next() >> 11) / Double(1 << 53)
        }

    }

    @Test
    func randomGraphsMatchDijkstra() throws {
        for seed: UInt64 in 1 ... 10 {
            for directed in [false, true] {
                var rng = LCG(state: seed)
                var graph = Graph(nodeTolerance: 0.000001)
                let nodeCount = 24
                var nodes: [Node] = []
                for index in 0 ..< nodeCount {
                    nodes.append(
                        graph.createNode(
                            at: Coordinate3D(
                                latitude: 10.0 + (Double(index / 5) * 0.01),
                                longitude: 20.0 + (Double(index % 5) * 0.01))))
                }

                var pairs: Set<Int> = []
                func key(_ a: Int, _ b: Int) -> Int {
                    (min(a, b) * 1000) + max(a, b)
                }

                for index in 1 ..< nodeCount {
                    let other = rng.int(index)
                    pairs.insert(key(index, other))
                    let weight = 1.0 + Double(rng.int(20))
                    if directed, rng.double() < 0.35 {
                        addDirectedEdge(
                            from: nodes[index],
                            to: nodes[other],
                            weight: weight,
                            in: &graph)
                    }
                    else if directed, rng.double() < 0.35 {
                        addDirectedEdge(
                            from: nodes[other],
                            to: nodes[index],
                            weight: weight,
                            in: &graph)
                    }
                    else {
                        addUndirectedEdge(
                            from: nodes[index],
                            to: nodes[other],
                            weight: weight,
                            in: &graph)
                    }
                }

                var attempts = 0
                while pairs.count < 45, attempts < 500 {
                    attempts += 1
                    let a = rng.int(nodeCount)
                    let b = rng.int(nodeCount)
                    guard a != b, pairs.insert(key(a, b)).inserted else {
                        continue
                    }

                    let weight = 1.0 + Double(rng.int(20))
                    if directed, rng.double() < 0.35 {
                        addDirectedEdge(
                            from: nodes[a],
                            to: nodes[b],
                            weight: weight,
                            in: &graph)
                    }
                    else {
                        addUndirectedEdge(
                            from: nodes[a],
                            to: nodes[b],
                            weight: weight,
                            in: &graph)
                    }
                }

                let index = try #require(
                    graph.multiLevelIndex(
                        levels: 3,
                        baseRows: 3,
                        baseColumns: 3),
                    "seed \(seed) directed \(directed)",
                )

                for source in nodes {
                    for destination in nodes {
                        try assertParity(
                            graph,
                            index: index,
                            source: source,
                            destination: destination,
                            label: "random seed \(seed) directed \(directed)")
                    }
                }
            }
        }
    }

    @Test
    func realWorldNetworkMatchesDijkstra() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let index = try #require(
            graph.multiLevelIndex(
                levels: 3,
                baseRows: 4,
                baseColumns: 4),
        )

        let nodes = graph.nodes
        let step = max(1, nodes.count / 20)
        var sample: [Node] = []
        for index in stride(from: 0, to: nodes.count, by: step) {
            sample.append(nodes[index])
        }

        for source in sample {
            for destination in sample {
                try assertParity(
                    graph,
                    index: index,
                    source: source,
                    destination: destination,
                    label: "immenstadt")
            }
        }
    }

    @Test
    func directedRealWorldNetworkMatchesDijkstra() throws {
        let collection = try GraphTestHelper.immenstadtCollection()
        let graph = Graph(
            featureCollection: collection,
            isDirected: true)
        let index = try #require(
            graph.multiLevelIndex(
                levels: 3,
                baseRows: 4,
                baseColumns: 4),
        )

        let nodes = graph.nodes
        let step = max(1, nodes.count / 12)
        var sample: [Node] = []
        for index in stride(from: 0, to: nodes.count, by: step) {
            sample.append(nodes[index])
        }

        for source in sample {
            for destination in sample {
                try assertParity(
                    graph,
                    index: index,
                    source: source,
                    destination: destination,
                    label: "directed immenstadt")
            }
        }
    }

    @Test
    func antimeridianGraphMatchesDijkstra() throws {
        let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978]

        for projection in projections {
            var graph = Graph(nodeTolerance: 0.000001)
            let a = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 179.9)
                    .projected(to: projection))
            let b = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: -179.9)
                    .projected(to: projection))
            let c = graph.createNode(
                at: Coordinate3D(latitude: 10.1, longitude: 179.8)
                    .projected(to: projection))
            let d = graph.createNode(
                at: Coordinate3D(latitude: 10.1, longitude: -179.8)
                    .projected(to: projection))

            graph.addUndirectedEdge(from: a, to: b)
            graph.addUndirectedEdge(from: a, to: c)
            graph.addUndirectedEdge(from: b, to: d)
            graph.addUndirectedEdge(from: c, to: d)

            let index = try #require(
                graph.multiLevelIndex(
                    levels: 2,
                    baseRows: 2,
                    baseColumns: 2),
                "projection \(projection)",
            )

            for source in graph.nodes {
                for destination in graph.nodes {
                    try assertParity(
                        graph,
                        index: index,
                        source: source,
                        destination: destination,
                        label: "antimeridian \(projection)")
                }
            }
        }
    }

    // MARK: - Configuration and edge cases

    @Test
    func invalidConfigurationOrEmptyGraphReturnsNil() {
        #expect(Graph().multiLevelIndex() == nil)
        #expect(
            Graph().multiLevelIndex(
                levels: 0,
                baseRows: 8,
                baseColumns: 8) == nil,
        )
        #expect(
            Graph().multiLevelIndex(
                levels: 3,
                baseRows: 0,
                baseColumns: 8) == nil,
        )
        #expect(
            Graph().multiLevelIndex(
                levels: 3,
                baseRows: 8,
                baseColumns: 0) == nil,
        )
    }

    @Test
    func levelsAreClampedAndSingleCellGridsWork() throws {
        var graph = Graph(nodeTolerance: 0.000001)
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.01))
        graph.addUndirectedEdge(from: a, to: b)

        let clamped = try #require(
            graph.multiLevelIndex(
                levels: 100,
                baseRows: 8,
                baseColumns: 8),
        )
        #expect(clamped.levelCount == 3)

        let singleCell = try #require(
            graph.multiLevelIndex(
                levels: 100,
                baseRows: 1,
                baseColumns: 1),
        )
        #expect(singleCell.levelCount == 1)
        try assertParity(
            graph,
            index: singleCell,
            source: a,
            destination: b,
            label: "single cell")
    }

    @Test
    func singleNodeGraphWorks() throws {
        var graph = Graph(nodeTolerance: 0.000001)
        let node = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let index = try #require(graph.multiLevelIndex())

        #expect(index.shortestPath(from: node, to: node) == [node])
        #expect(index.originalNodeCount == 1)
        #expect(index.levelCount == 3)
    }

    @Test
    func disconnectedNodesReturnEmptyPath() throws {
        var graph = Graph(nodeTolerance: 0.000001)
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.01))
        let index = try #require(graph.multiLevelIndex())

        #expect(index.shortestPath(from: a, to: b).isEmpty)
        #expect(index.shortestPath(from: b, to: a).isEmpty)
    }

    @Test
    func outOfRangeNodesReturnEmptyPath() throws {
        var graph = Graph(nodeTolerance: 0.000001)
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.01))
        graph.addUndirectedEdge(from: a, to: b)

        let index = try #require(graph.multiLevelIndex())
        let invalid = Node(
            index: 99,
            coordinate: Coordinate3D(latitude: 0.0, longitude: 0.0))

        #expect(index.shortestPath(from: invalid, to: a).isEmpty)
        #expect(index.shortestPath(from: a, to: invalid).isEmpty)
    }

    @Test
    func constrainedQueriesFallBackToTheOriginalGraph() throws {
        let graph = makeGridGraph(
            rows: 5,
            columns: 5,
            projection: .epsg4326)
        let index = try #require(
            graph.multiLevelIndex(
                levels: 2,
                baseRows: 2,
                baseColumns: 2),
        )

        let source = try #require(graph.nodes.first)
        let destination = try #require(graph.nodes.last)

        let unconstrained = index.shortestPath(
            from: source,
            to: destination)
        #expect(
            index.shortestPath(
                from: source,
                to: destination,
                blockedNodes: nil,
                edgeFilter: nil)
                == unconstrained,
        )

        let blocked = Set([graph.nodes[graph.nodes.count / 2]])
        #expect(
            index.shortestPath(
                from: source,
                to: destination,
                blockedNodes: blocked)
                == graph.shortestPath(
                    from: source,
                    to: destination,
                    blockedNodes: blocked),
        )

        let filter: (Edge) -> Bool = { edge in edge.weight < 100_000.0 }
        #expect(
            index.shortestPath(
                from: source,
                to: destination,
                blockedNodes: nil,
                edgeFilter: filter)
                == graph.shortestPath(
                    from: source,
                    to: destination,
                    edgeFilter: filter),
        )
    }

    @Test
    func indexIsReusable() throws {
        let graph = makeGridGraph(
            rows: 4,
            columns: 4,
            projection: .epsg3857)
        let index = try #require(
            graph.multiLevelIndex(
                levels: 3,
                baseRows: 2,
                baseColumns: 2),
        )

        let source = try #require(graph.nodes.first)
        let destination = try #require(graph.nodes.last)
        let first = index.shortestPath(from: source, to: destination)

        for _ in 0 ..< 5 {
            #expect(
                index.shortestPath(from: source, to: destination)
                    == first,
            )
        }
    }

    @Test
    func oneShotConvenienceMatchesIndex() throws {
        let graph = makeGridGraph(
            rows: 4,
            columns: 4,
            projection: .epsg4326)
        let index = try #require(
            graph.multiLevelIndex(
                levels: 2,
                baseRows: 2,
                baseColumns: 2),
        )
        let source = try #require(graph.nodes.first)
        let destination = try #require(graph.nodes.last)

        #expect(
            graph.shortestPathViaMultiLevel(
                from: source,
                to: destination,
                levels: 2,
                baseRows: 2,
                baseColumns: 2)
                == index.shortestPath(from: source, to: destination),
        )
    }

}
#endif
