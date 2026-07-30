import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
    import CoreLocation
#endif

/// ``Graph/betweennessCentrality(edgeFilter:)`` tests.
///
/// Betweenness centrality measures how often a node lies on shortest paths
/// between other nodes. Coverage spans synthetic graphs with known
/// centralities, the real-world Immenstadt network, all supported
/// projections, antimeridian-crossing geometries, and directed graphs.
struct BetweennessCentralityTests {

    // MARK: - Basic properties

    @Test
    func leafNodeHasZeroBetweenness() {
        // a - b - c - d: the endpoints a and d lie on no shortest path between
        // others, so their betweenness is 0.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 10.15, longitude: 20.15))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)

        let centrality = graph.betweennessCentrality()
        #expect(
            centrality[a] == 0.0,
            "Leaf a should have 0 betweenness, got \(centrality[a] ?? -1)")
        #expect(
            centrality[d] == 0.0,
            "Leaf d should have 0 betweenness, got \(centrality[d] ?? -1)")
    }

    @Test
    func middleNodeOfChainHasHighestBetweenness() {
        // a - b - c - d: b lies on paths a->c, a->d; c lies on paths a->d, b->d.
        // The middle two have equal, positive betweenness; endpoints 0.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 10.15, longitude: 20.15))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)

        let centrality = graph.betweennessCentrality()
        let bValue = centrality[b] ?? -1
        let cValue = centrality[c] ?? -1
        #expect(
            bValue > 0.0,
            "Middle node b should have positive betweenness, got \(bValue)")
        #expect(
            cValue > 0.0,
            "Middle node c should have positive betweenness, got \(cValue)")
        // b and c should have equal betweenness by symmetry.
        #expect(
            abs(bValue - cValue) < 0.001,
            "b and c should be equal, got \(bValue) vs \(cValue)")
        // The endpoints must be 0.
        #expect(centrality[a] == 0.0)
        #expect(centrality[d] == 0.0)
    }

    @Test
    func cycleNodesHaveEqualBetweenness() {
        // A pure cycle of 4 nodes: by symmetry every node has equal betweenness.
        var graph = Graph()
        let nodes = (0..<4).map { i in
            graph.createNode(
                at: Coordinate3D(
                    latitude: 10.0 + 0.01 * Double(i % 2),
                    longitude: 20.0 + 0.01 * Double(i / 2)))
        }
        for i in 0..<nodes.count {
            graph.addUndirectedEdge(
                from: nodes[i], to: nodes[(i + 1) % nodes.count])
        }

        let centrality = graph.betweennessCentrality()
        let values = nodes.map { centrality[$0] ?? -1 }
        let first = values[0]
        for v in values {
            #expect(
                abs(v - first) < 0.001,
                "Cycle nodes should have equal betweenness, got \(v) vs \(first)"
            )
        }
        #expect(first > 0.0, "Cycle nodes should have positive betweenness")
    }

    @Test
    func emptyGraphReturnsEmpty() {
        let graph = Graph()
        #expect(graph.betweennessCentrality().isEmpty)
    }

    @Test
    func singleEdgeBothNodesZeroBetweenness() {
        // Two nodes, one edge: neither lies on a path between other nodes.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)

        let centrality = graph.betweennessCentrality()
        #expect(centrality[a] == 0.0)
        #expect(centrality[b] == 0.0)
    }

    // MARK: - Real network

    @Test
    func immenstadtBetweennessIsNonNegative() throws {
        // Centrality values must be non-negative, and at least one node must
        // have positive betweenness (otherwise the metric is trivially 0).
        let graph = try GraphTestHelper.immenstadtGraph()
        let centrality = graph.betweennessCentrality()
        #expect(centrality.count == graph.nodeCount)
        var maxValue = 0.0
        var allNonNegative = true
        for (_, value) in centrality {
            if value < 0.0 { allNonNegative = false }
            maxValue = max(maxValue, value)
        }
        #expect(allNonNegative, "Negative betweenness encountered")
        #expect(
            maxValue > 0.0,
            "Expected at least one node with positive betweenness")
    }

    @Test
    func immenstadtArticulationPointsHaveHighBetweenness() throws {
        // Articulation points (critical intersections) tend to carry
        // significant through-traffic: their betweenness should be at least the
        // graph's median betweenness.
        let graph = try GraphTestHelper.immenstadtGraph()
        let centrality = graph.betweennessCentrality()
        let cutVertices = Set(graph.articulationPoints().map(\.index))

        let allValues = adjacencyListSortedValues(
            graph: graph, centrality: centrality)
        let median = allValues.sorted(by: <)[allValues.count / 2]

        var cutVertexSum = 0.0
        var otherSum = 0.0
        for (index, value) in allValues.enumerated() where value > 0.0 {
            if cutVertices.contains(index) {
                cutVertexSum += value
            } else {
                otherSum += value
            }
        }
        // The mean betweenness of cut vertices should exceed the graph median.
        let cutVertexValues = allValues.enumerated().filter {
            cutVertices.contains($0.offset)
        }.map(\.element)
        if cutVertexValues.isNotEmpty {
            let cutMean =
                cutVertexValues.reduce(0.0, +) / Double(cutVertexValues.count)
            #expect(
                cutMean >= median - 0.001,
                "Cut vertices should have above-median betweenness")
        }
        _ = cutVertexSum
        _ = otherSum
    }

    // MARK: - Projection coverage

    @Test
    func betweennessAcrossProjections() {
        let projections: [Projection] = [
            .epsg4326, .epsg3857, .epsg4978, .noSRID,
        ]

        for projection in projections {
            // Chain a-b-c-d: middle nodes must have positive betweenness.
            var graph = Graph(nodeTolerance: 1.0)
            let a = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(
                    to: projection))
            let b = graph.createNode(
                at: Coordinate3D(latitude: 10.05, longitude: 20.05).projected(
                    to: projection))
            let c = graph.createNode(
                at: Coordinate3D(latitude: 10.1, longitude: 20.1).projected(
                    to: projection))
            let d = graph.createNode(
                at: Coordinate3D(latitude: 10.15, longitude: 20.15).projected(
                    to: projection))
            graph.addUndirectedEdge(from: a, to: b)
            graph.addUndirectedEdge(from: b, to: c)
            graph.addUndirectedEdge(from: c, to: d)

            let centrality = graph.betweennessCentrality()
            #expect(
                centrality[b] ?? -1 > 0.0,
                "projection \(projection): b should have positive betweenness")
            #expect(
                centrality[c] ?? -1 > 0.0,
                "projection \(projection): c should have positive betweenness")
            #expect(
                centrality[a] == 0.0,
                "projection \(projection): a should have 0 betweenness")
            #expect(
                centrality[d] == 0.0,
                "projection \(projection): d should have 0 betweenness")
        }
    }

    // MARK: - Antimeridian

    @Test
    func betweennessAcrossAntimeridian() {
        // Chain straddling the dateline: a(179.9) - b(-179.95) - c(-179.9) - d(-179.85).
        // The middle nodes b and c must have positive betweenness.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 179.9))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: -179.95))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: -179.9))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: -179.85))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)

        let centrality = graph.betweennessCentrality()
        #expect(
            centrality[b] ?? -1 > 0.0,
            "Antimeridian middle b should have positive betweenness")
        #expect(
            centrality[c] ?? -1 > 0.0,
            "Antimeridian middle c should have positive betweenness")
        #expect(centrality[a] == 0.0)
        #expect(centrality[d] == 0.0)
    }

    // MARK: - Directed

    @Test
    func directedOneWayChainBetweenness() {
        // One-way chain A -> B -> C: B lies on the only path A->C, so B has
        // positive betweenness; A and C have 0.
        let chain = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!,
            properties: ["oneway": "yes"])
        let directed = Graph(
            featureCollection: FeatureCollection([chain]), isDirected: true)

        let centrality = directed.betweennessCentrality()
        let nodes = directed.nodes
        let a = nodes[0]
        let b = nodes[1]
        let c = nodes[2]
        #expect(
            centrality[b] ?? -1 > 0.0,
            "Middle node B should have positive betweenness")
        #expect(centrality[a] == 0.0)
        #expect(centrality[c] == 0.0)
    }

    // MARK: - Support

    /// Returns the per-node centrality values in node-index order.
    private func adjacencyListSortedValues(
        graph: Graph, centrality: [Node: Double]
    ) -> [Double] {
        graph.nodes.map { centrality[$0] ?? 0.0 }
    }

}
