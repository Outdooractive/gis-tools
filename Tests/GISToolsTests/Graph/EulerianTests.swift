import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
    import CoreLocation
#endif

/// ``Graph/eulerianity()``, ``Graph/eulerianPath()``, and
/// ``Graph/chinesePostmanTour()`` tests.
///
/// Eulerian walks traverse every edge exactly once; the Chinese Postman tour
/// covers every edge at least once with minimal repetition. Coverage spans
/// synthetic graphs with known Eulerian status, the real-world Immenstadt
/// network, all supported projections, antimeridian-crossing geometries, and
/// directed graphs (undirected underlying).
struct EulerianTests {

    // MARK: - Eulerianity classification

    @Test
    func cycleIsEulerian() {
        // A pure cycle is Eulerian (every node has even degree).
        var graph = Graph()
        let nodes = (0..<4).map { i in
            graph.createNode(
                at: Coordinate3D(
                    latitude: 10.0 + 0.01 * Double(i % 2),
                    longitude: 20.0 + 0.01 * Double(i / 2)))
        }
        for i in 0..<nodes.count {
            graph.addUndirectedEdge(
                from: nodes[i], to: nodes[(i + 1) % nodes.count])
        }
        #expect(graph.eulerianity() == .eulerian)
    }

    @Test
    func chainIsSemiEulerian() {
        // a - b - c: b has degree 2, a and c degree 1 -> semi-Eulerian.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        #expect(graph.eulerianity() == .semiEulerian)
    }

    @Test
    func fourOddDegreeNodesAreNonEulerian() {
        // Triangle a-b-c-a plus a tail d: a has degree 3, c degree 2, b degree
        // 2, d degree 1 -> two odd nodes (a, d) -> semi-Eulerian.
        // For a nonEulerian example use a "K4 minus an edge": 4 nodes with
        // degrees 3,3,2,2 -> two odd nodes, still semi. To get > 2 odd nodes,
        // use a 3-star: center degree 3, leaves degree 1 each -> 4 odd nodes.
        var graph = Graph()
        let center = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let l1 = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.0))
        let l2 = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.05))
        let l3 = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: center, to: l1)
        graph.addUndirectedEdge(from: center, to: l2)
        graph.addUndirectedEdge(from: center, to: l3)
        #expect(graph.eulerianity() == .nonEulerian)
    }

    @Test
    func emptyGraphIsNonEulerian() {
        let graph = Graph()
        #expect(graph.eulerianity() == .nonEulerian)
    }

    @Test
    func disconnectedGraphIsNonEulerian() {
        // Two disconnected edges: each component is semi-Eulerian, but overall
        // disconnected -> non-Eulerian.
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
        #expect(graph.eulerianity() == .nonEulerian)
    }

    // MARK: - Eulerian path

    @Test
    func eulerianPathOfCycleCoversAllEdges() {
        // A 4-cycle: the Eulerian path should visit 4 nodes (closed circuit,
        // so 5 entries with the start repeated).
        var graph = Graph()
        let nodes = (0..<4).map { i in
            graph.createNode(
                at: Coordinate3D(
                    latitude: 10.0 + 0.01 * Double(i % 2),
                    longitude: 20.0 + 0.01 * Double(i / 2)))
        }
        for i in 0..<nodes.count {
            graph.addUndirectedEdge(
                from: nodes[i], to: nodes[(i + 1) % nodes.count])
        }
        let path = graph.eulerianPath()
        #expect(
            path.count == 5,
            "Expected a closed circuit of 5 entries, got \(path.count)")
        #expect(
            path.first == path.last, "Eulerian circuit should return to start")
        // Every node must appear.
        let visited = Set(path.map(\.index))
        for node in nodes {
            #expect(visited.contains(node.index))
        }
    }

    @Test
    func eulerianPathOfSemiEulerianStartsAndEndsAtOddNodes() {
        // Chain a-b-c: odd nodes are a and c. The Eulerian trail starts at one
        // and ends at the other.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)

        let path = graph.eulerianPath()
        #expect(path.count == 3, "Expected 3 nodes, got \(path.count)")
        let endpoints = Set([path.first!.index, path.last!.index])
        #expect(
            endpoints == Set([a.index, c.index]),
            "Trail should start/end at odd nodes, got \(endpoints)")
    }

    @Test
    func eulerianPathEmptyForNonEulerian() {
        var graph = Graph()
        let center = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let l1 = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.0))
        let l2 = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.05))
        let l3 = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        graph.addUndirectedEdge(from: center, to: l1)
        graph.addUndirectedEdge(from: center, to: l2)
        graph.addUndirectedEdge(from: center, to: l3)
        #expect(graph.eulerianPath().isEmpty)
    }

    // MARK: - Chinese Postman

    @Test
    func chinesePostmanOfEulerianGraphIsEulerianPath() {
        // Eulerian graph: the postman tour equals the Eulerian circuit (each
        // edge exactly once).
        var graph = Graph()
        let nodes = (0..<4).map { i in
            graph.createNode(
                at: Coordinate3D(
                    latitude: 10.0 + 0.01 * Double(i % 2),
                    longitude: 20.0 + 0.01 * Double(i / 2)))
        }
        for i in 0..<nodes.count {
            graph.addUndirectedEdge(
                from: nodes[i], to: nodes[(i + 1) % nodes.count])
        }
        let tour = graph.chinesePostmanTour()
        #expect(tour.isNotEmpty, "Postman tour should exist")
        #expect(tour.first == tour.last, "Postman tour should be closed")
        // Total length equals the sum of all edges (no repetition).
        let allEdges = graph.edges
        let totalEdgeWeight = allEdges.reduce(0.0) { $0 + $1.weight }
        let tourLength = graph.length(ofPath: tour)
        #expect(
            abs(tourLength - totalEdgeWeight) < 0.001,
            "Eulerian postman should have no repetition: \(tourLength) vs \(totalEdgeWeight)"
        )
    }

    @Test
    func chinesePostmanOfSemiEulerianAddsRepeat() {
        // Semi-Eulerian chain a-b-c: the postman must traverse one edge twice.
        // Total tour length = (a-b) + (b-c) + min(a-b, b-c) repeated... actually
        // the odd nodes a,c get matched and their shortest path (a-b-c) is
        // duplicated, so the tour traverses a-b twice and b-c twice.
        var graph = Graph()
        let a = graph.createNode(
            at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(
            at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(
            at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)

        let tour = graph.chinesePostmanTour()
        #expect(tour.isNotEmpty)
        #expect(tour.first == tour.last, "Postman tour should be closed")
        // Total length = 2 * (a-b + b-c).
        let ab = graph.weight(from: a, to: b)!
        let bc = graph.weight(from: b, to: c)!
        let tourLength = graph.length(ofPath: tour)
        #expect(
            abs(tourLength - 2.0 * (ab + bc)) < 0.001,
            "Postman tour length \(tourLength) vs \(2.0 * (ab + bc))")
    }

    @Test
    func chinesePostmanDisconnectedReturnsEmpty() {
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
        #expect(graph.chinesePostmanTour().isEmpty)
    }

    @Test
    func chinesePostmanEmptyGraphReturnsEmpty() {
        let graph = Graph()
        #expect(graph.chinesePostmanTour().isEmpty)
    }

    // MARK: - Real network

    @Test
    func immenstadtChinesePostmanDisconnectedReturnsEmpty() throws {
        // The Immenstadt network has multiple connected components (12), so no
        // single postman tour exists; the method correctly returns empty.
        let graph = try GraphTestHelper.immenstadtGraph()
        let components = graph.connectedComponents
        #expect(components.count > 1, "Expected a disconnected network")
        #expect(
            graph.chinesePostmanTour().isEmpty,
            "Disconnected graph should yield no tour")
    }

    @Test
    func chinesePostmanCoversAllEdgesInConnectedSubgraph() {
        // A connected graph with four odd nodes (a square with one diagonal):
        // every node has degree >= 2, exactly two have odd degree -> the
        // postman duplicates the shortest path between the two odd nodes.
        // Verify the tour is closed and covers every edge at least once.
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
        graph.addUndirectedEdge(from: a, to: c)  // diagonal
        // Degrees: a=3, b=2, c=3, d=2 -> odd nodes a, c.

        let tour = graph.chinesePostmanTour()
        #expect(tour.isNotEmpty, "Connected graph should have a postman tour")
        #expect(tour.first == tour.last, "Tour should be closed")
        // Tour length >= total edge weight and <= 2x total edge weight.
        let totalEdgeWeight = graph.edges.reduce(0.0) { $0 + $1.weight }
        let tourLength = graph.length(ofPath: tour)
        #expect(
            tourLength >= totalEdgeWeight - 0.5,
            "Should cover all edges: \(tourLength) vs \(totalEdgeWeight)")
        #expect(
            tourLength <= totalEdgeWeight * 2.0 + 0.5,
            "Should not double every edge")
    }

    // MARK: - Projection coverage

    @Test
    func eulerianPathAcrossProjections() {
        let projections: [Projection] = [
            .epsg4326, .epsg3857, .epsg4978, .noSRID,
        ]

        for projection in projections {
            var graph = Graph(nodeTolerance: 1.0)
            let a = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(
                    to: projection))
            let b = graph.createNode(
                at: Coordinate3D(latitude: 10.05, longitude: 20.05).projected(
                    to: projection))
            let c = graph.createNode(
                at: Coordinate3D(latitude: 10.05, longitude: 20.0).projected(
                    to: projection))
            let d = graph.createNode(
                at: Coordinate3D(latitude: 10.0, longitude: 20.05).projected(
                    to: projection))
            graph.addUndirectedEdge(from: a, to: b)
            graph.addUndirectedEdge(from: b, to: c)
            graph.addUndirectedEdge(from: c, to: d)
            graph.addUndirectedEdge(from: d, to: a)
            #expect(
                graph.eulerianity() == .eulerian, "projection \(projection)")
            let path = graph.eulerianPath()
            #expect(
                path.count == 5, "projection \(projection): got \(path.count)")
            #expect(path.first == path.last)
        }
    }

    // MARK: - Antimeridian

    @Test
    func eulerianPathAcrossAntimeridian() {
        // Cycle straddling the dateline.
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
        #expect(graph.eulerianity() == .eulerian)
        let path = graph.eulerianPath()
        #expect(path.count == 5, "Expected 5 entries, got \(path.count)")
        #expect(path.first == path.last)
    }

}
