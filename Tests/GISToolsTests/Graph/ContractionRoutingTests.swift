import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
  import CoreLocation
#endif

/// Contraction-accelerated routing tests.
///
/// ``Graph/shortestPathViaContraction(from:to:blockedNodes:edgeFilter:)``,
/// ``Graph/aStarPathViaContraction(from:to:blockedNodes:edgeFilter:)``, and
/// ``Graph/bidirectionalShortestPathViaContraction(from:to:blockedNodes:edgeFilter:)``
/// must return paths whose cost matches a direct search on the full graph.
/// Coverage spans the real-world Immenstadt network, all supported
/// projections, and antimeridian-crossing geometries.
struct ContractionRoutingTests {

  // MARK: - Parity with direct routing on the real network

  @Test
  func dijkstraViaContractionMatchesDirect() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
    let start = component.first!
    let end = component.last!

    let direct = graph.shortestPath(from: start, to: end)
    let viaContraction = graph.shortestPathViaContraction(from: start, to: end)

    #expect(viaContraction.first == start, "Endpoint mismatch at start")
    #expect(viaContraction.last == end, "Endpoint mismatch at end")
    #expect(
      abs(graph.length(ofPath: direct) - graph.length(ofPath: viaContraction)) < 5.0,
      "Contraction route \(graph.length(ofPath: viaContraction))m != direct \(graph.length(ofPath: direct))m"
    )
  }

  @Test
  func aStarViaContractionMatchesDirect() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
    let start = component.first!
    let end = component.last!

    let direct = graph.aStarPath(from: start, to: end)
    let viaContraction = graph.aStarPathViaContraction(from: start, to: end)

    #expect(viaContraction.first == start)
    #expect(viaContraction.last == end)
    #expect(
      abs(graph.length(ofPath: direct) - graph.length(ofPath: viaContraction)) < 5.0,
      "A* contraction route mismatch")
  }

  @Test
  func bidirectionalViaContractionMatchesDirect() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
    let start = component.first!
    let end = component.last!

    let direct = graph.bidirectionalShortestPath(from: start, to: end)
    let viaContraction = graph.bidirectionalShortestPathViaContraction(from: start, to: end)

    #expect(viaContraction.first == start)
    #expect(viaContraction.last == end)
    #expect(
      abs(graph.length(ofPath: direct) - graph.length(ofPath: viaContraction)) < 5.0,
      "Bidirectional contraction route mismatch")
  }

  @Test
  func contractionReducesNodeCountOnRealNetwork() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let result = try #require(graph.contracted())
    #expect(
      result.graph.nodeCount < graph.nodeCount,
      "Contraction should reduce node count (\(result.graph.nodeCount) vs \(graph.nodeCount))")
    // Real road networks have many intermediate polyline vertices.
    #expect(result.graph.nodeCount <= graph.nodeCount / 2)
  }

  // MARK: - Edge filter parity

  @Test
  func viaContractionWithEdgeFilterMatchesDirect() throws {
    let graph = try GraphTestHelper.immenstadtGraph()

    let hikingTypes: Set<String> = ["footway", "path", "track", "pedestrian", "steps"]
    let hikingFilter: (Edge) -> Bool = { edge in
      guard let type: String = edge.feature?.property(for: "type") else { return false }
      return hikingTypes.contains(type)
    }

    guard
      let (seed, reachable) = GraphTestHelper.largestFilteredComponent(
        in: graph,
        edgeFilter: hikingFilter)
    else {
      Issue.record("Hiking subgraph too small to test")
      return
    }

    let end = GraphTestHelper.farthestNode(from: seed, in: reachable) ?? reachable.last!

    let direct = graph.shortestPath(from: seed, to: end, edgeFilter: hikingFilter)
    let viaContraction = graph.shortestPathViaContraction(
      from: seed, to: end, edgeFilter: hikingFilter)

    #expect(viaContraction.first == seed)
    #expect(viaContraction.last == end)
    #expect(
      abs(graph.length(ofPath: direct) - graph.length(ofPath: viaContraction)) < 5.0,
      "Filtered contraction route mismatch")

    // The expanded path must use only hiking edges.
    for i in 1..<viaContraction.count {
      let edgeFeature = graph.feature(from: viaContraction[i - 1], to: viaContraction[i])
      let type: String? = edgeFeature?.property(for: "type")
      #expect(
        hikingTypes.contains(type ?? ""), "Non-hiking edge in expanded path: \(type ?? "nil")")
    }
  }

  // MARK: - Projection coverage

  @Test
  func viaContractionAcrossProjections() {
    let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978, .noSRID]

    for projection in projections {
      let coords = (0...6).map { i in
        Coordinate3D(latitude: 10.0 + Double(i) * 0.01, longitude: 20.0).projected(to: projection)
      }
      var graph = Graph(nodeTolerance: 1.0)
      let nodes = coords.map { graph.createNode(at: $0) }
      for i in 0..<nodes.count - 1 {
        graph.addUndirectedEdge(from: nodes[i], to: nodes[i + 1])
      }

      let direct = graph.shortestPath(from: nodes.first!, to: nodes.last!)
      let viaContraction = graph.shortestPathViaContraction(from: nodes.first!, to: nodes.last!)

      #expect(viaContraction.first == nodes.first!, "projection \(projection)")
      #expect(viaContraction.last == nodes.last!, "projection \(projection)")
      #expect(
        abs(graph.length(ofPath: direct) - graph.length(ofPath: viaContraction)) < 0.001,
        "projection \(projection) route mismatch")
    }
  }

  // MARK: - Antimeridian

  @Test
  func viaContractionAcrossAntimeridian() {
    // Chain a (179.9) - b (-179.95) - c (-179.9) - d (-179.85): b and c are
    // degree-2 chain nodes across the dateline; contraction removes them.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.95))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.85))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: d)

    let direct = graph.shortestPath(from: a, to: d)
    let viaContraction = graph.shortestPathViaContraction(from: a, to: d)

    #expect(viaContraction.first == a)
    #expect(viaContraction.last == d)
    #expect(
      abs(graph.length(ofPath: direct) - graph.length(ofPath: viaContraction)) < 1.0,
      "Antimeridian contraction route mismatch")
    // The expanded path should include the intermediate dateline nodes.
    #expect(viaContraction.count >= direct.count, "Expanded path should be at least as long")
  }

  // MARK: - Blocked nodes / fallback

  @Test
  func viaContractionWithBlockedNodes() {
    // Block an endpoint-adjacent node; the contraction wrapper must still
    // return a valid path (falling back to direct search if the blocked
    // node was an intermediate chain node).
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: 20.15))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: d)

    // Block an intermediate (b is a chain node). The wrapper falls back to
    // the full search, which cannot route through b.
    let blocked = Set([b])
    #expect(graph.shortestPathViaContraction(from: a, to: d, blockedNodes: blocked).isEmpty)
  }

}
