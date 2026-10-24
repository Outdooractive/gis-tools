#if EnableGraphAPI
#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Graph/toFeatureCollection()`` tests.
///
/// Verifies the round-trip: building a graph from a feature collection and
/// exporting it back preserves geometry, properties, and edge count.
struct GraphExportTests {

    @Test
    func emptyGraphExportsEmptyCollection() {
        let graph = Graph()
        let fc = graph.toFeatureCollection()
        #expect(fc.features.isEmpty)
    }

    @Test
    func exportPreservesEdgeCount() throws {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
            Coordinate3D(latitude: 10.2, longitude: 20.2),
        ]
        let graph = try Graph(
            featureCollection: FeatureCollection([Feature(#require(LineString(coords)))]))
        let fc = graph.toFeatureCollection()
        // 3 nodes → 2 edges
        #expect(fc.features.count == 2)
    }

    @Test
    func exportPreservesGeometries() throws {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let graph = try Graph(
            featureCollection: FeatureCollection([Feature(#require(LineString(coords)))]))
        let fc = graph.toFeatureCollection()
        #expect(fc.features.count == 1)

        let feature = fc.features[0]
        guard let ls = feature.geometry as? LineString else {
            Issue.record("Expected LineString geometry")
            return
        }

        #expect(ls.coordinates.count == 2)
        #expect(ls.coordinates[0].latitude == 10.0)
        #expect(ls.coordinates[0].longitude == 20.0)
        #expect(ls.coordinates[1].latitude == 10.1)
        #expect(ls.coordinates[1].longitude == 20.1)
    }

    @Test
    func exportPreservesFeatureProperties() throws {
        let feature = try Feature(
            #require(LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])),
            properties: ["highway": "residential", "maxspeed": 50])
        let graph = Graph(
            featureCollection: FeatureCollection([feature]))
        let fc = graph.toFeatureCollection()
        #expect(fc.features.count == 1)

        let exported = fc.features[0]
        let highway: String? = exported.property(for: "highway")
        #expect(highway == "residential")
        let maxspeed: Int? = exported.property(for: "maxspeed")
        #expect(maxspeed == 50)
    }

    @Test
    func exportMarksDirectedEdges() throws {
        let feature = try Feature(
            #require(LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])),
            properties: ["oneway": "yes"])
        let graph = Graph(
            featureCollection: FeatureCollection([feature]),
            isDirected: true)
        let fc = graph.toFeatureCollection()
        #expect(fc.features.count == 1)

        let exported = fc.features[0]
        let oneway: String? = exported.property(for: "oneway")
        #expect(oneway == "yes")
    }

    @Test
    func exportIncludesWeight() throws {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let graph = try Graph(
            featureCollection: FeatureCollection([Feature(#require(LineString(coords)))]))
        let fc = graph.toFeatureCollection()
        #expect(fc.features.count == 1)

        let weight: Double? = fc.features[0].property(for: "weight")
        #expect(weight != nil)
        #expect(try #require(weight) > 0.0)
    }

    @Test
    func exportPreservesFeatureId() throws {
        let feature = try Feature(
            #require(LineString([
                Coordinate3D(latitude: 10.0, longitude: 20.0),
                Coordinate3D(latitude: 10.1, longitude: 20.1),
            ])),
            id: .string("road-42"))
        let graph = Graph(
            featureCollection: FeatureCollection([feature]))
        let fc = graph.toFeatureCollection()
        #expect(fc.features.count == 1)

        let exported = fc.features[0]
        #expect(exported.id == .string("road-42"))
    }

    @Test
    func exportUndirectedEdgeHasNoOnewayProperty() throws {
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let graph = try Graph(
            featureCollection: FeatureCollection([Feature(#require(LineString(coords)))]))
        let fc = graph.toFeatureCollection()
        #expect(fc.features.count == 1)

        let oneway: String? = fc.features[0].property(for: "oneway")
        #expect(oneway == nil, "Undirected edge should not have oneway property")
    }

    // MARK: - Round-trip

    @Test
    func roundTripPreservesNodeCount() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let fc = graph.toFeatureCollection()
        let rebuilt = Graph(featureCollection: fc)

        // The rebuilt graph may have slight differences due to re-deriving
        // edges from individual 2-point LineStrings, but the node count
        // should be close.
        let ratio = Double(rebuilt.nodeCount) / Double(graph.nodeCount)
        #expect(ratio >= 0.8, "Round-trip lost too many nodes: \(rebuilt.nodeCount) / \(graph.nodeCount)")
        #expect(ratio <= 1.2, "Round-trip gained too many nodes: \(rebuilt.nodeCount) / \(graph.nodeCount)")
    }

    @Test
    func roundTripPreservesEdgeCount() throws {
        let graph = try GraphTestHelper.immenstadtGraph()
        let fc = graph.toFeatureCollection()
        let rebuilt = Graph(featureCollection: fc)
        #expect(
            rebuilt.edges.count == graph.edges.count,
            "Edge count should match: \(rebuilt.edges.count) vs \(graph.edges.count)",
        )
    }

    @Test
    func roundTripPreservesWeights() throws {
        // Build a small graph, export, rebuild, and verify weights match.
        let coords = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.05, longitude: 20.05),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
        ]
        let original = try Graph(
            featureCollection: FeatureCollection([Feature(#require(LineString(coords)))]))
        let fc = original.toFeatureCollection()
        let rebuilt = Graph(featureCollection: fc)

        let origWeights = original.edges.map(\.weight).sorted()
        let rebWeights = rebuilt.edges.map(\.weight).sorted()
        #expect(origWeights.count == rebWeights.count)

        for (orig, reb) in zip(origWeights, rebWeights) {
            #expect(
                abs(orig - reb) < 1.0,
                "Weight mismatch: \(orig) vs \(reb)",
            )
        }
    }

    @Test
    func debugDescriptionForEmptyGraph() {
        #expect(Graph().debugDescription.isEmpty)
    }

    @Test
    func debugDescriptionListsNodesAndEdges() throws {
        let graph = try Graph(featureCollection: FeatureCollection([Feature(#require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ])))]))

        let description = graph.debugDescription
        #expect(!description.isEmpty)
        #expect(description.contains("->"))
        #expect(description.components(separatedBy: "\n").count >= 2)
        #expect(description.contains("0.0,0.0") || description.contains("0,0"))
    }

}
#endif
