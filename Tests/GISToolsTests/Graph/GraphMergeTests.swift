import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
    import CoreLocation
#endif

/// ``Graph/merged(_:)`` tests.
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

        let merged = Graph.merged([graph1, graph2])
        #expect(merged.nodeCount == 4)
        #expect(merged.edges.count == 2)
    }

    @Test
    func mergingSingleGraphReturnsSameGraph() {
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)

        let merged = Graph.merged([graph])
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
        let c = graph2.createNode(
            at: Coordinate3D(latitude: 10.0500001, longitude: 20.0500001))
        let d = graph2.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph2.addUndirectedEdge(from: c, to: d)

        let merged = Graph.merged([graph1, graph2])
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

        let merged = Graph.merged([graph1, graph2])
        #expect(merged.nodeCount == 2, "All nodes should deduplicate to 2")
        #expect(merged.edges.count == 1, "Duplicate edge should be removed")
    }

    // MARK: - Cut-edge scenario

    @Test
    func cutEdgesFormChainInMergedGraph() {
        var graph1 = Graph()
        let a = graph1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph1.addUndirectedEdge(from: a, to: b)

        var graph2 = Graph()
        let c = graph2.createNode(
            at: Coordinate3D(latitude: 10.0500001, longitude: 20.0500001))
        let d = graph2.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph2.addUndirectedEdge(from: c, to: d)

        let merged = Graph.merged([graph1, graph2])
        #expect(merged.nodeCount == 3, "b and c dedup → 3 nodes")
        #expect(merged.edges.count == 2, "Two edges forming chain a-bc-d")

        let path = merged.shortestPath(from: merged.nodes[0], to: merged.nodes[2])
        #expect(path.count == 3, "Chain path should be 3 nodes: a→bc→d")
    }

    // MARK: - Seam stitching

    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978])
    func stitchingDanglingEndpoint(projection: Projection) throws {
        let a = Coordinate3D(latitude: 0.0, longitude: -0.00005)
            .projected(to: projection)
        let d = Coordinate3D(latitude: 0.0, longitude: 0.00005)
            .projected(to: projection)
        let c = Coordinate3D(latitude: 0.0, longitude: 0.0)
            .projected(to: projection)
        let e = Coordinate3D(latitude: 0.0, longitude: 0.0001)
            .projected(to: projection)

        var graph1 = Graph(nodeTolerance: 0.001)
        let a1 = graph1.createNode(at: a)
        let d1 = graph1.createNode(at: d)
        graph1.addUndirectedEdge(from: a1, to: d1)

        var graph2 = Graph(nodeTolerance: 0.001)
        let c2 = graph2.createNode(at: c)
        let e2 = graph2.createNode(at: e)
        graph2.addUndirectedEdge(from: c2, to: e2)

        let merged = Graph.merged(
            [graph1, graph2],
            stitchingTolerance: 1.0)

        #expect(merged.nodeCount == 4)
        #expect(merged.edges.count == 3)
        #expect(merged.connectedComponents.count == 1)

        let aNode = try #require(merged.node(at: a, tolerance: 5.0))
        let dNode = try #require(merged.node(at: d, tolerance: 5.0))
        let eNode = try #require(merged.node(at: e, tolerance: 5.0))

        #expect(
            merged.weight(from: aNode, to: dNode) == nil,
            "The overlapping direct segment should be split and removed")
        #expect(merged.shortestPath(from: aNode, to: eNode).isNotEmpty)
    }

    @Test
    func stitchingNoSRIDDanglingEndpoint() throws {
        let a = Coordinate3D(x: -5.0, y: 0.0, projection: .noSRID)
        let d = Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID)
        let c = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let e = Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID)

        var graph1 = Graph(nodeTolerance: 0.1)
        let a1 = graph1.createNode(at: a)
        let d1 = graph1.createNode(at: d)
        graph1.addUndirectedEdge(from: a1, to: d1)

        var graph2 = Graph(nodeTolerance: 0.1)
        let c2 = graph2.createNode(at: c)
        let e2 = graph2.createNode(at: e)
        graph2.addUndirectedEdge(from: c2, to: e2)

        let merged = Graph.merged(
            [graph1, graph2],
            stitchingTolerance: 0.1)

        #expect(merged.nodeCount == 4)
        #expect(merged.edges.count == 3)
        #expect(merged.connectedComponents.count == 1)

        let aNode = try #require(merged.node(at: a, tolerance: 5.0))
        let dNode = try #require(merged.node(at: d, tolerance: 5.0))
        #expect(merged.weight(from: aNode, to: dNode) == nil)
    }

    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func deduplicatesMultipleOverlappingRoads(projection: Projection) {
        func coordinate(_ distance: Double) -> Coordinate3D {
            if projection == .noSRID {
                return Coordinate3D(
                    x: distance,
                    y: 0.0,
                    projection: .noSRID)
            }

            return Coordinate3D(
                latitude: 0.0,
                longitude: distance * 0.00001)
                .projected(to: projection)
        }

        func makeGraph(_ segments: [(Double, Double)]) -> Graph {
            let features = segments.map { start, end in
                Feature(
                    LineString(unchecked: [
                        coordinate(start),
                        coordinate(end),
                    ]),
                    properties: [
                        "name": "Overlap Road",
                        "original_id": 42,
                    ])
            }

            return Graph(
                featureCollection: FeatureCollection(features),
                nodeTolerance: 0.001)
        }

        let merged = Graph.merged(
            [
                makeGraph([(0.0, 10.0)]),
                makeGraph([(2.0, 12.0)]),
                makeGraph([(0.0, 5.0), (5.0, 10.0)]),
                makeGraph([(4.0, 8.0)]),
            ],
            stitchingTolerance: 0.1)

        #expect(merged.nodeCount == 7)
        #expect(merged.edges.count == 6)
        #expect(
            merged.directedEdgeCount == 12,
            "Every undirected edge should be stored exactly twice")

        #expect(
            merged.edges.allSatisfy { edge in
                let originalID: Int? = edge.feature?.property(for: "original_id")
                let name: String? = edge.feature?.property(for: "name")
                return originalID == 42 && name == "Overlap Road"
            },
            "Splitting and merging must preserve the shared road properties")

        var seen: Set<String> = []
        for edgeList in merged.adjacencyList {
            for edge in edgeList.edges {
                let key = "\(edge.from.index)->\(edge.to.index):\(edge.isDirected)"
                #expect(
                    seen.insert(key).inserted,
                    "Duplicate directed edge instance \(key)")
            }
        }
    }

    @Test
    func stitchingDoesNotJoinPerpendicularRoads() {
        let a = Coordinate3D(latitude: 0.0, longitude: -0.00005)
        let d = Coordinate3D(latitude: 0.0, longitude: 0.00005)
        let c = Coordinate3D(latitude: -0.00005, longitude: 0.00005)
        let e = Coordinate3D(latitude: 0.00005, longitude: 0.00005)

        var graph1 = Graph(nodeTolerance: 0.001)
        let a1 = graph1.createNode(at: a)
        let d1 = graph1.createNode(at: d)
        graph1.addUndirectedEdge(from: a1, to: d1)

        var graph2 = Graph(nodeTolerance: 0.001)
        let c2 = graph2.createNode(at: c)
        let e2 = graph2.createNode(at: e)
        graph2.addUndirectedEdge(from: c2, to: e2)

        let stitched = Graph.merged(
            [graph1, graph2],
            stitchingTolerance: 1.0)
        let unstitched = Graph.merged(
            [graph1, graph2],
            stitchingTolerance: 0.0)

        #expect(stitched.connectedComponents.count == 2)
        #expect(unstitched.connectedComponents.count == 2)
        #expect(stitched.edges.count == 2)
    }

    @Test
    func stitchingCanBeDisabled() {
        let a = Coordinate3D(latitude: 0.0, longitude: -0.00005)
        let d = Coordinate3D(latitude: 0.0, longitude: 0.00005)
        let c = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let e = Coordinate3D(latitude: 0.0, longitude: 0.0001)

        var graph1 = Graph(nodeTolerance: 0.001)
        let a1 = graph1.createNode(at: a)
        let d1 = graph1.createNode(at: d)
        graph1.addUndirectedEdge(from: a1, to: d1)

        var graph2 = Graph(nodeTolerance: 0.001)
        let c2 = graph2.createNode(at: c)
        let e2 = graph2.createNode(at: e)
        graph2.addUndirectedEdge(from: c2, to: e2)

        let merged = Graph.merged(
            [graph1, graph2],
            stitchingTolerance: 0.0)

        #expect(merged.connectedComponents.count == 2)
        #expect(merged.edges.count == 2)
    }

    // MARK: - Real network merge

    @Test
    func mergingImmenstadtNetworks() throws {
        let graph1 = try GraphTestHelper.immenstadtGraph()
        let graph2 = try GraphTestHelper.immenstadtGraph2()

        let merged = Graph.merged([graph1, graph2])

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
    func mergingEmptyArrayReturnsEmptyGraph() {
        let merged = Graph.merged([])
        #expect(merged.nodeCount == 0)
        #expect(merged.edges.isEmpty)
    }

    @Test
    func mergingWithEmptyGraph() {
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)

        let merged = Graph.merged([graph, Graph()])
        #expect(merged.nodeCount == 2)
        #expect(merged.edges.count == 1)
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

        let merged = Graph.merged([directed1, directed2])
        #expect(merged.isDirected)
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

        let merged = Graph.merged([undirected, directed])
        #expect(merged.isDirected, "Merged should be directed when one input is")
    }

    @Test
    func mergingManuallyDirectedEdgesProducesDirectedGraph() {
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addDirectedEdge(from: a, to: b, isDirected: true)

        let merged = Graph.merged([graph, Graph()])

        #expect(merged.isDirected)
        #expect(merged.hasDirectedEdges)
        #expect(merged.directedEdgeCount == 1)
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

            let merged = Graph.merged([graph1, graph2])
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

        let merged = Graph.merged([graph1, graph2])
        #expect(merged.nodeCount == 4)
        #expect(merged.edges.count == 2)
    }

    // MARK: - Connectivity preservation

    @Test
    func mergedGraphPreservesConnectivity() {
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

        var graph2 = Graph()
        let c2 = graph2.createNode(
            at: Coordinate3D(latitude: 10.0500001, longitude: 20.0000001))
        let d = graph2.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.0))
        graph2.addUndirectedEdge(from: c2, to: d)

        let merged = Graph.merged([graph1, graph2])
        #expect(merged.connectedComponents.count == 1,
                "Merged graph should be fully connected")

        let path = merged.shortestPath(
            from: merged.node(at: a.coordinate, tolerance: 5.0)!,
            to: merged.node(at: d.coordinate, tolerance: 5.0)!)
        #expect(path.isNotEmpty)
    }

    // MARK: - Multi-graph merge

    @Test
    func mergingThreeDisjointGraphs() {
        var g1 = Graph()
        let a1 = g1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b1 = g1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        g1.addUndirectedEdge(from: a1, to: b1)

        var g2 = Graph()
        let a2 = g2.createNode(
            at: Coordinate3D(latitude: 11.0, longitude: 21.0))
        let b2 = g2.createNode(
            at: Coordinate3D(latitude: 11.05, longitude: 21.05))
        g2.addUndirectedEdge(from: a2, to: b2)

        var g3 = Graph()
        let a3 = g3.createNode(
            at: Coordinate3D(latitude: 12.0, longitude: 22.0))
        let b3 = g3.createNode(
            at: Coordinate3D(latitude: 12.05, longitude: 22.05))
        g3.addUndirectedEdge(from: a3, to: b3)

        let merged = Graph.merged([g1, g2, g3])
        #expect(merged.nodeCount == 6)
        #expect(merged.edges.count == 3)
    }

    @Test
    func mergingThreeWithOverlap() {
        var g1 = Graph()
        let a = g1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = g1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        g1.addUndirectedEdge(from: a, to: b)

        var g2 = Graph()
        let b2 = g2.createNode(
            at: Coordinate3D(latitude: 10.0500001, longitude: 20.0500001))
        let c = g2.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        g2.addUndirectedEdge(from: b2, to: c)

        var g3 = Graph()
        let c3 = g3.createNode(
            at: Coordinate3D(latitude: 10.1000001, longitude: 20.1000001))
        let d = g3.createNode(
            at: Coordinate3D(latitude: 10.15, longitude: 20.15))
        g3.addUndirectedEdge(from: c3, to: d)

        let merged = Graph.merged([g1, g2, g3])
        #expect(merged.nodeCount == 4, "Should deduplicate b and c")
        #expect(merged.edges.count == 3, "Three edges forming chain")

        let path = merged.shortestPath(
            from: merged.node(at: a.coordinate, tolerance: 5.0)!,
            to: merged.node(at: d.coordinate, tolerance: 5.0)!)
        #expect(path.count == 4, "Expected 4-node chain, got \(path.count)")
    }

    @Test
    func mergingThreeDuplicateEdgeInAll() {
        var g1 = Graph()
        let a1 = g1.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b1 = g1.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        g1.addUndirectedEdge(from: a1, to: b1)

        var g2 = Graph()
        let a2 = g2.createNode(
            at: Coordinate3D(latitude: 10.0000001, longitude: 20.0000001))
        let b2 = g2.createNode(
            at: Coordinate3D(latitude: 10.0500001, longitude: 20.0500001))
        g2.addUndirectedEdge(from: a2, to: b2)

        var g3 = Graph()
        let a3 = g3.createNode(
            at: Coordinate3D(latitude: 10.0000002, longitude: 20.0000002))
        let b3 = g3.createNode(
            at: Coordinate3D(latitude: 10.0500002, longitude: 20.0500002))
        g3.addUndirectedEdge(from: a3, to: b3)

        let merged = Graph.merged([g1, g2, g3])
        #expect(merged.nodeCount == 2, "All nodes deduplicate to 2")
        #expect(merged.edges.count == 1, "Triple-duplicate edge → 1")
    }

    // MARK: - Instance method convenience

    @Test
    func instanceMergedWithDelegatesToStatic() {
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

        let viaStatic = Graph.merged([graph1, graph2])
        let viaInstance = graph1.merged(with: graph2)
        #expect(viaStatic.nodeCount == viaInstance.nodeCount)
        #expect(viaStatic.edges.count == viaInstance.edges.count)
    }

}
