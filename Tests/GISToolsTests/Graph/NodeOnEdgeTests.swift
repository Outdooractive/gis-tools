#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph/nodeOnEdge(near:tolerance:)`` tests: splitting edges at the
/// perpendicular foot of a nearby coordinate.
struct NodeOnEdgeTests {

    @Test
    func nodeOnEdgeSplitsSegment() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.0002, longitude: 20.0002))
        graph.addUndirectedEdge(from: a, to: b)

        let nearMid = Coordinate3D(latitude: 10.0001, longitude: 20.0001)
        let inserted = graph.nodeOnEdge(near: nearMid, tolerance: 50.0)
        #expect(inserted != nil)
        // After splitting, a and b connect only to the inserted node, and the
        // inserted node connects to both (degree 2).
        #expect(graph.degree(of: a) == 1)
        #expect(graph.degree(of: b) == 1)
        #expect(graph.degree(of: inserted!) == 2)
        #expect(graph.nodeCount == 3)
    }

    @Test
    func nodeOnEdgeFarAway() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)

        let far = Coordinate3D(latitude: 50.0, longitude: 50.0)
        let inserted = graph.nodeOnEdge(near: far, tolerance: 1.0)
        #expect(inserted == nil)
    }

}