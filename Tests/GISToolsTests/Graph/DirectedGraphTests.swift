#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph`` directed-support tests: one-way edges and traversal direction.
struct DirectedGraphTests {

    @Test
    func directedGraphOnewayEdge() {
        // Two features: a one-way road A->B and a two-way road B->A.
        let oneway = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!,
            properties: ["oneway": "1"])
        let twoway = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!)

        let directed = Graph(
            featureCollection: FeatureCollection([oneway, twoway]),
            isDirected: true)

        // In a directed graph, the oneway edge contributes one directed edge,
        // the twoway contributes two. Both share endpoints (merged), so the
        // graph has 2 nodes. Node a (index 0) has outgoing edges from both
        // features (2 outgoing); node b (index 1) has outgoing only from the
        // twoway feature (1 outgoing).
        #expect(directed.nodeCount == 2)
        #expect(directed.degree(of: directed.nodes[0]) == 2)
        #expect(directed.degree(of: directed.nodes[1]) == 1)
    }

    @Test
    func directedGraphOnewayNotTraversableAgainstDirection() {
        let oneway = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!,
            properties: ["oneway": "yes"])

        let directed = Graph(
            featureCollection: FeatureCollection([oneway]),
            isDirected: true)

        let a = directed.nodes[0]
        let b = directed.nodes[1]
        // Forward direction is reachable.
        #expect(directed.shortestPath(from: a, to: b).count == 2)
        // Reverse direction is not reachable (one-way).
        #expect(directed.shortestPath(from: b, to: a).isEmpty)
    }

    @Test
    func undirectedGraphIgnoresOneway() {
        let oneway = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!,
            properties: ["oneway": "yes"])

        let undirected = Graph(
            featureCollection: FeatureCollection([oneway]),
            isDirected: false)

        // In an undirected graph, the oneway tag is ignored; both directions
        // are reachable.
        let a = undirected.nodes[0]
        let b = undirected.nodes[1]
        #expect(undirected.shortestPath(from: a, to: b).count == 2)
        #expect(undirected.shortestPath(from: b, to: a).count == 2)
    }

}