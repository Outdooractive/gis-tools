#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph`` projection-coverage tests: construction, shortest path, and cycle
/// detection across EPSG:4326, EPSG:3857, EPSG:4978, and noSRID.
struct GraphProjectionTests {

    @Test
    func graphWorksAcrossProjections() throws {
        let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978, .noSRID]

        for projection in projections {
            let coords = [
                Coordinate3D(latitude: 10.0, longitude: 20.0).projected(to: projection),
                Coordinate3D(latitude: 10.1, longitude: 20.1).projected(to: projection),
                Coordinate3D(latitude: 10.1, longitude: 20.0).projected(to: projection),
            ]
            // Build a triangle directly (bypass the feature parser, which
            // expects 4326) to exercise the chosen projection.
            var graph = Graph(nodeTolerance: 1.0)
            let a = graph.createNode(at: coords[0])
            let b = graph.createNode(at: coords[1])
            let c = graph.createNode(at: coords[2])
            graph.addUndirectedEdge(from: a, to: b)
            graph.addUndirectedEdge(from: b, to: c)
            graph.addUndirectedEdge(from: c, to: a)

            #expect(graph.nodeCount == 3, "projection \(projection)")

            let path = graph.shortestPath(from: a, to: c)
            #expect(path.count == 2, "projection \(projection): \(path)")
            #expect(path.first == a)
            #expect(path.last == c)

            let cycles = graph.cycles(from: a)
            #expect(cycles.count == 1, "projection \(projection): \(cycles.count) cycles")
        }
    }

}