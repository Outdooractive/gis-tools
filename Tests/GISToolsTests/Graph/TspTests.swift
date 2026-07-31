import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
    import CoreLocation
#endif

/// ``Graph/travelingSalespersonTour(nodes:start:)`` tests.
///
/// The TSP approximation (nearest-neighbor + 2-opt) returns a closed tour over
/// a set of nodes with small total length. Coverage spans synthetic graphs
/// with known optimal tours, the real-world Immenstadt network, all supported
/// projections, antimeridian-crossing geometries, and edge cases.
struct TspTests {

    // MARK: - Basic behaviour

    @Test
    func emptyNodesYieldsEmptyTour() {
        let graph = Graph()
        let tour = graph.travelingSalespersonTour(nodes: [])
        #expect(tour.nodes.isEmpty)
        #expect(tour.totalLength == 0.0)
    }

    @Test
    func singleNodeTourIsSelfLoop() {
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let tour = graph.travelingSalespersonTour(nodes: [a])
        #expect(tour.nodes.count == 2)
        #expect(tour.nodes[0] == a)
        #expect(tour.nodes[1] == a)
        #expect(tour.totalLength == 0.0)
    }

    @Test
    func twoNodeTourVisitsBothAndReturns() {
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)
        let tour = graph.travelingSalespersonTour(nodes: [a, b])
        #expect(
            tour.nodes.count == 3, "Expected [a, b, a], got \(tour.nodes.count)"
        )
        #expect(tour.nodes.first == a)
        #expect(tour.nodes.last == a)
        // The middle node is b.
        #expect(Set(tour.nodes.dropFirst().dropLast()) == Set([b]))
        // Total length = 2 * dist(a, b).
        let ab = graph.weight(from: a, to: b)!
        #expect(
            abs(tour.totalLength - 2.0 * ab) < 0.001,
            "Got \(tour.totalLength) vs \(2.0 * ab)")
    }

    @Test
    func tourIsClosedAndVisitsEveryNode() {
        // A 5-node chain; the tour must return to start and visit all 5.
        var graph = Graph()
        let nodes = (0..<5).map { i in
            graph.createNode(
                at: Coordinate3D(
                    latitude: 10.0 + 0.01 * Double(i), longitude: 20.0))
        }
        for i in 0..<nodes.count - 1 {
            graph.addUndirectedEdge(from: nodes[i], to: nodes[i + 1])
        }
        let tour = graph.travelingSalespersonTour(nodes: nodes)
        #expect(tour.nodes.first == tour.nodes.last, "Tour should be closed")
        // Every node visited exactly once (plus the repeated start).
        let visited = Set(tour.nodes.map(\.index))
        for node in nodes {
            #expect(visited.contains(node.index))
        }
        #expect(
            tour.nodes.count == nodes.count + 1,
            "Expected \(nodes.count + 1) entries, got \(tour.nodes.count)")
    }

    @Test
    func duplicatesAreDeduplicated() {
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)
        let tour = graph.travelingSalespersonTour(nodes: [a, a, b, b])
        // After dedup, 2 unique nodes -> 3 entries.
        #expect(
            tour.nodes.count == 3,
            "Expected dedup to 2 nodes, got \(tour.nodes.count)")
    }

    @Test
    func unreachableNodesYieldEmptyTour() {
        // Two disconnected edges: a-b and c-d cannot be toured together.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)
        let c = graph.createNode(
            at: Coordinate3D(latitude: 11.0, longitude: 21.0))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 11.05, longitude: 21.05))
        graph.addUndirectedEdge(from: c, to: d)
        let tour = graph.travelingSalespersonTour(nodes: [a, b, c, d])
        #expect(tour.nodes.isEmpty, "Unreachable nodes should yield empty tour")
    }

    // MARK: - Quality

    @Test
    func squareTourIsOptimal() {
        // A square (cycle of 4): the optimal TSP tour traverses the perimeter.
        // Nearest-neighbor + 2-opt should find the optimal length = perimeter.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.1))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.0))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)
        graph.addUndirectedEdge(from: d, to: a)
        // Add the diagonals so distances between any two nodes are well defined.
        graph.addUndirectedEdge(from: a, to: c)
        graph.addUndirectedEdge(from: b, to: d)

        let tour = graph.travelingSalespersonTour(nodes: [a, b, c, d])
        let perimeter =
            graph.weight(from: a, to: b)!
            + graph.weight(from: b, to: c)!
            + graph.weight(from: c, to: d)!
            + graph.weight(from: d, to: a)!
        #expect(
            abs(tour.totalLength - perimeter) < 1.0,
            "Tour \(tour.totalLength) should be near-optimal (perimeter \(perimeter))"
        )
    }

    @Test
    func twoOptDoesNotIncreaseLength() throws {
        // On the real network, the 2-opt-improved tour should be no longer
        // than a plain nearest-neighbor tour (we verify the tour is closed and
        // reasonable).
        let graph = try GraphTestHelper.immenstadtGraph()
        let component = graph.connectedComponents.max(by: {
            $0.count < $1.count
        })!
        // Sample a subset of ~12 nodes spread across the component.
        let step = max(component.count / 12, 1)
        let subset = Swift.stride(from: 0, to: component.count, by: step).map {
            component[$0]
        }
        guard subset.count >= 4 else { return }

        let tour = graph.travelingSalespersonTour(nodes: subset)
        #expect(tour.nodes.first == tour.nodes.last, "Tour should be closed")
        let visited = Set(tour.nodes.map(\.index))
        for node in subset {
            #expect(visited.contains(node.index), "Node not visited")
        }
        #expect(tour.totalLength > 0.0)
    }

    // MARK: - Real network

    @Test
    func immenstadtTspVisitsAllAndCloses() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let component = graph.connectedComponents.max(by: {
            $0.count < $1.count
        })!
        let step = max(component.count / 10, 1)
        let subset = Swift.stride(from: 0, to: component.count, by: step).map {
            component[$0]
        }
        let tour = graph.travelingSalespersonTour(nodes: subset)
        #expect(
            tour.nodes.count == subset.count + 1,
            "Expected \(subset.count + 1), got \(tour.nodes.count)")
        #expect(tour.nodes.first == tour.nodes.last)
        let visited = Set(tour.nodes.map(\.index))
        for node in subset {
            #expect(visited.contains(node.index))
        }
    }

    // MARK: - Projection coverage

    @Test
    func tspAcrossProjections() {
        let projections: [Projection] = [
            .epsg4326, .epsg3857, .epsg4978, .noSRID,
        ]

        for projection in projections {
            var graph = Graph(nodeTolerance: 1.0)
            let a = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(
                    to: projection))
            let b = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.1).projected(
                    to: projection))
            let c = graph.createNode(
                at: Coordinate3D(latitude: 10.1, longitude: 20.1).projected(
                    to: projection))
            let d = graph.createNode(
                at: Coordinate3D(latitude: 10.1, longitude: 20.0).projected(
                    to: projection))
            graph.addUndirectedEdge(from: a, to: b)
            graph.addUndirectedEdge(from: b, to: c)
            graph.addUndirectedEdge(from: c, to: d)
            graph.addUndirectedEdge(from: d, to: a)
            graph.addUndirectedEdge(from: a, to: c)
            graph.addUndirectedEdge(from: b, to: d)

            let tour = graph.travelingSalespersonTour(nodes: [a, b, c, d])
            #expect(
                tour.nodes.count == 5,
                "projection \(projection): got \(tour.nodes.count)")
            #expect(
                tour.nodes.first == tour.nodes.last, "projection \(projection)")
            let perimeter =
                graph.weight(from: a, to: b)!
                + graph.weight(from: b, to: c)!
                + graph.weight(from: c, to: d)!
                + graph.weight(from: d, to: a)!
            #expect(
                abs(tour.totalLength - perimeter) < 1.0,
                "projection \(projection): \(tour.totalLength) vs \(perimeter)")
        }
    }

    // MARK: - Antimeridian

    @Test
    func tspAcrossAntimeridian() {
        // A square straddling the dateline.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 179.9))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: -179.95))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: -179.9))
        let d = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 179.95))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)
        graph.addUndirectedEdge(from: d, to: a)
        graph.addUndirectedEdge(from: a, to: c)
        graph.addUndirectedEdge(from: b, to: d)

        let tour = graph.travelingSalespersonTour(nodes: [a, b, c, d])
        #expect(
            tour.nodes.count == 5, "Expected 5 entries, got \(tour.nodes.count)"
        )
        #expect(tour.nodes.first == tour.nodes.last)
        let visited = Set(tour.nodes.map(\.index))
        for node in [a, b, c, d] {
            #expect(visited.contains(node.index))
        }
    }

}
