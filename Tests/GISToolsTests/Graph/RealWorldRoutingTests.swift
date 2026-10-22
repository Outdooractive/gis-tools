#if EnableGraphAPI
import Foundation
@testable import GISTools
import Testing

/// Routing on the real-world Munich and Paris road tiles.
///
/// The tiles contain mixed OSM road classes, including footways, paths,
/// cycleways, residential roads and larger roads. Each profile must only use
/// edges that are appropriate for that mode of transport.
struct RealWorldRoutingTests {

    private enum Profiles {

        static func hiking(_ edge: Edge) -> Bool {
            guard let type: String = edge.feature?.property(for: "type"),
                  ["footway", "path", "track", "pedestrian", "steps"].contains(type)
            else { return false }

            let foot: String? = edge.feature?.property(for: "foot")
            let access: String? = edge.feature?.property(for: "access")
            return foot != "no" && access != "no" && access != "private"
        }

        static func cycling(_ edge: Edge) -> Bool {
            guard let type: String = edge.feature?.property(for: "type") else { return false }

            let bicycle: String? = edge.feature?.property(for: "bicycle")
            let access: String? = edge.feature?.property(for: "access")
            if bicycle == "no" || bicycle == "private" || access == "no" || access == "private" {
                return false
            }

            let roadTypes: Set = [
                "cycleway",
                "residential",
                "primary",
                "secondary",
                "tertiary",
                "service",
                "living_street",
                "track",
                "unclassified",
                "path",
                "footway",
            ]
            guard roadTypes.contains(type) else { return false }

            // Footways and paths are only cycling infrastructure when cycling
            // is explicitly allowed.
            if type == "footway" || type == "path" {
                return bicycle == "yes"
                    || bicycle == "designated"
                    || bicycle == "permissive"
                    || bicycle == "official"
            }
            return true
        }

        static func car(_ edge: Edge) -> Bool {
            guard let type: String = edge.feature?.property(for: "type") else { return false }

            let access: String? = edge.feature?.property(for: "access")
            if access == "no" || access == "private" {
                return false
            }

            let roadTypes: Set = [
                "motorway",
                "motorway_link",
                "trunk",
                "trunk_link",
                "primary",
                "primary_link",
                "secondary",
                "secondary_link",
                "tertiary",
                "tertiary_link",
                "residential",
                "service",
                "living_street",
                "unclassified",
            ]
            return roadTypes.contains(type)
        }

    }

    private static let allgaeuGraph: Graph = makeGraph(
        prefix: "allgaeu_",
        xRange: 8647 ... 8657,
        yRange: 5723 ... 5725)

    private static let munichGraph: Graph = makeGraph(
        prefix: "munich_",
        xRange: 8717 ... 8719,
        yRange: 5684 ... 5685)

    private static let parisGraph: Graph = makeGraph(
        prefix: "paris_",
        xRange: 8298 ... 8300,
        yRange: 5635 ... 5636)

    private static func makeGraph(
        prefix: String,
        xRange: ClosedRange<Int>,
        yRange: ClosedRange<Int>
    ) -> Graph {
        var graphs: [Graph] = []
        graphs.reserveCapacity(
            (xRange.upperBound - xRange.lowerBound + 1)
                * (yRange.upperBound - yRange.lowerBound + 1))

        for x in xRange {
            for y in yRange {
                let collection = try! TestData.featureCollection(
                    package: "Graph",
                    name: "\(prefix)14_\(x)_\(y)")
                graphs.append(Graph(featureCollection: collection))
            }
        }

        return Graph.merged(graphs)
    }

    @Test
    func allgaeuCyclingRoute() {
        assertRoute(
            in: Self.allgaeuGraph,
            filter: Profiles.cycling,
            label: "Allgäu cycling",
            minimumLength: 20000.0,
            waypointCount: 2)
    }

    @Test
    func allgaeuHikingRoute() {
        assertRoute(
            in: Self.allgaeuGraph,
            filter: Profiles.hiking,
            label: "Allgäu hiking",
            minimumLength: 20000.0,
            waypointCount: 2)
    }

    @Test
    func allgaeuCarRouteLeftToRight() {
        assertRoute(
            in: Self.allgaeuGraph,
            filter: Profiles.car,
            label: "Allgäu car left-to-right",
            minimumLength: 10000.0,
            westToEast: true)
    }

    @Test
    func munichLandmarkMatchesAStar() throws {
        let component = try #require(
            Self.munichGraph.connectedComponents.max(by: { $0.count < $1.count }))
        let start = component.first!
        let end = component.last!
        let index = try #require(Self.munichGraph.landmarkIndex(landmarkCount: 4))

        let direct = Self.munichGraph.aStarPath(from: start, to: end)
        let landmark = index.aStarPath(from: start, to: end)

        #expect(landmark.first == start)
        #expect(landmark.last == end)
        #expect(
            abs(Self.munichGraph.length(ofPath: direct)
                - Self.munichGraph.length(ofPath: landmark)) < 5.0)
    }

    @Test
    func munichHikingRoute() {
        assertRoute(
            in: Self.munichGraph,
            filter: Profiles.hiking,
            label: "Munich hiking",
            minimumLength: 20000.0,
            waypointCount: 4)
    }

    @Test
    func munichCyclingRoute() {
        assertRoute(
            in: Self.munichGraph,
            filter: Profiles.cycling,
            label: "Munich cycling",
            minimumLength: 20000.0,
            waypointCount: 4)
    }

    @Test
    func munichCarRoute() {
        assertRoute(
            in: Self.munichGraph,
            filter: Profiles.car,
            label: "Munich car",
            minimumLength: 20000.0,
            waypointCount: 4)
    }

    @Test
    func parisLandmarkMatchesAStar() throws {
        let component = try #require(
            Self.parisGraph.connectedComponents.max(by: { $0.count < $1.count }))
        let start = component.first!
        let end = component.last!
        let index = try #require(Self.parisGraph.landmarkIndex(landmarkCount: 4))

        let direct = Self.parisGraph.aStarPath(from: start, to: end)
        let landmark = index.aStarPath(from: start, to: end)

        #expect(landmark.first == start)
        #expect(landmark.last == end)
        #expect(
            abs(Self.parisGraph.length(ofPath: direct)
                - Self.parisGraph.length(ofPath: landmark)) < 5.0)
    }

    @Test
    func parisHikingRoute() {
        assertRoute(
            in: Self.parisGraph,
            filter: Profiles.hiking,
            label: "Paris hiking",
            minimumLength: 20000.0,
            waypointCount: 4)
    }

    @Test
    func parisCyclingRoute() {
        assertRoute(
            in: Self.parisGraph,
            filter: Profiles.cycling,
            label: "Paris cycling",
            minimumLength: 20000.0,
            waypointCount: 4)
    }

    @Test
    func parisCarRoute() {
        assertRoute(
            in: Self.parisGraph,
            filter: Profiles.car,
            label: "Paris car",
            minimumLength: 20000.0,
            waypointCount: 4)
    }

    private func largestFilteredComponent(
        in graph: Graph,
        filter: (Edge) -> Bool
    ) -> (seed: Node, reachable: [Node])? {
        var visited: Set<Int> = []
        var best: (seed: Node, reachable: [Node])?

        for node in graph.nodes where !visited.contains(node.index) {
            visited.insert(node.index)

            var component: [Node] = [node]
            var queue: [Node] = [node]

            while let current = queue.popLast() {
                for edge in graph.edges(for: current) where filter(edge) {
                    guard visited.insert(edge.to.index).inserted else { continue }

                    queue.append(edge.to)
                    component.append(edge.to)
                }
            }

            if let current = best {
                if component.count > current.reachable.count {
                    best = (node, component)
                }
            }
            else {
                best = (node, component)
            }
        }

        guard let best, best.reachable.count >= 2 else { return nil }

        return best
    }

    private func assertRoute(
        in graph: Graph,
        filter: @escaping (Edge) -> Bool,
        label: String,
        minimumLength: Double = 0.0,
        waypointCount: Int = 0,
        westToEast: Bool = false
    ) {
        guard let (seed, reachable) = largestFilteredComponent(
            in: graph,
            filter: filter)
        else {
            Issue.record("\(label): filtered network is too small")
            return
        }

        var nodes: [Node] = [seed]
        if westToEast {
            let west = reachable.min {
                $0.coordinate.longitude < $1.coordinate.longitude
            }
            let east = reachable.max {
                $0.coordinate.longitude < $1.coordinate.longitude
            }
            if let west, let east, west != east {
                nodes = [west, east]
            }
        }
        else if waypointCount > 0 {
            let north = reachable.max {
                $0.coordinate.latitude < $1.coordinate.latitude
            }
            let south = reachable.min {
                $0.coordinate.latitude < $1.coordinate.latitude
            }
            let east = reachable.max {
                $0.coordinate.longitude < $1.coordinate.longitude
            }
            let west = reachable.min {
                $0.coordinate.longitude < $1.coordinate.longitude
            }
            let extremes = [north, south, east, west]

            for waypoint in extremes.prefix(waypointCount).compactMap({ $0 }) {
                if nodes.last != waypoint {
                    nodes.append(waypoint)
                }
            }
        }

        if let end = GraphTestHelper.farthestNode(from: seed, in: reachable),
           nodes.last != end
        {
            nodes.append(end)
        }

        guard nodes.count >= 2 else {
            Issue.record("\(label): no destination node")
            return
        }

        var path: [Node] = []
        for index in 1 ..< nodes.count {
            let segment = graph.shortestPath(
                from: nodes[index - 1],
                to: nodes[index],
                edgeFilter: filter)
            guard segment.count >= 2 else {
                Issue.record("\(label): no route between intermediate points")
                return
            }

            if path.isEmpty {
                path = segment
            }
            else {
                path.append(contentsOf: segment.dropFirst())
            }
        }

        #expect(path.count >= 2, "\(label): expected a path")
        guard path.count >= 2 else { return }

        for index in 1 ..< path.count {
            let from = path[index - 1]
            let to = path[index]
            guard let edge = graph.edges(for: from).first(where: { $0.to == to }) else {
                Issue.record("\(label): missing edge \(from.index) -> \(to.index)")
                continue
            }

            let type: String? = edge.feature?.property(for: "type")
            #expect(
                filter(edge),
                "\(label): path uses an unsuitable edge of type \(type ?? "nil")"
            )
        }

        let length = graph.length(ofPath: path)
        #expect(
            length >= minimumLength,
            "\(label): expected at least \(Int(minimumLength))m, got \(Int(length))m"
        )
        print("\(label): \(path.count) nodes, \(Int(length))m")
    }

}
#endif
