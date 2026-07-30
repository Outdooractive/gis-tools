import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
    import CoreLocation
#endif

/// ``Graph/articulationPoints()`` tests.
///
/// Articulation points are nodes whose removal disconnects the graph
/// (critical intersections). Coverage spans synthetic graphs with known cut
/// vertices, the real-world Immenstadt network, all supported projections,
/// antimeridian-crossing geometries, and directed graphs.
struct ArticulationPointTests {

    // MARK: - Basic detection

    @Test
    func chainAllNodesExceptEndsAreCutVertices() {
        // a - b - c - d: b and c are articulation points.
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

        let cutVertices = Set(graph.articulationPoints().map(\.index))
        #expect(
            cutVertices == Set([b.index, c.index]),
            "Expected b,c, got \(cutVertices)")
    }

    @Test
    func cycleHasNoArticulationPoints() {
        // A pure cycle has no cut vertices.
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
        #expect(graph.articulationPoints().isEmpty)
    }

    @Test
    func centerOfStarIsCutVertex() {
        // Hub b connected to three leaves: b is the only articulation point.
        var graph = Graph()
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let l1 = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.0))
        let l2 = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.05))
        let l3 = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: b, to: l1)
        graph.addUndirectedEdge(from: b, to: l2)
        graph.addUndirectedEdge(from: b, to: l3)

        let cutVertices = Set(graph.articulationPoints().map(\.index))
        #expect(cutVertices == Set([b.index]))
    }

    @Test
    func emptyGraphHasNoCutVertices() {
        let graph = Graph()
        #expect(graph.articulationPoints().isEmpty)
    }

    @Test
    func bridgeJoiningTwoCyclesEndpointsAreCutVertices() {
        // Two cycles joined by edge c-d: c and d are both articulation points
        // (removing either disconnects the two cycles).
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.0))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.0))
        let e = graph.createNode(
            at: Coordinate3D(latitude: 10.15, longitude: 20.05))
        let f = graph.createNode(
            at: Coordinate3D(latitude: 10.15, longitude: 20.0))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: a)  // cycle 1
        graph.addUndirectedEdge(from: d, to: e)
        graph.addUndirectedEdge(from: e, to: f)
        graph.addUndirectedEdge(from: f, to: d)  // cycle 2
        graph.addUndirectedEdge(from: c, to: d)  // bridge

        let cutVertices = Set(graph.articulationPoints().map(\.index))
        #expect(
            cutVertices == Set([c.index, d.index]),
            "Expected c,d, got \(cutVertices)")
    }

    // MARK: - Real network

    @Test
    func immenstadtCutVerticesActuallyDisconnect() throws {
        // Every reported articulation point must, when removed, increase the
        // number of connected components.
        let graph = try GraphTestHelper.immenstadtGraph()
        let cutVertices = graph.articulationPoints()
        #expect(cutVertices.isNotEmpty, "Real network should have cut vertices")

        let originalComponentCount = graph.connectedComponents.count
        var verified = 0
        for node in cutVertices.prefix(20) {
            var modified = graph
            modified.removeNode(node)
            let newCount = modified.connectedComponents.count
            #expect(
                newCount > originalComponentCount,
                "Cut vertex removal did not disconnect: \(node.index)")
            verified += 1
        }
        #expect(verified > 0)
    }

    // MARK: - Projection coverage

    @Test
    func articulationPointsAcrossProjections() {
        let projections: [Projection] = [
            .epsg4326, .epsg3857, .epsg4978, .noSRID,
        ]

        for projection in projections {
            // Triangle (no cut vertices) + a leaf d hanging off a.
            var graph = Graph(nodeTolerance: 1.0)
            let a = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(
                    to: projection))
            let b = graph.createNode(
                at: Coordinate3D(latitude: 10.05, longitude: 20.05).projected(
                    to: projection))
            let c = graph.createNode(
                at: Coordinate3D(latitude: 10.05, longitude: 20.0).projected(
                    to: projection))
            let d = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.05).projected(
                    to: projection))
            graph.addUndirectedEdge(from: a, to: b)
            graph.addUndirectedEdge(from: b, to: c)
            graph.addUndirectedEdge(from: c, to: a)
            graph.addUndirectedEdge(from: a, to: d)

            let cutVertices = Set(graph.articulationPoints().map(\.index))
            #expect(
                cutVertices == Set([a.index]),
                "projection \(projection): got \(cutVertices)")
        }
    }

    // MARK: - Antimeridian

    @Test
    func articulationPointsAcrossAntimeridian() {
        // Two cycles straddling the dateline joined by a bridge; the bridge
        // endpoints are cut vertices.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 179.9))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: -179.95))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: -179.9))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 179.9))
        let e = graph.createNode(
            at: Coordinate3D(latitude: 10.15, longitude: -179.95))
        let f = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: -179.9))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: a)
        graph.addUndirectedEdge(from: d, to: e)
        graph.addUndirectedEdge(from: e, to: f)
        graph.addUndirectedEdge(from: f, to: d)
        graph.addUndirectedEdge(from: c, to: d)

        let cutVertices = Set(graph.articulationPoints().map(\.index))
        #expect(cutVertices == Set([c.index, d.index]))
    }

    // MARK: - Directed

    @Test
    func directedTwoWayChainCutVertices() {
        // Directed graph with a two-way chain a-b-c: b is a weak cut vertex.
        let chain = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.05, longitude: 20.05),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!)
        let directed = Graph(
            featureCollection: FeatureCollection([chain]),
            isDirected: true)

        let cutVertices = Set(directed.articulationPoints().map(\.index))
        // The middle node b is the weak cut vertex.
        #expect(
            cutVertices.count == 1,
            "Expected 1 weak cut vertex, got \(cutVertices)")
    }

}
