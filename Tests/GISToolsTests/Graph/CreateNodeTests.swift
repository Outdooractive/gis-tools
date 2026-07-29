#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph/createNode(at:)`` and copy-on-write semantics tests.
struct CreateNodeTests {

    @Test
    func createNodeReturnsExistingAtSameLocation() {
        var graph = Graph()
        let coord = Coordinate3D(latitude: 10.0, longitude: 20.0)
        let first = graph.createNode(at: coord)
        let second = graph.createNode(at: coord)
        #expect(first == second)
        #expect(graph.nodeCount == 1)
    }

    @Test
    func createNodeReturnsExistingWithinTolerance() {
        var graph = Graph()
        let coord1 = Coordinate3D(latitude: 10.0000005, longitude: 20.0)
        let coord2 = Coordinate3D(latitude: 10.0000010, longitude: 20.0)
        let first = graph.createNode(at: coord1)
        let second = graph.createNode(at: coord2)
        #expect(first == second)
        #expect(graph.nodeCount == 1)
    }

    @Test
    func createNodeOutsideTolerance() {
        var graph = Graph()
        let coord1 = Coordinate3D(latitude: 10.0, longitude: 20.0)
        let coord2 = Coordinate3D(latitude: 10.0, longitude: 21.0)
        let first = graph.createNode(at: coord1)
        let second = graph.createNode(at: coord2)
        #expect(first != second)
        #expect(graph.nodeCount == 2)
    }

    @Test
    func graphCopyOnWrite() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let original = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        var copy = original
        #expect(copy.nodeCount == original.nodeCount)

        copy.createNode(at: Coordinate3D(latitude: 10.2, longitude: 20.2))
        #expect(copy.nodeCount == 3)
        #expect(original.nodeCount == 2)
    }

}