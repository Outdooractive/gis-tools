import Foundation
@testable import GISTools
import Testing

/// Reusable contraction routing index tests.
struct RoutingIndexTests {

    @Test
    func emptyGraphHasNoIndex() {
        #expect(Graph().routingIndex() == nil)
    }

    @Test
    func indexReducesNodeCountOnRealNetwork() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let index = try #require(graph.routingIndex())

        #expect(index.originalNodeCount == graph.nodeCount)
        #expect(index.contractedNodeCount < index.originalNodeCount)
    }

    @Test(arguments: [
        RoutingAlgorithm.dijkstra,
        .aStar,
        .bidirectional,
    ])
    func indexMatchesDirectSearch(algorithm: RoutingAlgorithm) throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let index = try #require(graph.routingIndex())
        let component = try #require(graph.connectedComponents.max(by: { $0.count < $1.count }))
        let start = try #require(component.first)
        let end = try #require(component.last)

        let direct = directPath(
            algorithm,
            in: graph,
            from: start,
            to: end)
        let indexed = indexedPath(
            algorithm,
            in: index,
            from: start,
            to: end)

        #expect(indexed.first == start)
        #expect(indexed.last == end)
        #expect(
            abs(graph.length(ofPath: direct) - graph.length(ofPath: indexed)) < 5.0,
            "\(algorithm) path mismatch"
        )
    }

    @Test
    func indexFallsBackForEdgeFilter() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let index = try #require(graph.routingIndex())
        let hikingTypes: Set = ["footway", "path", "track", "pedestrian", "steps"]
        let filter: (Edge) -> Bool = { edge in
            guard let type: String = edge.feature?.property(for: "type") else { return false }

            return hikingTypes.contains(type)
        }

        let component = try #require(GraphTestHelper.largestFilteredComponent(
            in: graph,
            edgeFilter: filter))
        let end = GraphTestHelper.farthestNode(from: component.seed, in: component.reachable)
            ?? component.reachable.last!

        let direct = graph.shortestPath(
            from: component.seed,
            to: end,
            edgeFilter: filter)
        let indexed = index.shortestPath(
            from: component.seed,
            to: end,
            blockedNodes: nil,
            edgeFilter: filter)

        #expect(indexed.first == component.seed)
        #expect(indexed.last == end)
        #expect(
            abs(graph.length(ofPath: direct) - graph.length(ofPath: indexed)) < 5.0
        )
    }

    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func indexAcrossProjections(projection: Projection) throws {
        let coordinates = (0 ... 6).map { index in
            Coordinate3D(latitude: 10.0 + Double(index) * 0.01, longitude: 20.0)
                .projected(to: projection)
        }
        var graph = Graph(nodeTolerance: 1.0)
        let nodes = coordinates.map { graph.createNode(at: $0) }
        for index in 0 ..< nodes.count - 1 {
            graph.addUndirectedEdge(from: nodes[index], to: nodes[index + 1])
        }

        let index = graph.routingIndex()
        let start = try #require(nodes.first)
        let end = try #require(nodes.last)
        let direct = graph.shortestPath(from: start, to: end)
        let indexed = index?.shortestPath(from: start, to: end) ?? []

        #expect(indexed.first == start, "projection \(projection)")
        #expect(indexed.last == end, "projection \(projection)")
        #expect(
            abs(graph.length(ofPath: direct) - graph.length(ofPath: indexed)) < 0.001,
            "projection \(projection) route mismatch"
        )
    }

    @Test
    func indexAcrossAntimeridian() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.95))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
        let d = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.85))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)

        let index = graph.routingIndex()
        let direct = graph.shortestPath(from: a, to: d)
        let indexed = index?.shortestPath(from: a, to: d) ?? []

        #expect(indexed.first == a)
        #expect(indexed.last == d)
        #expect(abs(graph.length(ofPath: direct) - graph.length(ofPath: indexed)) < 1.0)
    }

    @Test
    func indexSupportsDirectedGraphs() {
        var graphValue = Graph(isDirected: true)
        let a = graphValue.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graphValue.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graphValue.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graphValue.addDirectedEdge(from: a, to: b, isDirected: true)
        graphValue.addDirectedEdge(from: b, to: c, isDirected: true)

        let index = graphValue.routingIndex()
        let path = index?.shortestPath(from: a, to: c) ?? []

        #expect(path.first == a)
        #expect(path.last == c)
        #expect(index?.shortestPath(from: c, to: a).isEmpty == true)
    }

    @Test
    func indexFallsBackForRemovedEndpoint() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let d = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: 20.15))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)

        let index = graph.routingIndex()
        let direct = graph.shortestPath(from: a, to: b)
        let indexed = index?.shortestPath(from: a, to: b) ?? []

        #expect(indexed.first == a)
        #expect(indexed.last == b)
        #expect(indexed == direct)
    }

    @Test
    func indexFallsBackForBlockedNodes() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)

        let index = graph.routingIndex()
        let path = index?.shortestPath(
            from: a,
            to: c,
            blockedNodes: Set([b])) ?? []

        #expect(path.isEmpty)
    }

    // MARK: - Helpers

    enum RoutingAlgorithm: String, Sendable, CustomStringConvertible {

        case dijkstra
        case aStar
        case bidirectional

        var description: String {
            rawValue
        }

    }

    private func directPath(
        _ algorithm: RoutingAlgorithm,
        in graph: Graph,
        from start: Node,
        to end: Node
    ) -> [Node] {
        switch algorithm {
        case .dijkstra:
            return graph.shortestPath(from: start, to: end)
        case .aStar:
            return graph.aStarPath(from: start, to: end)
        case .bidirectional:
            return graph.bidirectionalShortestPath(from: start, to: end)
        }
    }

    private func indexedPath(
        _ algorithm: RoutingAlgorithm,
        in index: Graph.RoutingIndex,
        from start: Node,
        to end: Node
    ) -> [Node] {
        switch algorithm {
        case .dijkstra:
            return index.shortestPath(from: start, to: end)
        case .aStar:
            return index.aStarPath(from: start, to: end)
        case .bidirectional:
            return index.bidirectionalShortestPath(from: start, to: end)
        }
    }

}
