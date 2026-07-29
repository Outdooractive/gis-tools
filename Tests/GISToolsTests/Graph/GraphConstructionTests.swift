#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph`` construction tests: building from feature collections, node
/// merging, and tolerance behavior.
struct GraphConstructionTests {

    @Test
    func graphFromFeatureCollection() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let lineString = LineString(coords)!
        let feature = Feature(lineString)
        let collection = FeatureCollection([feature])
        let graph = Graph(featureCollection: collection)

        #expect(graph.nodeCount == 3)
        #expect(graph.edges.count == 2)
    }

    @Test
    func graphEmptyFeatureCollection() {
        let graph = Graph(featureCollection: FeatureCollection())
        #expect(graph.nodeCount == 0)
        #expect(graph.edges.isEmpty)
        #expect(graph.nodes.isEmpty)
    }

    @Test
    func graphSkipsNonLineString() {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let collection = FeatureCollection([Feature(point)])
        let graph = Graph(featureCollection: collection)
        #expect(graph.nodeCount == 0)
    }

    @Test
    func graphMultipleFeatures() {
        let coords1 = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let coords2 = [
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let features = [
            Feature(LineString(coords1)!),
            Feature(LineString(coords2)!),
        ]
        let graph = Graph(featureCollection: FeatureCollection(features))
        // The middle node is shared via 1m tolerance
        #expect(graph.nodeCount == 3)
        #expect(graph.edges.count == 2)
    }

    @Test
    func graphSkipsSelfEdge() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.0, longitude: 20.0),
        ]
        let lineString = LineString(coords)!
        let graph = Graph(featureCollection: FeatureCollection([Feature(lineString)]))
        #expect(graph.nodeCount == 1)
        #expect(graph.degree(of: graph.nodes[0]) == 0)
    }

    @Test
    func graphNodeToleranceMerging() {
        let shared = Coordinate3D(latitude: 10.0, longitude: 20.00001)
        let coords1 = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            shared,
        ]
        let coords2 = [
            shared,
            Coordinate3D(latitude: 10.0, longitude: 20.00002),
        ]
        let features = [
            Feature(LineString(coords1)!),
            Feature(LineString(coords2)!),
        ]
        var graph = Graph(featureCollection: FeatureCollection(features))
        #expect(graph.nodeCount == 3)

        let far1 = Coordinate3D(latitude: 10.0, longitude: 20.0001)
        let far2 = Coordinate3D(latitude: 10.0, longitude: 20.0002)
        let close1 = Coordinate3D(latitude: 10.0000005, longitude: 20.0)
        let close2 = Coordinate3D(latitude: 10.0000010, longitude: 20.0)
        graph = Graph(featureCollection: FeatureCollection([
            Feature(LineString([far1, close1])!),
            Feature(LineString([far2, close2])!),
        ]))
        #expect(graph.nodeCount == 3)

        graph = Graph(featureCollection: FeatureCollection([
            Feature(LineString([far1, close1])!),
            Feature(LineString([far2, close2])!),
        ]), nodeTolerance: 0.001)
        #expect(graph.nodeCount == 4)
    }

}