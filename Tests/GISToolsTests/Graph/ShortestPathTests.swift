#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph/shortestPath(from:to:blockedNodes:edgeFilter:)`` tests on small
/// synthetic graphs.
struct ShortestPathTests {

    @Test
    func shortestPath() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let path = graph.shortestPath(from: graph.nodes[0], to: graph.nodes[2])
        #expect(path.count == 3)
        #expect(path[0].index == 0)
        #expect(path[2].index == 2)
    }

    @Test
    func shortestPathSameNode() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let path = graph.shortestPath(from: graph.nodes[0], to: graph.nodes[0])
        #expect(path.count == 1)
        #expect(path[0].index == 0)
    }

    @Test
    func shortestPathDisconnected() {
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
        let path = graph.shortestPath(from: graph.nodes[0], to: graph.nodes[2])
        #expect(path.isEmpty)
    }

    @Test
    func shortestPathWithBlockedNodes() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let blocked = Set([graph.nodes[1]])
        let path = graph.shortestPath(from: graph.nodes[0], to: graph.nodes[2], blockedNodes: blocked)
        #expect(path.isEmpty)
    }

    @Test
    func shortestPathInvalidNodes() {
        let graph = Graph()
        let a = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = Node(index: 1, coordinate: Coordinate3D(latitude: 10.1, longitude: 20.1))
        #expect(graph.shortestPath(from: a, to: b).isEmpty)
    }

    @Test
    func shortestPathWithBranch() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)

        let path = graph.shortestPath(from: a, to: c)
        #expect(path.count == 3)
        #expect(path[0].index == a.index)
        #expect(path[2].index == c.index)
    }

    @Test
    func shortestPathTakesShorterRoute() {
        // Square with a diagonal: a-b-c-d-a plus a-c. Shortest a->c is the diagonal.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.1))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let d = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.0))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)
        graph.addUndirectedEdge(from: d, to: a)
        graph.addUndirectedEdge(from: a, to: c) // diagonal shortcut

        let path = graph.shortestPath(from: a, to: c)
        #expect(path.count == 2, "Expected the diagonal shortcut: \(path)")
        #expect(path[0] == a)
        #expect(path[1] == c)
    }

}