#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph`` node-query tests: lookup by coordinate/index, degree, neighbors.
struct NodeQueryTests {

    @Test
    func nodeAtCoordinate() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let node = graph.node(at: Coordinate3D(latitude: 10.0, longitude: 20.0), tolerance: 0.01)
        #expect(node != nil)
        #expect(node?.coordinate == coords[0])
    }

    @Test
    func nodeAtCoordinateOutsideTolerance() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let farAway = Coordinate3D(latitude: 10.5, longitude: 20.5)
        let node = graph.node(at: farAway, tolerance: 0.001)
        #expect(node == nil)
    }

    @Test
    func nodeWithIndex() {
        let coords = [Coordinate3D(latitude: 10.0, longitude: 20.0), Coordinate3D(latitude: 10.1, longitude: 20.1)]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        #expect(graph.node(withIndex: 0) != nil)
        #expect(graph.node(withIndex: 99) == nil)
        #expect(graph.node(withIndex: -1) == nil)
    }

    @Test
    func nodeCount() {
        let coords = [Coordinate3D(latitude: 10.0, longitude: 20.0), Coordinate3D(latitude: 10.1, longitude: 20.1)]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        #expect(graph.nodeCount == 2)
    }

    @Test
    func containsNode() {
        let coords = [Coordinate3D(latitude: 10.0, longitude: 20.0), Coordinate3D(latitude: 10.1, longitude: 20.1)]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        #expect(graph.contains(node: graph.nodes[0]))
        #expect(graph.contains(node: graph.nodes[1]))
        #expect(!graph.contains(node: Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))))
    }

    @Test
    func degree() {
        let coords = [Coordinate3D(latitude: 10.0, longitude: 20.0), Coordinate3D(latitude: 10.1, longitude: 20.1)]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        #expect(graph.degree(of: graph.nodes[0]) == 1)
        #expect(graph.degree(of: Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))) == 0)
    }

    @Test
    func neighbors() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let middle = graph.nodes[1]
        let neighbors = graph.neighbors(for: middle)
        #expect(neighbors.count == 2)
        #expect(neighbors.contains(where: { $0.index == 0 }))
        #expect(neighbors.contains(where: { $0.index == 2 }))
    }

    @Test
    func neighborsOfInvalidNode() {
        let coords = [Coordinate3D(latitude: 10.0, longitude: 20.0), Coordinate3D(latitude: 10.1, longitude: 20.1)]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let invalid = Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))
        #expect(graph.neighbors(for: invalid).isEmpty)
    }

}