#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph`` traversal tests: BFS, DFS, connected components, and node removal.
struct GraphTraversalTests {

    @Test
    func breadthFirstSearch() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let bfs = graph.breadthFirstSearch(from: graph.nodes[0])
        #expect(bfs.count == 3)
    }

    @Test
    func bfsInvalidNode() {
        let graph = Graph()
        let invalid = Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))
        #expect(graph.breadthFirstSearch(from: invalid).isEmpty)
    }

    @Test
    func depthFirstSearch() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let dfs = graph.depthFirstSearch(from: graph.nodes[0])
        #expect(dfs.count == 3)
    }

    @Test
    func dfsInvalidNode() {
        let graph = Graph()
        let invalid = Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))
        #expect(graph.depthFirstSearch(from: invalid).isEmpty)
    }

    @Test
    func connectedComponents() {
        let graph = Graph(featureCollection: FeatureCollection([
            Feature(LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!),
            Feature(LineString([
                Coordinate3D(latitude: 11.0, longitude: 21.0),
                Coordinate3D(latitude: 11.1, longitude: 21.1),
            ])!),
        ]))
        let components = graph.connectedComponents
        #expect(components.count == 2)
    }

    @Test
    func connectedComponentsSingle() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        #expect(graph.connectedComponents.count == 1)
    }

    @Test
    func connectedComponentsEmpty() {
        let graph = Graph()
        #expect(graph.connectedComponents.isEmpty)
    }

    @Test
    func removeNode() {
        var graph = Graph(featureCollection: FeatureCollection([
            Feature(LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
                Coordinate3D(latitude: 10.2, longitude: 20.2),
            ])!),
        ]))
        #expect(graph.nodeCount == 3)
        graph.removeNode(graph.nodes[1])
        #expect(graph.nodeCount == 3)
        #expect(graph.degree(of: graph.nodes[0]) == 0)
        #expect(graph.degree(of: graph.nodes[2]) == 0)
    }

    @Test
    func removeInvalidNode() {
        var graph = Graph()
        let invalid = Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))
        graph.removeNode(invalid)
    }

}