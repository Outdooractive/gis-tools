#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Shared helpers for the graph test suite.
///
/// The Immenstadt and Raploch road-network graphs are parsed once and
/// reused across all tests. Because ``Graph`` is a value type, every test
/// that accesses the cached graph receives its own copy-on-write snapshot;
/// mutations made by individual tests never affect the shared fixture.
enum GraphTestHelper {

    private static let _immenstadtCollection: FeatureCollection = {
        try! TestData.featureCollection(package: "Graph", name: "RoadNetwork_Immenstadt")
    }()

    private static let _immenstadtGraph: Graph = {
        Graph(featureCollection: _immenstadtCollection, isDirected: false)
    }()

    private static let _raplochCollection: FeatureCollection = {
        try! TestData.featureCollection(package: "Graph", name: "RoadNetwork_Raploch")
    }()

    private static let _raplochGraph: Graph = {
        Graph(featureCollection: _raplochCollection, isDirected: false)
    }()

    private static let _immenstadtCollection2: FeatureCollection = {
        try! TestData.featureCollection(package: "Graph", name: "RoadNetwork_Immenstadt_2")
    }()

    private static let _immenstadtGraph2: Graph = {
        Graph(featureCollection: _immenstadtCollection2, isDirected: false)
    }()

    static func immenstadtCollection() throws -> FeatureCollection {
        _immenstadtCollection
    }

    static func immenstadtGraph() throws -> Graph {
        _immenstadtGraph
    }

    static func immenstadtGraph2() throws -> Graph {
        _immenstadtGraph2
    }

    static func raplochCollection() throws -> FeatureCollection {
        _raplochCollection
    }

    static func raplochGraph() throws -> Graph {
        _raplochGraph
    }

    /// Finds a node near a feature tagged with `roundabout` in the cached
    /// Immenstadt collection.
    static func roundaboutNode(in graph: Graph) throws -> Node? {
        for feature in _immenstadtCollection.features {
            let isRoundabout: Bool = {
                if let s: String = feature.property(for: "roundabout") {
                    return s == "yes" || s == "1" || s == "true"
                }
                if let i: Int = feature.property(for: "roundabout") { return i == 1 }
                return false
            }()
            guard isRoundabout,
                  let ls = feature.geometry as? LineString,
                  let first = ls.coordinates.first
            else { continue }
            if let node = graph.node(at: first, tolerance: 5.0) {
                return node
            }
        }
        return nil
    }

    /// BFS restricted to edges accepted by `edgeFilter`. Returns visited nodes
    /// in visit order.
    static func filteredBFS(
        from start: Node,
        in graph: Graph,
        edgeFilter: (Edge) -> Bool
    ) -> [Node] {
        var visited: Set<Int> = [start.index]
        var queue: [Int] = [start.index]
        var result: [Node] = [start]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            for edge in graph.edges(for: graph.node(withIndex: current)!) {
                if !edgeFilter(edge) { continue }
                if visited.insert(edge.to.index).inserted {
                    queue.append(edge.to.index)
                    result.append(edge.to)
                }
            }
        }
        return result
    }

    /// Finds a seed node in the largest filtered component by sampling
    /// candidate nodes and returning the one with the largest filtered BFS
    /// reachability, together with the reachable set.
    static func largestFilteredComponent(
        in graph: Graph,
        edgeFilter: (Edge) -> Bool,
        maxSamples: Int = 50,
        minComponentSize: Int = 2
    ) -> (seed: Node, reachable: [Node])? {
        var bestSeed: Node?
        var bestReachable: [Node] = []
        var sampled = 0
        for node in graph.nodes {
            guard graph.edges(for: node).contains(where: edgeFilter) else { continue }
            let reachable = filteredBFS(from: node, in: graph, edgeFilter: edgeFilter)
            if reachable.count > bestReachable.count {
                bestSeed = node
                bestReachable = reachable
            }
            sampled += 1
            if sampled >= maxSamples || bestReachable.count > 500 { break }
        }
        guard let seed = bestSeed, bestReachable.count >= minComponentSize else { return nil }
        return (seed, bestReachable)
    }

    /// Returns the node in `reachable` (excluding `seed`) that is farthest from
    /// `seed` by straight-line distance.
    static func farthestNode(from seed: Node, in reachable: [Node]) -> Node? {
        reachable.dropFirst().max(by: {
            $0.coordinate.distance(from: seed.coordinate) < $1.coordinate.distance(from: seed.coordinate)
        }) ?? reachable.last
    }

    /// Returns a connected subgraph of the Immenstadt road network bounded to
    /// roughly `maxNodes` nodes, built by BFS from the largest component's
    /// first node.
    ///
    /// The subgraph preserves real road-network topology while being small
    /// enough for expensive graph algorithms (e.g. betweenness centrality).
    static func immenstadtCore(maxNodes: Int = 500) throws -> Graph {
        let graph = _immenstadtGraph
        let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
        let seed = component.first!

        var visited: Set<Int> = [seed.index]
        var queue: [Int] = [seed.index]
        while !queue.isEmpty, visited.count < maxNodes {
            let current = queue.removeFirst()
            for edge in graph.edges(for: graph.node(withIndex: current)!) {
                if visited.insert(edge.to.index).inserted {
                    queue.append(edge.to.index)
                }
            }
        }

        return graph.subgraph(containing: visited)
    }

}
