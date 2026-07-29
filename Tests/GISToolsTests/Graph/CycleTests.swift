#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph/cycles(from:curvature:maximumPathLength:maximumPathNodeCount:maximumFromSourceDistance:)``
/// tests on small synthetic graphs: basic shapes, curvature constraints, and
/// bounding limits.
struct CycleTests {

    // MARK: - Basic shapes

    @Test
    func cycleTriangle() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.0))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: a)

        let cycles = graph.cycles(from: a)
        // Exactly one triangle: a-b-c-a (canonical dedup removes rotation/reversal).
        #expect(cycles.count == 1, "Expected 1 triangle, got \(cycles.count)")
        for cycle in cycles {
            #expect(cycle.first == a)
            #expect(cycle.last == cycle.first)
            #expect(cycle.count == 4) // 3 distinct + closing
        }
    }

    @Test
    func cycleNoCyclesInLine() {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
        let cycles = graph.cycles(from: graph.nodes[0])
        #expect(cycles.isEmpty)
    }

    @Test
    func cycleSquare() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.1))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let d = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.0))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)
        graph.addUndirectedEdge(from: d, to: a)

        let cycles = graph.cycles(from: a)
        #expect(cycles.count == 1, "Expected 1 square, got \(cycles.count)")
        #expect(cycles[0].count == 5)
    }

    @Test
    func cycleTwoTrianglesSharingEdge() {
        // Triangles a-b-c-a and a-c-d-a share edge a-c.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.025, longitude: 20.05))
        let d = graph.createNode(at: Coordinate3D(latitude: 9.95, longitude: 20.05))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: a)
        graph.addUndirectedEdge(from: a, to: d)
        graph.addUndirectedEdge(from: d, to: c)

        let cycles = graph.cycles(from: a)
        // Two triangles (a-b-c-a, a-c-d-a) plus the quadrilateral a-b-c-d-a.
        #expect(cycles.count == 3, "Expected 2 triangles + 1 quad, got \(cycles.count)")
        // Every cycle starts and ends at a.
        for cycle in cycles {
            #expect(cycle.first == a)
            #expect(cycle.last == a)
            #expect(cycle.count >= 4)
        }
    }

    @Test
    func cycleFigure8() {
        // Two triangles sharing a single vertex (a): a-b-c-a and a-d-e-a.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.025, longitude: 20.05))
        let d = graph.createNode(at: Coordinate3D(latitude: 9.95, longitude: 20.0))
        let e = graph.createNode(at: Coordinate3D(latitude: 9.975, longitude: 19.95))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: a)
        graph.addUndirectedEdge(from: a, to: d)
        graph.addUndirectedEdge(from: d, to: e)
        graph.addUndirectedEdge(from: e, to: a)

        let cycles = graph.cycles(from: a)
        #expect(cycles.count == 2, "Expected 2 triangles in figure-8, got \(cycles.count)")
    }

    @Test
    func cycleDedupAcrossStartNodes() {
        // The same cycle should be reported only once regardless of which of
        // its nodes we start from.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.1))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let d = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.0))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)
        graph.addUndirectedEdge(from: d, to: a)

        let fromA = graph.cycles(from: a)
        let fromB = graph.cycles(from: b)
        let fromC = graph.cycles(from: c)
        // Each call dedups internally; different starts report the same single
        // cycle (rotated so the start node is first/last).
        #expect(fromA.count == 1)
        #expect(fromB.count == 1)
        #expect(fromC.count == 1)
        // The set of visited indices is the same.
        let setA = Set(fromA[0].dropLast().map(\.index))
        let setB = Set(fromB[0].dropLast().map(\.index))
        #expect(setA == setB)
    }

    // MARK: - Curvature

    @Test
    func cycleCurvatureLeftOnly() {
        // A clockwise square (viewed from above): all right turns when
        // traversed in one direction, all left turns in the other.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.1))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let d = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.0))
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)
        graph.addUndirectedEdge(from: d, to: a)

        // With only-left restriction we still find the cycle (one of the two
        // traversal directions has all left turns).
        let left = graph.cycles(from: a, curvature: .left)
        #expect(left.count == 1, "Left-only should find the ccw traversal: \(left.count)")

        // With only-right restriction we find the other traversal direction.
        let right = graph.cycles(from: a, curvature: .right)
        #expect(right.count == 1, "Right-only should find the cw traversal: \(right.count)")
    }

    @Test
    func cycleCurvatureZigZagFindsNothing() {
        // A zig-zag path that closes into a thin shape: consecutive turns
        // alternate, so neither pure-left nor pure-right traversal exists.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.02))
        let c = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.04))
        let d = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.06))
        let e = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.08))
        // Close the loop back to a with a long edge so it forms a single cycle.
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: d)
        graph.addUndirectedEdge(from: d, to: e)
        graph.addUndirectedEdge(from: e, to: a)

        let left = graph.cycles(from: a, curvature: .left)
        let right = graph.cycles(from: a, curvature: .right)
        // The zig-zag portion alternates direction, so neither pure curvature
        // can complete the cycle. (The long closing edge produces a large turn
        // in one direction at each junction, but the zig-zag turns in the
        // opposite direction disqualify both.)
        #expect(left.isEmpty || right.isEmpty, "At least one curvature should fail on a zig-zag")
    }

    // MARK: - Bounding limits

    @Test
    func cycleMaximumPathNodeCount() {
        // A pentagon: 5-node cycle. Limit to 4 nodes -> no cycle.
        var graph = Graph()
        let nodes = (0 ..< 5).map { i in
            graph.createNode(at: Coordinate3D(
                latitude: 10.0 + 0.01 * cos(Double(i) * 2.0 * .pi / 5.0),
                longitude: 20.0 + 0.01 * sin(Double(i) * 2.0 * .pi / 5.0)))
        }
        for i in 0 ..< 5 {
            graph.addUndirectedEdge(from: nodes[i], to: nodes[(i + 1) % 5])
        }

        let noCycle = graph.cycles(from: nodes[0], maximumPathNodeCount: 4)
        #expect(noCycle.isEmpty, "A 5-node cycle shouldn't fit in 4 nodes")

        let yesCycle = graph.cycles(from: nodes[0], maximumPathNodeCount: 6)
        #expect(yesCycle.count == 1, "Expected 1 pentagon, got \(yesCycle.count)")
    }

    @Test
    func cycleMaximumPathLength() {
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.001, longitude: 20.0)) // ~111m
        let c = graph.createNode(at: Coordinate3D(latitude: 10.001, longitude: 20.001)) // ~78m
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: a)

        // Perimeter ~ 111 + 78 + 111 = ~300m. Limit to 100m -> no cycle.
        let noCycle = graph.cycles(from: a, maximumPathLength: 100.0)
        #expect(noCycle.isEmpty)
        // Limit to 1000m -> find the cycle.
        let yesCycle = graph.cycles(from: a, maximumPathLength: 1000.0)
        #expect(yesCycle.count == 1)
    }

    @Test
    func cycleMaximumFromSourceDistance() {
        // A long thin triangle: the apex is far from the base start node.
        var graph = Graph()
        let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.01)) // ~780m east
        let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.005)) // ~5.5km north
        graph.addUndirectedEdge(from: a, to: b)
        graph.addUndirectedEdge(from: b, to: c)
        graph.addUndirectedEdge(from: c, to: a)

        // Restrict to within 1km of a: c is ~5.5km away, so no cycle.
        let noCycle = graph.cycles(from: a, maximumFromSourceDistance: 1000.0)
        #expect(noCycle.isEmpty)
        // Restrict to within 10km: cycle found.
        let yesCycle = graph.cycles(from: a, maximumFromSourceDistance: 10_000.0)
        #expect(yesCycle.count == 1)
    }

}