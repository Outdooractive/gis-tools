#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Routing tests on the real-world Immenstadt road network: unfiltered road
/// paths plus hiking and cycling routes constrained by `edgeFilter`.
struct RoutingTests {

    @Test
    func roadNetworkPathExists() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        // Pick two far-apart nodes in the largest component.
        let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
        #expect(component.count > 50)

        let start = component.first!
        let end = component.last!
        let path = graph.shortestPath(from: start, to: end)
        #expect(path.count >= 2, "Expected a path between two nodes in the same component")
        #expect(path.first == start)
        #expect(path.last == end)

        let length = graph.length(ofPath: path)
        #expect(length > 0.0)
        print("Immenstadt road path: \(path.count) nodes, \(Int(length))m")
    }

    @Test
    func roadNetworkHikingPath() throws {
        let graph = try GraphTestHelper.immenstadtGraph()

        let hikingTypes: Set<String> = ["footway", "path", "track", "pedestrian", "steps"]
        let hikingFilter: (Edge) -> Bool = { edge in
            guard let type: String = edge.feature?.property(for: "type") else { return false }
            return hikingTypes.contains(type)
        }

        guard let (seed, reachable) = GraphTestHelper.largestFilteredComponent(
            in: graph,
            edgeFilter: hikingFilter)
        else {
            Issue.record("Hiking subgraph too small to test")
            return
        }

        // Pick the farthest reachable node by straight-line distance.
        let end = GraphTestHelper.farthestNode(from: seed, in: reachable) ?? reachable.last!
        let path = graph.shortestPath(from: seed, to: end, edgeFilter: hikingFilter)
        #expect(path.count >= 2, "Expected a hiking path")
        #expect(path.first == seed)
        #expect(path.last == end)

        for i in 1 ..< path.count {
            let edgeFeature = graph.feature(from: path[i - 1], to: path[i])
            let type: String? = edgeFeature?.property(for: "type")
            #expect(hikingTypes.contains(type ?? ""), "Non-hiking edge in hiking path: \(type ?? "nil")")
        }
        print("Immenstadt hiking path: \(path.count) nodes, \(Int(graph.length(ofPath: path)))m")
    }

    @Test
    func roadNetworkCyclingPath() throws {
        let graph = try GraphTestHelper.immenstadtGraph()

        // Cycling: cycleways + roads where cycling isn't forbidden.
        let roadTypes: Set<String> = ["cycleway", "residential", "primary", "secondary", "service", "living_street"]
        let cyclingFilter: (Edge) -> Bool = { edge in
            guard let type: String = edge.feature?.property(for: "type") else { return false }
            guard roadTypes.contains(type) else { return false }
            let bicycle: String? = edge.feature?.property(for: "bicycle")
            return bicycle != "no"
        }

        guard let (seed, reachable) = GraphTestHelper.largestFilteredComponent(
            in: graph,
            edgeFilter: cyclingFilter)
        else {
            Issue.record("Cycling subgraph too small to test")
            return
        }

        let end = GraphTestHelper.farthestNode(from: seed, in: reachable) ?? reachable.last!
        let path = graph.shortestPath(from: seed, to: end, edgeFilter: cyclingFilter)
        #expect(path.count >= 2, "Expected a cycling path")
        #expect(path.first == seed)
        #expect(path.last == end)

        for i in 1 ..< path.count {
            let edgeFeature = graph.feature(from: path[i - 1], to: path[i])
            let type: String? = edgeFeature?.property(for: "type")
            #expect(roadTypes.contains(type ?? ""), "Non-road edge in cycling path: \(type ?? "nil")")
            let bicycle: String? = edgeFeature?.property(for: "bicycle")
            #expect(bicycle != "no", "Cycling path uses a bicycle=no edge")
        }
        print("Immenstadt cycling path: \(path.count) nodes, \(Int(graph.length(ofPath: path)))m")
    }

}
