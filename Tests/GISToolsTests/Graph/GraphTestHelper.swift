#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Shared helpers for the graph test suite.
enum GraphTestHelper {

    static func immenstadtCollection() throws -> FeatureCollection {
        try TestData.featureCollection(package: "Graph", name: "RoadNetwork_Immenstadt")
    }

    static func immenstadtGraph() throws -> Graph {
        Graph(featureCollection: try immenstadtCollection(), isDirected: false)
    }

    static func raplochCollection() throws -> FeatureCollection {
        try TestData.featureCollection(package: "Graph", name: "RoadNetwork_Raploch")
    }

    static func raplochGraph() throws -> Graph {
        Graph(featureCollection: try raplochCollection(), isDirected: false)
    }

    /// Finds a node near a feature tagged with `roundabout`.
    static func roundaboutNode(in graph: Graph) throws -> Node? {
        let collection = try immenstadtCollection()
        for feature in collection.features {
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

}