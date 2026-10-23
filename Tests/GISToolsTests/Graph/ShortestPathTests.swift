#if EnableGraphAPI
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

    // MARK: - Differential coverage

    /// Deterministic seeded graphs cross-checked against Floyd–Warshall.
    ///
    /// This is the audit oracle for all shortest-path entry points: Dijkstra,
    /// A*, bidirectional Dijkstra, the three contraction wrappers, the
    /// reusable routing index and ALT. For every ordered node pair the
    /// returned path must have exactly the reference shortest-path cost (or
    /// be empty when the pair is unreachable). Seeded LCG graphs cover
    /// undirected and one-way cases, cycles, parallel paths and degree-2
    /// chains; the previous contraction bugs (dropped incoming one-way edges,
    /// first-chain-wins parallel edges, and direction-blind chain expansion)
    /// all fail this test.
    struct LCG {

        var state: UInt64

        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }

        mutating func int(_ upperBound: Int) -> Int {
            Int(next() % UInt64(upperBound))
        }

        mutating func double() -> Double {
            Double(next() >> 11) / Double(1 << 53)
        }

    }

    func makeGraph(
        seed: UInt64,
        nodeCount: Int,
        edgeCount: Int,
        directed: Bool
    ) -> Graph {
        var rng = LCG(state: seed)
        var graph = Graph(nodeTolerance: 0.000001)
        var nodes: [Node] = []
        for index in 0 ..< nodeCount {
            let coordinate = Coordinate3D(
                latitude: Double(index / 4) * 0.01,
                longitude: Double(index % 4) * 0.01)
            nodes.append(graph.createNode(at: coordinate))
        }

        var pairs: Set<Int> = []
        for index in 1 ..< nodeCount {
            let other = rng.int(index)
            pairs.insert(min(index, other) * 1_000 + max(index, other))
            if directed, rng.double() < 0.3 {
                graph.addDirectedEdge(
                    from: nodes[index],
                    to: nodes[other],
                    isDirected: true)
            }
            else if directed, rng.double() < 0.3 {
                graph.addDirectedEdge(
                    from: nodes[other],
                    to: nodes[index],
                    isDirected: true)
            }
            else {
                graph.addUndirectedEdge(from: nodes[index], to: nodes[other])
            }
        }

        var attempts = 0
        while pairs.count < edgeCount, attempts < edgeCount * 20 {
            attempts += 1
            let a = rng.int(nodeCount)
            let b = rng.int(nodeCount)
            guard a != b else { continue }
            let key = min(a, b) * 1_000 + max(a, b)
            guard pairs.insert(key).inserted else { continue }
            if directed, rng.double() < 0.3 {
                graph.addDirectedEdge(
                    from: nodes[a],
                    to: nodes[b],
                    isDirected: true)
            }
            else {
                graph.addUndirectedEdge(from: nodes[a], to: nodes[b])
            }
        }
        return graph
    }

    func referenceDistances(_ graph: Graph) -> [[Double]] {
        let count = graph.nodeCount
        var distances = Array(
            repeating: Array(repeating: Double.infinity, count: count),
            count: count)
        for index in 0 ..< count {
            distances[index][index] = 0.0
        }
        for edge in graph.adjacencyList.flatMap(\.edges) {
            distances[edge.from.index][edge.to.index] = min(
                distances[edge.from.index][edge.to.index],
                edge.weight)
        }
        for k in 0 ..< count {
            for i in 0 ..< count {
                if distances[i][k] == .infinity { continue }
                for j in 0 ..< count {
                    let candidate = distances[i][k] + distances[k][j]
                    if candidate < distances[i][j] {
                        distances[i][j] = candidate
                    }
                }
            }
        }
        return distances
    }

    func pathCost(_ path: [Node], in graph: Graph) -> Double? {
        guard path.count > 1 else {
            return path.count == 1 ? 0.0 : nil
        }
        var total = 0.0
        for index in 1 ..< path.count {
            guard let weight = graph.weight(
                from: path[index - 1],
                to: path[index])
            else { return nil }
            total += weight
        }
        return total
    }

    @Test
    func randomGraphRoutingMatchesFloydWarshall() throws {
        for seed: UInt64 in 1 ... 40 {
            for directed in [false, true] {
                let graph = makeGraph(
                    seed: seed,
                    nodeCount: 8 + Int(seed % 5),
                    edgeCount: 12 + Int(seed % 6),
                    directed: directed)
                let reference = referenceDistances(graph)
                let index = graph.routingIndex()

                for source in graph.nodes {
                    for destination in graph.nodes {
                        let expected = reference[source.index][destination.index]
                        let paths: [(String, [Node])] = [
                            ("dijkstra", graph.shortestPath(from: source, to: destination)),
                            ("astar", graph.aStarPath(from: source, to: destination)),
                            ("bidirectional", graph.bidirectionalShortestPath(from: source, to: destination)),
                            ("contraction", graph.shortestPathViaContraction(from: source, to: destination)),
                            ("contractionAStar", graph.aStarPathViaContraction(from: source, to: destination)),
                            ("contractionBidi", graph.bidirectionalShortestPathViaContraction(from: source, to: destination)),
                            ("routingIndex", index?.shortestPath(from: source, to: destination) ?? []),
                        ]

                        for (name, path) in paths {
                            if expected == .infinity {
                                #expect(
                                    path.isEmpty,
                                    "seed \(seed) \(directed) \(name): \(source.index)->\(destination.index) expected unreachable")
                            }
                            else {
                                let cost = try #require(
                                    pathCost(path, in: graph),
                                    "seed \(seed) \(directed) \(name): invalid path \(source.index)->\(destination.index)")
                                #expect(
                                    abs(cost - expected) < 0.000001,
                                    "seed \(seed) \(directed) \(name): \(source.index)->\(destination.index) cost \(cost) != \(expected)")
                            }
                        }

                        if let landmarks = Graph.LandmarkIndex(graph) {
                            let path = landmarks.aStarPath(from: source, to: destination)
                            if expected == .infinity {
                                #expect(
                                    path.isEmpty,
                                    "seed \(seed) \(directed) alt: expected unreachable")
                            }
                            else {
                                let cost = try #require(
                                    pathCost(path, in: graph),
                                    "seed \(seed) \(directed) alt: invalid path")
                                #expect(
                                    abs(cost - expected) < 0.000001,
                                    "seed \(seed) \(directed) alt: \(source.index)->\(destination.index) cost \(cost) != \(expected)")
                            }
                        }
                    }
                }
            }
        }
    }

}
#endif
