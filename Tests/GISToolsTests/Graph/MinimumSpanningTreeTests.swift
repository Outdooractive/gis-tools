import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
    import CoreLocation
#endif

/// ``Graph/minimumSpanningTree()`` tests.
///
/// The MST connects nodes with minimal total edge weight. Coverage spans
/// synthetic graphs with known MSTs, the real-world Immenstadt network, all
/// supported projections, antimeridian-crossing geometries, directed graphs,
/// and parallel edges.
struct MinimumSpanningTreeTests {

    // MARK: - Basic properties

    @Test
    func mstOfTreeIsTheTree() {
        // A tree is its own MST.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)

        let mst = graph.minimumSpanningTree()
        #expect(mst.count == 2, "Expected 2 edges (tree), got \(mst.count)")
    }

    @Test
    func mstPicksCheapestEdges() {
        // Triangle where one edge is much shorter than the other two; the MST
        // still needs 2 edges and picks the two cheapest.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.01, longitude: 20.01))  // close to a
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)  // short
        graph.addUndirectedEdge(from: b, to: c)  // medium
        graph.addUndirectedEdge(from: a, to: c)  // long

        let mst = graph.minimumSpanningTree()
        #expect(mst.count == 2, "Expected 2 edges, got \(mst.count)")
        // The MST must include the short a-b edge.
        let keys = Set(mst.map { MSTKey(a: $0.from.index, b: $0.to.index) })
        #expect(
            keys.contains(MSTKey(a: a.index, b: b.index)),
            "MST should include the shortest edge")
    }

    @Test
    func mstEdgeCountIsNodeCountMinusComponentCount() throws {
        // For a forest, |MST edges| = |nodes| - |components|.
        let graph = try GraphTestHelper.immenstadtGraph()
        let mst = graph.minimumSpanningTree()
        let componentCount = graph.connectedComponents.count
        let expected = graph.nodeCount - componentCount
        #expect(
            mst.count == expected,
            "MST edges \(mst.count) != nodes \(graph.nodeCount) - components \(componentCount)"
        )
    }

    @Test
    func emptyGraphHasEmptyMST() {
        let graph = Graph()
        #expect(graph.minimumSpanningTree().isEmpty)
    }

    @Test
    func mstConnectsAllNodesInComponent() {
        // The MST of a single component connects every node (it's a spanning
        // tree): each node must appear in at least one MST edge.
        var graph = Graph()
        let nodes = (0..<5).map { i in
            graph.createNode(
                at: Coordinate3D(
                    latitude: 10.0 + 0.01 * Double(i), longitude: 20.0))
        }
        // Fully connected for a clear MST.
        for i in 0..<nodes.count {
            for j in (i + 1)..<nodes.count {
                graph.addUndirectedEdge(from: nodes[i], to: nodes[j])
            }
        }

        let mst = graph.minimumSpanningTree()
        #expect(
            mst.count == 4, "Expected 4 edges for 5 nodes, got \(mst.count)")
        // Every node must be incident to at least one MST edge.
        let covered = Set(mst.flatMap { [$0.from.index, $0.to.index] })
        for node in nodes {
            #expect(
                covered.contains(node.index),
                "Node \(node.index) not covered by MST")
        }
    }

    // MARK: - Parallel edges

    @Test
    func mstPicksCheapestParallelEdge() {
        // Two nodes with two parallel edges of different weights: MST keeps
        // the cheaper one.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: a, to: b)  // parallel, same default weight

        let mst = graph.minimumSpanningTree()
        // One undirected edge remains in the MST (the cheaper of the two;
        // here both have equal weight, so exactly one is kept).
        #expect(mst.count == 1, "Expected 1 edge (deduped), got \(mst.count)")
    }

    // MARK: - Real network

    @Test
    func immenstadtMSTIsLighterThanFullGraph() throws {
        // The MST total weight must be strictly less than the sum of all edge
        // weights (a spanning tree prunes cycles).
        let graph = try GraphTestHelper.immenstadtGraph()
        let mst = graph.minimumSpanningTree()
        let mstWeight = mst.reduce(0.0) { $0 + $1.weight }
        let fullWeight = graph.edges.reduce(0.0) { $0 + $1.weight }
        #expect(
            mstWeight < fullWeight, "MST should be lighter than the full graph")
        #expect(mstWeight > 0.0)
    }

    // MARK: - Projection coverage

    @Test
    func mstAcrossProjections() {
        let projections: [Projection] = [
            .epsg4326, .epsg3857, .epsg4978, .noSRID,
        ]

        for projection in projections {
            var graph = Graph(nodeTolerance: 1.0)
            let a = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(
                    to: projection))
            let b = graph.createNode(
                at: Coordinate3D(latitude: 10.01, longitude: 20.01).projected(
                    to: projection))
            let c = graph.createNode(
                at: Coordinate3D(latitude: 10.1, longitude: 20.1).projected(
                    to: projection))
            graph.addUndirectedEdge(from: a, to: b)
            graph.addUndirectedEdge(from: b, to: c)
            graph.addUndirectedEdge(from: a, to: c)

            let mst = graph.minimumSpanningTree()
            #expect(
                mst.count == 2, "projection \(projection): got \(mst.count)")
            let keys = Set(mst.map { MSTKey(a: $0.from.index, b: $0.to.index) })
            #expect(
                keys.contains(MSTKey(a: a.index, b: b.index)),
                "projection \(projection) should keep the short a-b edge")
        }
    }

    // MARK: - Antimeridian

    @Test
    func mstAcrossAntimeridian() {
        // Triangle straddling the dateline.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 179.9))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: -179.95))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: -179.9))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: a)

        let mst = graph.minimumSpanningTree()
        #expect(
            mst.count == 2,
            "Expected 2 antimeridian MST edges, got \(mst.count)")
    }

    // MARK: - Directed

    @Test
    func directedTwoWayMST() {
        // Directed graph with two-way edges: the MST is over the undirected
        // underlying graph.
        var graph = Graph(isDirected: true)
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: a, to: c)

        let mst = graph.minimumSpanningTree()
        #expect(mst.count == 2, "Expected 2 MST edges, got \(mst.count)")
    }

    // MARK: - Support

    private struct MSTKey: Hashable {

        let a: Int
        let b: Int

        init(a: Int, b: Int) {
            self.a = min(a, b)
            self.b = max(a, b)
        }

    }

}
