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
    func bfsCallbackVisitsAllNodes() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))

        var visited: [Int] = []
        graph.breadthFirstSearch(from: graph.nodes[0]) { node in
            visited.append(node.index)
            return true
        }
        #expect(visited == [0, 1, 2])
    }

    @Test
    func bfsCallbackStopsEarly() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))

        var visited: [Int] = []
        graph.breadthFirstSearch(from: graph.nodes[0]) { node in
            visited.append(node.index)
            return node.index != 1
        }
        // Should stop after visiting node 1; node 2 never reached.
        #expect(visited == [0, 1])
    }

    @Test
    func bfsCallbackInvalidNode() {
        let graph = Graph()
        let invalid = Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))
        var visited: [Int] = []
        graph.breadthFirstSearch(from: invalid) { node in
            visited.append(node.index)
            return true
        }
        #expect(visited.isEmpty)
    }

    @Test
    func dfsCallbackVisitsAllNodes() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))

        var visited: [Int] = []
        graph.depthFirstSearch(from: graph.nodes[0]) { node in
            visited.append(node.index)
            return true
        }
        #expect(visited == [0, 1, 2])
    }

    @Test
    func dfsCallbackStopsEarly() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))

        var visited: [Int] = []
        graph.depthFirstSearch(from: graph.nodes[0]) { node in
            visited.append(node.index)
            return node.index != 1
        }
        // DFS goes deep: visits 0, then 1, stops before 2.
        #expect(visited == [0, 1])
    }

    @Test
    func dfsCallbackInvalidNode() {
        let graph = Graph()
        let invalid = Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))
        var visited: [Int] = []
        graph.depthFirstSearch(from: invalid) { node in
            visited.append(node.index)
            return true
        }
        #expect(visited.isEmpty)
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

    // MARK: - Subgraph & connected component graphs

    @Test
    func connectedComponentGraphsCount() {
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
        let componentGraphs = graph.connectedComponentGraphs
        #expect(componentGraphs.count == 2)
        for component in componentGraphs {
            #expect(component.nodeCount == 2)
            #expect(component.directedEdgeCount == 2) // one undirected edge
        }
    }

    @Test
    func connectedComponentGraphsCoverAllNodes() {
        // Every node and edge from the original must end up in exactly one
        // component graph.
        let graph = Graph(featureCollection: FeatureCollection([
            Feature(LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
                Coordinate3D(latitude: 10.2, longitude: 20.2),
            ])!),
            Feature(LineString([
                Coordinate3D(latitude: 11.0, longitude: 21.0),
                Coordinate3D(latitude: 11.1, longitude: 21.1),
            ])!),
        ]))
        let componentGraphs = graph.connectedComponentGraphs
        var totalNodes = 0
        var totalEdges = 0
        for component in componentGraphs {
            totalNodes += component.nodeCount
            totalEdges += component.directedEdgeCount
        }
        #expect(totalNodes == graph.nodeCount)
        #expect(totalEdges == graph.directedEdgeCount)
    }

    @Test
    func connectedComponentGraphsEmpty() {
        let graph = Graph()
        #expect(graph.connectedComponentGraphs.isEmpty)
    }

    @Test
    func connectedComponentGraphsIsolatedNode() {
        // A single isolated node produces a single-node graph with no edges.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        let isolated = graph.createNode(at: Coordinate3D(latitude: 11.0, longitude: 21.0))

        let componentGraphs = graph.connectedComponentGraphs
        #expect(componentGraphs.count == 2)
        // Find the isolated component (1 node, 0 edges).
        let isolatedGraph = componentGraphs.first { $0.nodeCount == 1 }
        #expect(isolatedGraph != nil)
        #expect(isolatedGraph?.directedEdgeCount == 0)
        #expect(isolatedGraph?.nodes[0].coordinate == isolated.coordinate)
    }

    @Test
    func subgraphPreservesEdges() {
        // Triangle a-b-c-a; subgraph of [a, b] should have only the a-b edge.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: a)

        let sub = graph.subgraph(containing: [a, b])
        #expect(sub.nodeCount == 2)
        #expect(sub.directedEdgeCount == 2) // one undirected edge (a-b)
        // The c-a and b-c edges are dropped.
        #expect(sub.weight(from: sub.nodes[0], to: sub.nodes[1]) != nil)
    }

    @Test
    func subgraphPreservesWeightsAndFeatures() {
        // The subgraph must keep original edge weights and features.
        let feature = Feature(
            LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])!,
            properties: ["type": "primary"])
        let graph = Graph(featureCollection: FeatureCollection([feature]))
        let sub = graph.subgraph(containing: graph.nodes)
        #expect(sub.nodeCount == 2)
        let edgeFeature = sub.feature(from: sub.nodes[0], to: sub.nodes[1])
        let type: String? = edgeFeature?.property(for: "type")
        #expect(type == "primary")
        let originalWeight = graph.weight(from: graph.nodes[0], to: graph.nodes[1])!
        let subWeight = sub.weight(from: sub.nodes[0], to: sub.nodes[1])!
        #expect(abs(originalWeight - subWeight) < 0.001)
    }

    @Test
    func subgraphRemapsIndices() {
        // Subgraph node indices must be compact (0, 1, 2, …), not the original
        // indices.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.2, longitude: 20.2))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)

        // Subgraph of [b, c] (original indices 1, 2) should remap to 0, 1.
        let sub = graph.subgraph(containing: [b, c])
        #expect(sub.nodeCount == 2)
        #expect(sub.nodes[0].index == 0)
        #expect(sub.nodes[1].index == 1)
    }

    @Test
    func subgraphDuplicatesIgnored() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)

        let sub = graph.subgraph(containing: [a, a, b, b])
        #expect(sub.nodeCount == 2)
    }

    @Test
    func subgraphInvalidNodesSkipped() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let invalid = Node(index: 99, coordinate: Coordinate3D(latitude: 0, longitude: 0))

        let sub = graph.subgraph(containing: [a, invalid])
        #expect(sub.nodeCount == 1)
    }

    @Test
    func subgraphRoutingMatchesOriginal() {
        // A route within a subgraph should cost the same as the corresponding
        // route in the original graph.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let d = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: 20.15))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)

        let sub = graph.subgraph(containing: [a, b, c])
        let originalPath = graph.shortestPath(from: a, to: c)
        let subPath = sub.shortestPath(from: sub.nodes[0], to: sub.nodes[2])
        #expect(
            abs(graph.length(ofPath: originalPath) - sub.length(ofPath: subPath)) < 0.001,
            "Subgraph route cost should match original")
    }

}