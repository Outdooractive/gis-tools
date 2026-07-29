#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph`` manual edge manipulation tests: adding and removing directed and
/// undirected edges.
struct EdgeManipulationTests {

    @Test
    func addDirectedEdge() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addDirectedEdge(from: a, to: b)
        #expect(graph.degree(of: a) == 1)
        #expect(graph.degree(of: b) == 0)
    }

    @Test
    func removeDirectedEdge() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addDirectedEdge(from: a, to: b)
        graph.removeDirectedEdge(from: a, to: b)
        #expect(graph.degree(of: a) == 0)
    }

    @Test
    func removeDirectedEdgeNonExistent() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.removeDirectedEdge(from: a, to: b)
        graph.removeDirectedEdge(from: Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0)), to: b)
    }

    @Test
    func addUndirectedEdge() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        #expect(graph.degree(of: a) == 1)
        #expect(graph.degree(of: b) == 1)
    }

    @Test
    func removeUndirectedEdge() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        graph.removeUndirectedEdge(from: a, to: b)
        #expect(graph.degree(of: a) == 0)
        #expect(graph.degree(of: b) == 0)
    }

}