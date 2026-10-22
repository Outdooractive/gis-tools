#if EnableGraphAPI
import Foundation
@testable import GISTools
import Testing

/// ALT landmark routing index tests.
struct LandmarkIndexTests {

    @Test
    func emptyGraphHasNoIndex() {
        #expect(Graph().landmarkIndex() == nil)
    }

    @Test
    func directedLandmarkPathMatchesAStar() throws {
        var graph = Graph(isDirected: true)
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addDirectedEdge(from: a, to: b, isDirected: true)
        graph.addDirectedEdge(from: b, to: c, isDirected: true)

        let index = try #require(graph.landmarkIndex(landmarkCount: 2))
        let direct = graph.aStarPath(from: a, to: c)
        let landmark = index.aStarPath(from: a, to: c)

        #expect(landmark.first == a)
        #expect(landmark.last == c)
        #expect(abs(graph.length(ofPath: direct) - graph.length(ofPath: landmark)) < 0.001)
        #expect(index.aStarPath(from: c, to: a).isEmpty)
    }

    @Test
    func landmarkPathMatchesAStar() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let index = try #require(graph.landmarkIndex(landmarkCount: 4))
        let component = try #require(graph.connectedComponents.max(by: { $0.count < $1.count }))
        let start = try #require(component.first)
        let end = try #require(component.last)

        let direct = graph.aStarPath(from: start, to: end)
        let landmark = index.aStarPath(from: start, to: end)

        #expect(index.landmarkCount == 4)
        #expect(landmark.first == start)
        #expect(landmark.last == end)
        #expect(
            abs(graph.length(ofPath: direct) - graph.length(ofPath: landmark)) < 5.0
        )
    }

    @Test
    func landmarkPathWithEdgeFilter() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let index = try #require(graph.landmarkIndex(landmarkCount: 4))
        let hikingTypes: Set = ["footway", "path", "track", "pedestrian", "steps"]
        let filter: (Edge) -> Bool = { edge in
            guard let type: String = edge.feature?.property(for: "type") else { return false }

            return hikingTypes.contains(type)
        }

        let component = try #require(GraphTestHelper.largestFilteredComponent(
            in: graph,
            edgeFilter: filter))
        let end = GraphTestHelper.farthestNode(from: component.seed, in: component.reachable)
            ?? component.reachable.last!

        let direct = graph.aStarPath(
            from: component.seed,
            to: end,
            edgeFilter: filter)
        let landmark = index.aStarPath(
            from: component.seed,
            to: end,
            edgeFilter: filter)

        #expect(landmark.first == component.seed)
        #expect(landmark.last == end)
        #expect(
            abs(graph.length(ofPath: direct) - graph.length(ofPath: landmark)) < 5.0
        )
    }

    @Test
    func landmarkPathWithBlockedNode() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let index = try #require(graph.landmarkIndex(landmarkCount: 4))
        let component = try #require(graph.connectedComponents.max(by: { $0.count < $1.count }))
        let start = try #require(component.first)
        let blocked = component[component.count / 2]
        let end = try #require(component.last)

        let direct = graph.aStarPath(
            from: start,
            to: end,
            blockedNodes: Set([blocked]))
        let landmark = index.aStarPath(
            from: start,
            to: end,
            blockedNodes: Set([blocked]))

        #expect(landmark.first == start)
        #expect(landmark.last == end)
        #expect(
            abs(graph.length(ofPath: direct) - graph.length(ofPath: landmark)) < 5.0
        )
    }

    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func landmarkPathAcrossProjections(projection: Projection) throws {
        let coordinates = (0 ... 6).map { index in
            Coordinate3D(latitude: 10.0 + Double(index) * 0.01, longitude: 20.0)
                .projected(to: projection)
        }
        var graph = Graph(nodeTolerance: 1.0)
        let nodes = coordinates.map { graph.createNode(at: $0) }
        for index in 0 ..< nodes.count - 1 {
            graph.addUndirectedEdge(from: nodes[index], to: nodes[index + 1])
        }

        let index = graph.landmarkIndex(landmarkCount: 2)
        let start = try #require(nodes.first)
        let end = try #require(nodes.last)
        let direct = graph.aStarPath(from: start, to: end)
        let landmark = index?.aStarPath(from: start, to: end) ?? []

        #expect(landmark.first == start, "projection \(projection)")
        #expect(landmark.last == end, "projection \(projection)")
        #expect(
            abs(graph.length(ofPath: direct) - graph.length(ofPath: landmark)) < 0.001,
            "projection \(projection) route mismatch"
        )
    }

    @Test
    func landmarkPathAcrossAntimeridian() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.95))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
        let d = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.85))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)

        let index = graph.landmarkIndex(landmarkCount: 2)
        let direct = graph.aStarPath(from: a, to: d)
        let landmark = index?.aStarPath(from: a, to: d) ?? []

        #expect(landmark.first == a)
        #expect(landmark.last == d)
        #expect(abs(graph.length(ofPath: direct) - graph.length(ofPath: landmark)) < 1.0)
    }

}
#endif
