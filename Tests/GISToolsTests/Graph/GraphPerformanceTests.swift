#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Performance benchmarks for ``Graph``: construction, Dijkstra, cycle
/// detection, and traversal on the real-world Immenstadt road network, plus
/// synthetic worst-case graphs.
///
/// Marked `.serialized` so the benchmarks don't compete for CPU with each
/// other, which would skew timing measurements.
@Suite(.serialized)
struct GraphPerformanceTests {

    @Test
    func constructionPerformance() throws {
        let start = Date()
        let graph = try GraphTestHelper.immenstadtGraph()
        let elapsed = Date().timeIntervalSince(start)

        print("Immenstadt construction: \(graph.nodeCount) nodes, \(graph.edges.count) edges, \(elapsed)s")
        #expect(elapsed < 2.0, "Construction too slow: \(elapsed)s")
    }

    @Test
    func dijkstraPerformance() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
        // 100 random source/destination pairs within the largest component.
        let n = component.count
        var rng = SystemRandomNumberGenerator()
        let pairs = (0 ..< 100).map { _ -> (Node, Node) in
            let s = component[Int.random(in: 0 ..< n, using: &rng)]
            let d = component[Int.random(in: 0 ..< n, using: &rng)]
            return (s, d)
        }

        let start = Date()
        var pathCount = 0
        for (s, d) in pairs {
            if graph.shortestPath(from: s, to: d).isNotEmpty {
                pathCount += 1
            }
        }
        let elapsed = Date().timeIntervalSince(start)

        print("Immenstadt Dijkstra x100: \(pathCount)/100 found, \(elapsed)s")
        #expect(elapsed < 1.0, "100 Dijkstra queries too slow: \(elapsed)s")
    }

    @Test
    func cycleDetectionPerformance() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        // Find a few roundabout nodes to seed the search.
        let collection = try GraphTestHelper.immenstadtCollection()
        let roundaboutFeatures = collection.features.filter { feature in
            let s: String? = feature.property(for: "roundabout")
            let i: Int? = feature.property(for: "roundabout")
            return s == "yes" || s == "1" || s == "true" || i == 1
        }

        var seeds: [Node] = []
        for feature in roundaboutFeatures.prefix(5) {
            guard let ls = feature.geometry as? LineString,
                  let first = ls.coordinates.first
            else { continue }
            if let node = graph.node(at: first, tolerance: 5.0) {
                seeds.append(node)
            }
        }
        if seeds.isEmpty, let r = try GraphTestHelper.roundaboutNode(in: graph) {
            seeds.append(r)
        }

        let start = Date()
        var total = 0
        for seed in seeds.prefix(5) {
            let cycles = graph.cycles(
                from: seed,
                maximumPathLength: 250.0,
                maximumPathNodeCount: 150,
                maximumFromSourceDistance: 150.0)
            total += cycles.count
        }
        let elapsed = Date().timeIntervalSince(start)

        print("Immenstadt cycle detection (5 seeds): \(total) cycles, \(elapsed)s")
        #expect(elapsed < 5.0, "Cycle detection too slow: \(elapsed)s")
    }

    @Test
    func traversalPerformance() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
        let start = component.first!

        let bfsStart = Date()
        let bfs = graph.breadthFirstSearch(from: start)
        let bfsElapsed = Date().timeIntervalSince(bfsStart)

        let dfsStart = Date()
        let dfs = graph.depthFirstSearch(from: start)
        let dfsElapsed = Date().timeIntervalSince(dfsStart)

        print("Immenstadt BFS: \(bfs.count) nodes in \(bfsElapsed)s; DFS: \(dfs.count) in \(dfsElapsed)s")
        #expect(bfs.count == component.count)
        #expect(dfs.count == component.count)
        #expect(bfsElapsed < 1.0)
        #expect(dfsElapsed < 1.0)
    }

    @Test
    func shortestPathPerformanceSynthetic() {
        // A chain of 1000 nodes; Dijkstra must handle it quickly.
        var graph = Graph()
        var previous = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        for i in 1 ..< 1000 {
            let next = graph.createNode(at: Coordinate3D(
                latitude: 10.0 + Double(i) * 0.001,
                longitude: 20.0))
            graph.addUndirectedEdge(from: previous, to: next)
            previous = next
        }

        let start = graph.nodes[0]
        let end = graph.nodes[graph.nodeCount - 1]

        let startTime = Date()
        let path = graph.shortestPath(from: start, to: end)
        let elapsed = Date().timeIntervalSince(startTime)

        #expect(path.count == 1000)
        #expect(elapsed < 5.0, "Shortest path on 1000-node chain took too long: \(elapsed)s")
    }

    @Test
    func bfsPerformanceSynthetic() {
        var graph = Graph()
        var nodes: [Node] = []
        for i in 0 ..< 500 {
            let node = graph.createNode(at: Coordinate3D(
                latitude: 10.0 + Double(i) * 0.001,
                longitude: 20.0))
            nodes.append(node)
            if i > 0 {
                graph.addUndirectedEdge(from: nodes[i - 1], to: nodes[i])
            }
        }

        let visited = graph.breadthFirstSearch(from: nodes[0])
        #expect(visited.count == 500)
    }

}