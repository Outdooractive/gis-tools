import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
    import CoreLocation
#endif

/// ``Graph/stronglyConnectedComponents()`` tests.
///
/// Strongly connected components (SCCs) find groups of mutually reachable nodes
/// in directed graphs. Coverage spans synthetic directed graphs with known
/// SCCs, the real-world Immenstadt network, all supported projections,
/// antimeridian-crossing geometries, and the undirected degenerate case.
struct StronglyConnectedComponentsTests {

    // MARK: - Basic detection

    @Test
    func directedCycleIsOneSCC() {
        // A -> B -> C -> A (one-way) is a single SCC.
        let cycle = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.0),
                Coordinate3D(latitude: 10.0, longitude: 20.0),
            ])!,
            properties: ["oneway": "yes"])
        let directed = Graph(
            featureCollection: FeatureCollection([cycle]), isDirected: true)

        let sccs = directed.stronglyConnectedComponents()
        #expect(sccs.count == 1, "Expected 1 SCC, got \(sccs.count)")
        #expect(sccs[0].count == 3)
    }

    @Test
    func directedDAGHasSingletonSCCs() {
        // A -> B -> C (one-way chain) has no return paths: 3 singleton SCCs.
        let chain = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!,
            properties: ["oneway": "yes"])
        let directed = Graph(
            featureCollection: FeatureCollection([chain]), isDirected: true)

        let sccs = directed.stronglyConnectedComponents()
        #expect(sccs.count == 3, "Expected 3 singleton SCCs, got \(sccs.count)")
        for scc in sccs {
            #expect(scc.count == 1)
        }
    }

    @Test
    func twoCyclesJoinedByOneWayEdge() {
        // Cycle 1: A->B->C->A. Cycle 2: D->E->F->D. One-way edge C->D joins
        // them (no return). Two SCCs of size 3 each.
        let cycle1 = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.0),
                Coordinate3D(latitude: 10.0, longitude: 20.0),
            ])!,
            properties: ["oneway": "yes"])
        let cycle2 = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.5),
                Coordinate3D(latitude: 10.05, longitude: 20.55),
                Coordinate3D(latitude: 10.1, longitude: 20.5),
                Coordinate3D(latitude: 10.0, longitude: 20.5),
            ])!,
            properties: ["oneway": "yes"])
        let link = Feature(
            LineString([
                Coordinate3D(latitude: 10.1, longitude: 20.0),
                Coordinate3D(latitude: 10.0, longitude: 20.5),
            ])!,
            properties: ["oneway": "yes"])

        let directed = Graph(
            featureCollection: FeatureCollection([cycle1, cycle2, link]),
            isDirected: true)

        let sccs = directed.stronglyConnectedComponents()
        #expect(sccs.count == 2, "Expected 2 SCCs, got \(sccs.count)")
        // Each SCC has 3 nodes.
        for scc in sccs {
            #expect(scc.count == 3)
        }
    }

    @Test
    func emptyGraphHasNoSCCs() {
        let graph = Graph()
        #expect(graph.stronglyConnectedComponents().isEmpty)
    }

    @Test
    func undirectedComponentsEqualSCCs() {
        // In an undirected graph, each connected component is one SCC.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)
        let c = graph.createNode(
            at: Coordinate3D(latitude: 11.0, longitude: 21.0))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 11.05, longitude: 21.05))
        graph.addUndirectedEdge(from: c, to: d)

        let sccs = graph.stronglyConnectedComponents()
        #expect(
            sccs.count == 2,
            "Expected 2 SCCs (one per component), got \(sccs.count)")
        for scc in sccs {
            #expect(scc.count == 2)
        }
    }

    // MARK: - Real network

    @Test
    func immenstadtSCCsCoverAllNodes() throws {
        // The Immenstadt graph is built undirected, so SCCs == connected
        // components; every node must appear in exactly one SCC.
        let graph = try GraphTestHelper.immenstadtGraph()
        let sccs = graph.stronglyConnectedComponents()
        var total = 0
        for scc in sccs {
            total += scc.count
        }
        #expect(
            total == graph.nodeCount,
            "SCCs must cover all nodes: \(total) vs \(graph.nodeCount)")
        // The largest component dominates.
        let largest = sccs.max(by: { $0.count < $1.count })!
        #expect(largest.count > 50)
    }

    // MARK: - Projection coverage

    @Test
    func sccsAcrossProjections() {
        let projections: [Projection] = [
            .epsg4326, .epsg3857, .epsg4978, .noSRID,
        ]

        for projection in projections {
            // Directed cycle (one SCC of 3) built directly in the projection.
            var graph = Graph(nodeTolerance: 1.0, isDirected: true)
            let a = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(
                    to: projection))
            let b = graph.createNode(
                at: Coordinate3D(latitude: 10.05, longitude: 20.05).projected(
                    to: projection))
            let c = graph.createNode(
                at: Coordinate3D(latitude: 10.1, longitude: 20.0).projected(
                    to: projection))
            graph.addDirectedEdge(from: a, to: b, isDirected: true)
            graph.addDirectedEdge(from: b, to: c, isDirected: true)
            graph.addDirectedEdge(from: c, to: a, isDirected: true)

            let sccs = graph.stronglyConnectedComponents()
            #expect(
                sccs.count == 1, "projection \(projection): got \(sccs.count)")
            #expect(sccs[0].count == 3)
        }
    }

    // MARK: - Antimeridian

    @Test
    func sccsAcrossAntimeridian() {
        // One-way cycle straddling the dateline: A(179.9) -> B(-179.95) ->
        // C(-179.9) -> A. Should be a single SCC.
        var graph = Graph(nodeTolerance: 1.0, isDirected: true)
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 179.9))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: -179.95))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: -179.9))
        graph.addDirectedEdge(from: a, to: b, isDirected: true)
        graph.addDirectedEdge(from: b, to: c, isDirected: true)
        graph.addDirectedEdge(from: c, to: a, isDirected: true)

        let sccs = graph.stronglyConnectedComponents()
        #expect(
            sccs.count == 1, "Expected 1 antimeridian SCC, got \(sccs.count)")
        #expect(sccs[0].count == 3)
    }

    // MARK: - SCC graphs

    @Test
    func sccGraphsCountMatchesComponents() {
        // Two cycles joined by a one-way edge: 2 SCCs of 3 nodes each.
        let cycle1 = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.0),
                Coordinate3D(latitude: 10.0, longitude: 20.0),
            ])!,
            properties: ["oneway": "yes"])
        let cycle2 = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.5),
                Coordinate3D(latitude: 10.05, longitude: 20.55),
                Coordinate3D(latitude: 10.1, longitude: 20.5),
                Coordinate3D(latitude: 10.0, longitude: 20.5),
            ])!,
            properties: ["oneway": "yes"])
        let link = Feature(
            LineString([
                Coordinate3D(latitude: 10.1, longitude: 20.0),
                Coordinate3D(latitude: 10.0, longitude: 20.5),
            ])!,
            properties: ["oneway": "yes"])

        let directed = Graph(
            featureCollection: FeatureCollection([cycle1, cycle2, link]),
            isDirected: true)

        let sccGraphs = directed.stronglyConnectedComponentGraphs()
        #expect(sccGraphs.count == 2, "Expected 2 SCC graphs, got \(sccGraphs.count)")
        for scc in sccGraphs {
            #expect(scc.nodeCount == 3)
        }
    }

    @Test
    func sccGraphsExcludeInterComponentEdges() {
        // The one-way link edge between the two cycles must NOT appear inside
        // either SCC graph (it's a condensation-DAG edge, not internal).
        let cycle1 = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.0),
                Coordinate3D(latitude: 10.0, longitude: 20.0),
            ])!,
            properties: ["oneway": "yes"])
        let cycle2 = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.5),
                Coordinate3D(latitude: 10.05, longitude: 20.55),
                Coordinate3D(latitude: 10.1, longitude: 20.5),
                Coordinate3D(latitude: 10.0, longitude: 20.5),
            ])!,
            properties: ["oneway": "yes"])
        let link = Feature(
            LineString([
                Coordinate3D(latitude: 10.1, longitude: 20.0),
                Coordinate3D(latitude: 10.0, longitude: 20.5),
            ])!,
            properties: ["oneway": "yes"])

        let directed = Graph(
            featureCollection: FeatureCollection([cycle1, cycle2, link]),
            isDirected: true)

        // The original has 3 features: 2 cycles (3 one-way edges each) + 1 link
        // = 7 directed edges total.
        let originalEdges = directed.directedEdgeCount
        #expect(originalEdges == 7)

        let sccGraphs = directed.stronglyConnectedComponentGraphs()
        var totalSccEdges = 0
        for scc in sccGraphs {
            totalSccEdges += scc.directedEdgeCount
        }
        // Each cycle contributes 3 one-way edges; the link is excluded.
        #expect(totalSccEdges == 6, "Inter-SCC link edge should be excluded, got \(totalSccEdges)")
    }

    @Test
    func sccGraphsCoverAllNodes() {
        // Every node must appear in exactly one SCC graph.
        let chain = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!,
            properties: ["oneway": "yes"])
        let directed = Graph(
            featureCollection: FeatureCollection([chain]),
            isDirected: true)

        let sccGraphs = directed.stronglyConnectedComponentGraphs()
        var totalNodes = 0
        for scc in sccGraphs {
            totalNodes += scc.nodeCount
        }
        #expect(totalNodes == directed.nodeCount, "SCC graphs must cover all nodes")
    }

    @Test
    func sccGraphsEmpty() {
        let graph = Graph()
        #expect(graph.stronglyConnectedComponentGraphs().isEmpty)
    }

    @Test
    func sccGraphsUndirectedEqualsComponentGraphs() {
        // In an undirected graph, SCC graphs == connected component graphs.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)
        let c = graph.createNode(at: Coordinate3D(latitude: 11.0, longitude: 21.0))
        let d = graph.createNode(at: Coordinate3D(latitude: 11.05, longitude: 21.05))
        graph.addUndirectedEdge(from: c, to: d)

        let sccGraphs = graph.stronglyConnectedComponentGraphs()
        let componentGraphs = graph.connectedComponentGraphs
        #expect(sccGraphs.count == componentGraphs.count)
        for (scc, component) in zip(sccGraphs, componentGraphs) {
            #expect(scc.nodeCount == component.nodeCount)
            #expect(scc.directedEdgeCount == component.directedEdgeCount)
        }
    }

}
