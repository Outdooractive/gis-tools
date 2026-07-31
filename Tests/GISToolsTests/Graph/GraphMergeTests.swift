import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
    import CoreLocation
#endif

/// ``Graph/merged(with:)`` tests.
///
/// Covers disjoint graphs, overlapping graphs with spatial node deduplication,
/// duplicate edge removal, the real-world Immenstadt and Immenstadt_2 road
/// networks, empty graphs, directed graphs, all supported projections, and
/// antimeridian-crossing geometries.
struct GraphMergeTests {

    // MARK: - Disjoint graphs

    @Test
    func mergingDisjointGraphsPreservesAllNodesAndEdges() {
        var graph1 = Graph()
        let a1 = graph1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b1 = graph1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph1.addUndirectedEdge(from: a1, to: b1)

        var graph2 = Graph()
        let a2 = graph2.createNode(
            at: Coordinate3D(latitude: 11.0, longitude: 21.0))
        let b2 = graph2.createNode(
            at: Coordinate3D(latitude: 11.05, longitude: 21.05))
        graph2.addUndirectedEdge(from: a2, to: b2)

        let merged = graph1.merged(with: graph2)
        #expect(merged.nodeCount == 4)
        #expect(merged.edges.count == 2)
    }

    @Test
    func mergingSameGraphIsIdentity() {
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)

        let merged = graph.merged(with: graph)
        #expect(merged.nodeCount == 2)
        #expect(merged.edges.count == 1)
    }

    // MARK: - Spatial deduplication

    @Test
    func mergingOverlappingGraphsDeduplicatesNodes() {
        var graph1 = Graph()
        let a = graph1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph1.addUndirectedEdge(from: a, to: b)

        var graph2 = Graph()
        // Same location as 'b' in graph1, within 1m tolerance.
        let c = graph2.createNode(
            at: Coordinate3D(latitude: 10.0500001, longitude: 20.0500001))
        let d = graph2.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph2.addUndirectedEdge(from: c, to: d)

        let merged = graph1.merged(with: graph2)
        #expect(merged.nodeCount == 3, "Node b and c should merge into one")
        #expect(merged.edges.count == 2)
    }

    @Test
    func mergingOverlappingGraphsDeduplicatesEdges() {
        var graph1 = Graph()
        let a = graph1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph1.addUndirectedEdge(from: a, to: b)

        var graph2 = Graph()
        let a2 = graph2.createNode(
            at: Coordinate3D(latitude: 10.0000001, longitude: 20.0000001))
        let b2 = graph2.createNode(
            at: Coordinate3D(latitude: 10.0500001, longitude: 20.0500001))
        graph2.addUndirectedEdge(from: a2, to: b2)

        let merged = graph1.merged(with: graph2)
        #expect(merged.nodeCount == 2, "All nodes should deduplicate to 2")
        #expect(merged.edges.count == 1, "Duplicate edge should be removed")
    }

    // MARK: - Cut-edge scenario

    @Test
    func cutEdgesFormChainInMergedGraph() {
        // Graph 1: a --- b  (edge goes up to buffer boundary at b)
        var graph1 = Graph()
        let a = graph1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph1.addUndirectedEdge(from: a, to: b)

        // Graph 2: c --- d  (continues from buffer boundary at c, which
        // equals b spatially)
        var graph2 = Graph()
        let c = graph2.createNode(
            at: Coordinate3D(latitude: 10.0500001, longitude: 20.0500001))
        let d = graph2.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph2.addUndirectedEdge(from: c, to: d)

        let merged = graph1.merged(with: graph2)
        #expect(merged.nodeCount == 3, "b and c dedup → 3 nodes")
        #expect(merged.edges.count == 2, "Two edges forming chain a-bc-d")

        // Verify chain connectivity: a should reach d via the shared node.
        let path = merged.shortestPath(from: merged.nodes[0], to: merged.nodes[2])
        #expect(path.count == 3, "Chain path should be 3 nodes: a→bc→d")
    }

    // MARK: - Real network merge

    @Test
    func mergingImmenstadtNetworks() throws {
        let graph1 = try GraphTestHelper.immenstadtGraph()
        let graph2 = try GraphTestHelper.immenstadtGraph2()

        let merged = graph1.merged(with: graph2)

        #expect(merged.nodeCount > 0)
        #expect(merged.edges.count > 0)
        #expect(
            merged.nodeCount <= graph1.nodeCount + graph2.nodeCount,
            "Merged nodes should be ≤ sum (spatial dedup)")
        #expect(
            merged.edges.count <= graph1.edges.count + graph2.edges.count,
            "Merged edges should be ≤ sum (duplicate removal)")

        print(
            "Immenstadt merge: \(graph1.nodeCount)+\(graph2.nodeCount) → \(merged.nodeCount) nodes,"
            + " \(graph1.edges.count)+\(graph2.edges.count) → \(merged.edges.count) edges")
    }

    // MARK: - Empty graphs

    @Test
    func mergingWithEmptyGraphReturnsSelf() {
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)

        let merged = graph.merged(with: Graph())
        #expect(merged.nodeCount == 2)
        #expect(merged.edges.count == 1)
    }

    @Test
    func mergingEmptyWithGraphReturnsOther() {
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)

        let merged = Graph().merged(with: graph)
        #expect(merged.nodeCount == 2)
        #expect(merged.edges.count == 1)
    }

    @Test
    func mergingTwoEmptyGraphsProducesEmpty() {
        let merged = Graph().merged(with: Graph())
        #expect(merged.nodeCount == 0)
        #expect(merged.edges.isEmpty)
    }

    // MARK: - Directed graphs

    @Test
    func mergingDirectedGraphPreservesOneWayEdges() {
        let feature1 = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.05, longitude: 20.05),
            ])!,
            properties: ["oneway": "yes"])
        let directed1 = Graph(
            featureCollection: FeatureCollection([feature1]),
            isDirected: true)

        let feature2 = Feature(
            LineString([
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!,
            properties: ["oneway": "yes"])
        let directed2 = Graph(
            featureCollection: FeatureCollection([feature2]),
            isDirected: true)

        let merged = directed1.merged(with: directed2)
        #expect(merged.isDirected)

        // The shared middle node merges, forming a chain of two one-way edges.
        #expect(merged.nodeCount == 3)
        #expect(merged.directedEdgeCount == 2)
    }

    @Test
    func mergingUndirectedWithDirectedProducesDirected() {
        var undirected = Graph()
        let a = undirected.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = undirected.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        undirected.addUndirectedEdge(from: a, to: b)

        let feature = Feature(
            LineString([
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!,
            properties: ["oneway": "yes"])
        let directed = Graph(
            featureCollection: FeatureCollection([feature]),
            isDirected: true)

        let merged = undirected.merged(with: directed)
        #expect(merged.isDirected, "Merged should be directed when one input is")
    }

    // MARK: - Projection coverage

    @Test
    func mergingAcrossProjections() {
        let projections: [Projection] = [
            .epsg4326, .epsg3857, .epsg4978, .noSRID,
        ]

        for projection in projections {
            var graph1 = Graph(nodeTolerance: 1.0)
            let a1 = graph1.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(
                    to: projection))
            let b1 = graph1.createNode(
                at: Coordinate3D(latitude: 10.05, longitude: 20.05).projected(
                    to: projection))
            graph1.addUndirectedEdge(from: a1, to: b1)

            var graph2 = Graph(nodeTolerance: 1.0)
            let a2 = graph2.createNode(
                at: Coordinate3D(latitude: 11.0, longitude: 21.0).projected(
                    to: projection))
            let b2 = graph2.createNode(
                at: Coordinate3D(latitude: 11.05, longitude: 21.05).projected(
                    to: projection))
            graph2.addUndirectedEdge(from: a2, to: b2)

            let merged = graph1.merged(with: graph2)
            #expect(
                merged.nodeCount == 4,
                "projection \(projection): got \(merged.nodeCount) nodes")
            #expect(
                merged.edges.count == 2,
                "projection \(projection): got \(merged.edges.count) edges")
        }
    }

    // MARK: - Antimeridian

    @Test
    func mergingAcrossAntimeridian() {
        var graph1 = Graph()
        let a = graph1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 179.9))
        let b = graph1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: -179.9))
        graph1.addUndirectedEdge(from: a, to: b)

        var graph2 = Graph()
        let c = graph2.createNode(
            at: Coordinate3D(latitude: 80.0, longitude: 179.9))
        let d = graph2.createNode(
            at: Coordinate3D(latitude: 80.0, longitude: -179.9))
        graph2.addUndirectedEdge(from: c, to: d)

        let merged = graph1.merged(with: graph2)
        #expect(merged.nodeCount == 4)
        #expect(merged.edges.count == 2)
    }

    // MARK: - Connectivity preservation

    @Test
    func mergedGraphPreservesConnectivity() {
        // Graph 1: triangle a-b-c-a
        var graph1 = Graph()
        let a = graph1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.0))
        graph1.addUndirectedEdge(from: a, to: b)
        graph1.addUndirectedEdge(from: b, to: c)
        graph1.addUndirectedEdge(from: c, to: a)

        // Graph 2: path c-d (shared node c via spatial proximity)
        var graph2 = Graph()
        let c2 = graph2.createNode(
            at: Coordinate3D(latitude: 10.0500001, longitude: 20.0000001))
        let d = graph2.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.0))
        graph2.addUndirectedEdge(from: c2, to: d)

        let merged = graph1.merged(with: graph2)
        #expect(merged.connectedComponents.count == 1,
                "Merged graph should be fully connected")

        // Route from a to d should work.
        let path = merged.shortestPath(
            from: merged.node(at: a.coordinate, tolerance: 5.0)!,
            to: merged.node(at: d.coordinate, tolerance: 5.0)!)
        #expect(path.isNotEmpty)
    }

}
