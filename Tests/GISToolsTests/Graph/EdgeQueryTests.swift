#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph`` edge-query tests: incident edges, weights, features, counts.
struct EdgeQueryTests {

    @Test
    func edgesForNode() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let middleEdges = graph.edges(for: graph.nodes[1])
        #expect(middleEdges.count == 2)
    }

    @Test
    func edgesForInvalidNode() {
        let graph = Graph(featureCollection: FeatureCollection())
        let invalid = Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))
        #expect(graph.edges(for: invalid).isEmpty)
    }

    @Test
    func weightQuery() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let w = graph.weight(from: graph.nodes[0], to: graph.nodes[1])
        #expect(w != nil)
        #expect(w! > 0.0)
        let wRev = graph.weight(from: graph.nodes[1], to: graph.nodes[0])
        #expect(wRev == w)
        #expect(graph.weight(from: graph.nodes[0], to: Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))) == nil)
    }

    @Test
    func featureQuery() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let lineString = LineString(coords)!
        let feature = Feature(lineString)
        let graph = Graph(featureCollection: FeatureCollection([feature]))
        let f = graph.feature(from: graph.nodes[0], to: graph.nodes[1])
        #expect(f != nil)
    }

    @Test
    func directedEdgeCount() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        #expect(graph.directedEdgeCount == 2)
    }

}