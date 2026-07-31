#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Cycle-detection tests on the real-world Immenstadt road network, including
/// a parameter sweep over the bounding limits and curvature-restricted
/// roundabout detection.
///
/// Marked `.serialized` because the suite runs 7 cycle-detection traversals
/// on the full road network.
@Suite(.serialized)
struct CycleRoadNetworkTests {

    /// Loads the Immenstadt road network and asserts that cycles are found and
    /// well-formed under the recommended bounding parameters.
    @Test
    func cyclesOnRoadNetworkImmenstadt() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        #expect(graph.nodeCount > 100, "Road network should have many nodes")

        // Find a node on/near a roundabout: features carry `roundabout`.
        let start = try GraphTestHelper.roundaboutNode(in: graph)
        #expect(start != nil, "No roundabout node found in test data")

        let cycles = graph.cycles(
            from: start!,
            maximumPathLength: 250.0,
            maximumPathNodeCount: 150,
            maximumFromSourceDistance: 150.0)

        #expect(cycles.isNotEmpty, "Expected at least one cycle near a roundabout")
        for cycle in cycles {
            #expect(cycle.first == cycle.last, "Cycle must be closed")
            #expect(cycle.count >= 4, "Cycle must have at least 3 distinct nodes")
            #expect(cycle.count <= 151, "Cycle must respect maximumPathNodeCount+1")
            // All nodes must be within maximumFromSourceDistance of the origin.
            for node in cycle {
                #expect(node.coordinate.distance(from: start!.coordinate) <= 150.0 + 1.0)
            }
        }

        // Canonical dedup: no two cycles share the same canonical form.
        var seen: Set<[Int]> = []
        for cycle in cycles {
            let indices = cycle.dropLast().map(\.index)
            #expect(seen.insert(indices.sorted()).inserted, "Duplicate cycle reported")
        }

        print("Immenstadt cycles from roundabout node \(start!.index): \(cycles.count)")
    }

    @Test(arguments: [
        (maxLength: 100.0, maxNodes: 75, maxFromSource: 75.0),
        (maxLength: 250.0, maxNodes: 150, maxFromSource: 150.0),
        (maxLength: 400.0, maxNodes: 200, maxFromSource: 200.0),
    ])
    func cycleParameterSweep(_ params: (maxLength: Double, maxNodes: Int, maxFromSource: Double)) throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        guard let start = try GraphTestHelper.roundaboutNode(in: graph) else {
            Issue.record("No roundabout node")
            return
        }

        let cycles = graph.cycles(
            from: start,
            maximumPathLength: params.maxLength,
            maximumPathNodeCount: params.maxNodes,
            maximumFromSourceDistance: params.maxFromSource)

        // Tighter limits find fewer-or-equal cycles; all stay within bounds.
        for cycle in cycles {
            #expect(cycle.count - 1 <= params.maxNodes)
        }
        print("Sweep \(params): \(cycles.count) cycles")
    }

    // MARK: - Curvature-restricted roundabout detection

    /// Roundabouts are roughly circular road features. Traversing a
    /// roundabout in one direction produces predominantly right turns (in the
    /// `angleBetween` convention, negative angles); in the other direction,
    /// predominantly left turns (positive angles).
    ///
    /// However, the roundabout features in the test data are open polylines,
    /// not closed rings — they connect to surrounding roads at their
    /// endpoints. The graph cycles that pass through roundabout nodes
    /// therefore include entry/exit roads that turn the opposite way, so
    /// requiring *every* turn to be left (or right) filters out all cycles.
    ///
    /// This test documents that behavior: the curvature restriction
    /// correctly finds 0 cycles with the recommended bounding parameters,
    /// because no pure roundabout ring exists as a graph cycle.
    @Test
    func roundaboutDetectionWithCurvature() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let start = try GraphTestHelper.roundaboutNode(in: graph)
        #expect(start != nil, "No roundabout node found in test data")

        let limits: (maxLength: Double, maxNodes: Int, maxFromSource: Double) = (250.0, 150, 150.0)

        let allCycles = graph.cycles(
            from: start!,
            maximumPathLength: limits.maxLength,
            maximumPathNodeCount: limits.maxNodes,
            maximumFromSourceDistance: limits.maxFromSource)

        let leftCycles = graph.cycles(
            from: start!,
            curvature: .left,
            maximumPathLength: limits.maxLength,
            maximumPathNodeCount: limits.maxNodes,
            maximumFromSourceDistance: limits.maxFromSource)

        let rightCycles = graph.cycles(
            from: start!,
            curvature: .right,
            maximumPathLength: limits.maxLength,
            maximumPathNodeCount: limits.maxNodes,
            maximumFromSourceDistance: limits.maxFromSource)

        print("Immenstadt curvature: ignore=\(allCycles.count), left=\(leftCycles.count), right=\(rightCycles.count)")

        // Curvature restriction must not find more cycles than unrestricted.
        #expect(leftCycles.count <= allCycles.count, "Left curvature found more cycles than ignore")
        #expect(rightCycles.count <= allCycles.count, "Right curvature found more cycles than ignore")

        // The cycles found near roundabouts include entry/exit roads, so they
        // mix turn directions and are filtered out by strict curvature. This
        // is the expected behavior with the current all-turns-must-match
        // curvature logic.
        #expect(leftCycles.isEmpty, "Left curvature should find no cycles (mixed turns)")
        #expect(rightCycles.isEmpty, "Right curvature should find no cycles (mixed turns)")

        // Verify the diagnosis: the unrestricted cycles near the roundabout
        // include edges on non-roundabout features.
        var hasMixedFeatures = false
        for cycle in allCycles.prefix(20) {
            var rbEdges = 0
            var nonRbEdges = 0
            for i in 0 ..< cycle.count - 1 {
                let feat = graph.feature(from: cycle[i], to: cycle[i + 1])
                let rb: String? = feat?.property(for: "roundabout")
                if rb == "yes" || rb == "1" || rb == "true" {
                    rbEdges += 1
                }
                else {
                    nonRbEdges += 1
                }
            }
            if rbEdges > 0, nonRbEdges > 0 {
                hasMixedFeatures = true
                break
            }
        }
        #expect(hasMixedFeatures, "Cycles near roundabouts should mix roundabout and non-roundabout edges")
    }

    /// Verifies that curvature restriction *does* work on a synthetic pure
    /// roundabout ring (a closed polygon with consistent right turns).
    @Test
    func curvatureFindsPureRoundaboutRing() {
        // Build a near-circular ring of 8 nodes — all right turns.
        var graph = Graph()
        let center = Coordinate3D(latitude: 47.5, longitude: 10.2)
        let radius = 0.0005 // ~55m
        var nodes: [Node] = []
        for i in 0 ..< 8 {
            let angle = Double(i) * 2.0 * .pi / 8.0
            let coord = Coordinate3D(
                latitude: center.latitude + radius * cos(angle),
                longitude: center.longitude + radius * sin(angle))
            nodes.append(graph.createNode(at: coord))
        }
        // Connect into a ring.
        for i in 0 ..< 8 {
            graph.addUndirectedEdge(from: nodes[i], to: nodes[(i + 1) % 8])
        }

        let allCycles = graph.cycles(from: nodes[0])
        let leftCycles = graph.cycles(from: nodes[0], curvature: .left)
        let rightCycles = graph.cycles(from: nodes[0], curvature: .right)

        print("Synthetic ring: ignore=\(allCycles.count), left=\(leftCycles.count), right=\(rightCycles.count)")

        #expect(allCycles.count == 1, "Expected 1 ring cycle, got \(allCycles.count)")
        // A pure ring traversed in one direction is all-right, in the other
        // all-left, so both curvatures should find exactly one cycle.
        #expect(leftCycles.count == 1, "Left curvature should find the ccw traversal")
        #expect(rightCycles.count == 1, "Right curvature should find the cw traversal")
    }

    // MARK: - Private

    /// Canonical index sequence for a cycle (rotation- and reversal-invariant
    /// for undirected graphs), used for cross-comparison.
    private func canonicalIndices(_ cycle: [Node]) -> [Int] {
        let indices = cycle.dropLast().map(\.index).sorted()
        return indices
    }

}