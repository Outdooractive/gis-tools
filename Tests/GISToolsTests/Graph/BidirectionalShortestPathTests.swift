import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
  import CoreLocation
#endif

/// ``Graph/bidirectionalShortestPath(from:to:blockedNodes:edgeFilter:)`` tests.
///
/// Bidirectional Dijkstra must return the same optimal paths as unidirectional
/// Dijkstra while exploring fewer nodes. Coverage spans small synthetic
/// graphs, the real-world Immenstadt network, all supported projections,
/// antimeridian-crossing geometries, and one-way (directed) graphs.
struct BidirectionalShortestPathTests {

  // MARK: - Basic behaviour

  @Test
  func bidirectionalPath() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
      Coordinate3D(latitude: 10.2, longitude: 20.2),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let path = graph.bidirectionalShortestPath(from: graph.nodes[0], to: graph.nodes[2])
    #expect(path.count == 3)
    #expect(path[0].index == 0)
    #expect(path[2].index == 2)
  }

  @Test
  func bidirectionalPathSameNode() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let path = graph.bidirectionalShortestPath(from: graph.nodes[0], to: graph.nodes[0])
    #expect(path.count == 1)
    #expect(path[0].index == 0)
  }

  @Test
  func bidirectionalPathDisconnected() {
    let graph = Graph(
      featureCollection: FeatureCollection([
        Feature(
          LineString([
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.1, longitude: 20.1),
          ])!),
        Feature(
          LineString([
            Coordinate3D(latitude: 11.0, longitude: 21.0),
            Coordinate3D(latitude: 11.1, longitude: 21.1),
          ])!),
      ]))
    let path = graph.bidirectionalShortestPath(from: graph.nodes[0], to: graph.nodes[2])
    #expect(path.isEmpty)
  }

  @Test
  func bidirectionalPathWithBlockedNodes() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
      Coordinate3D(latitude: 10.2, longitude: 20.2),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let blocked = Set([graph.nodes[1]])
    let path = graph.bidirectionalShortestPath(
      from: graph.nodes[0],
      to: graph.nodes[2],
      blockedNodes: blocked)
    #expect(path.isEmpty)
  }

  @Test
  func bidirectionalPathInvalidNodes() {
    let graph = Graph()
    let a = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = Node(index: 1, coordinate: Coordinate3D(latitude: 10.1, longitude: 20.1))
    #expect(graph.bidirectionalShortestPath(from: a, to: b).isEmpty)
  }

  @Test
  func bidirectionalPathWithBranch() {
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)

    let path = graph.bidirectionalShortestPath(from: a, to: c)
    #expect(path.count == 3)
    #expect(path[0].index == a.index)
    #expect(path[2].index == c.index)
  }

  @Test
  func bidirectionalPathTakesShorterRoute() {
    // Square with a diagonal: a-b-c-d-a plus a-c. Shortest a->c is the diagonal.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.1))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.0))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: d)
    graph.addUndirectedEdge(from: d, to: a)
    graph.addUndirectedEdge(from: a, to: c)  // diagonal shortcut

    let path = graph.bidirectionalShortestPath(from: a, to: c)
    #expect(path.count == 2, "Expected the diagonal shortcut: \(path)")
    #expect(path[0] == a)
    #expect(path[1] == c)
  }

  @Test
  func bidirectionalPathLongerDetour() {
    // Two paths from a to c: a direct edge, and a two-hop detour through b.
    // The bidirectional search must select the direct (shorter) edge.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    // Short direct edge a->c. Build the triangle so that the direct edge
    // is clearly shorter than the two-hop route.
    graph.addUndirectedEdge(from: a, to: c)

    let path = graph.bidirectionalShortestPath(from: a, to: c)
    #expect(path.count == 2, "Expected the direct edge: \(path)")
    #expect(path[0] == a)
    #expect(path[1] == c)
  }

  // MARK: - Parity with Dijkstra

  @Test
  func bidirectionalMatchesDijkstraOnRoadNetwork() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!

    let samples: [(Node, Node)] = [
      (component.first!, component.last!),
      (component[component.count / 4], component[component.count * 3 / 4]),
      (component[10 % component.count], component[component.count - 11]),
    ]

    for (start, end) in samples {
      let dijkstra = graph.shortestPath(from: start, to: end)
      let bidirectional = graph.bidirectionalShortestPath(from: start, to: end)

      #expect(bidirectional.first == start, "Bidirectional start mismatch")
      #expect(bidirectional.last == end, "Bidirectional end mismatch")

      let dijkstraLength = graph.length(ofPath: dijkstra)
      let bidirectionalLength = graph.length(ofPath: bidirectional)

      #expect(
        abs(dijkstraLength - bidirectionalLength) < 0.5,
        "Bidirectional (\(bidirectionalLength)m) != Dijkstra (\(dijkstraLength)m)")
    }
  }

  @Test
  func bidirectionalMatchesDijkstraWithEdgeFilter() throws {
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

    let dijkstra = graph.shortestPath(from: seed, to: end, edgeFilter: hikingFilter)
    let bidirectional = graph.bidirectionalShortestPath(
      from: seed,
      to: end,
      edgeFilter: hikingFilter)

    #expect(bidirectional.first == seed)
    #expect(bidirectional.last == end)
    #expect(
      abs(graph.length(ofPath: dijkstra) - graph.length(ofPath: bidirectional)) < 0.5,
      "Bidirectional (\(graph.length(ofPath: bidirectional))m) != Dijkstra (\(graph.length(ofPath: dijkstra))m)"
    )
  }

  // MARK: - Projection coverage

  @Test
  func bidirectionalWorksAcrossProjections() throws {
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

      let path = graph.bidirectionalShortestPath(from: a, to: c)
      #expect(path.count == 2, "projection \(projection): \(path)")
      #expect(path.first == a)
      #expect(path.last == c)
    }
  }

  // MARK: - Antimeridian

  @Test
  func bidirectionalCrossesAntimeridian() {
    // Two nodes straddling the antimeridian (+179.9 / -179.9) connected by
    // a single edge. The shortest path must cross the dateline.
    var graph = Graph()
    let west = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let east = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    graph.addUndirectedEdge(from: west, to: east)

    let path = graph.bidirectionalShortestPath(from: west, to: east)
    #expect(path.count == 2, "Expected direct antimeridian crossing: \(path)")
    #expect(path.first == west)
    #expect(path.last == east)
  }

  @Test
  func bidirectionalAntimeridianShorterThanDetour() {
    // west --- east straddles the antimeridian (short).
    // A long detour west -> north -> east stays on the +180 side.
    var graph = Graph()
    let west = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let east = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    let north = graph.createNode(at: Coordinate3D(latitude: 80.0, longitude: 179.9))
    graph.addUndirectedEdge(from: west, to: east)  // ~22 km across dateline
    graph.addUndirectedEdge(from: west, to: north)  // ~7_000 km
    graph.addUndirectedEdge(from: north, to: east)  // ~7_000 km

    let path = graph.bidirectionalShortestPath(from: west, to: east)
    #expect(path.count == 2, "Expected the antimeridian shortcut: \(path)")
    #expect(path.first == west)
    #expect(path.last == east)
  }

  // MARK: - Directed graphs

  @Test
  func bidirectionalDirectedOnewayForward() {
    // One-way edge A->B: forward search reaches B from A.
    let oneway = Feature(
      LineString([
        Coordinate3D(latitude: 10.0, longitude: 20.0),
        Coordinate3D(latitude: 10.1, longitude: 20.1),
      ])!,
      properties: ["oneway": "yes"])

    let directed = Graph(
      featureCollection: FeatureCollection([oneway]),
      isDirected: true)

    let a = directed.nodes[0]
    let b = directed.nodes[1]
    let path = directed.bidirectionalShortestPath(from: a, to: b)
    #expect(path.count == 2)
    #expect(path.first == a)
    #expect(path.last == b)
  }

  @Test
  func bidirectionalDirectedOnewayReverseBlocked() {
    // One-way edge A->B: reverse direction B->A must be unreachable.
    let oneway = Feature(
      LineString([
        Coordinate3D(latitude: 10.0, longitude: 20.0),
        Coordinate3D(latitude: 10.1, longitude: 20.1),
      ])!,
      properties: ["oneway": "yes"])

    let directed = Graph(
      featureCollection: FeatureCollection([oneway]),
      isDirected: true)

    let a = directed.nodes[0]
    let b = directed.nodes[1]
    #expect(directed.bidirectionalShortestPath(from: b, to: a).isEmpty)
  }

  @Test
  func bidirectionalDirectedMatchesDijkstra() {
    // Directed graph with mixed one-way and two-way edges; compare cost
    // (not necessarily node sequence) with unidirectional Dijkstra.
    let oneway = Feature(
      LineString([
        Coordinate3D(latitude: 10.0, longitude: 20.0),
        Coordinate3D(latitude: 10.1, longitude: 20.1),
      ])!,
      properties: ["oneway": "yes"])
    let twoway = Feature(
      LineString([
        Coordinate3D(latitude: 10.1, longitude: 20.1),
        Coordinate3D(latitude: 10.2, longitude: 20.2),
      ])!)

    let directed = Graph(
      featureCollection: FeatureCollection([oneway, twoway]),
      isDirected: true)

    let a = directed.nodes[0]
    let c = directed.nodes[2]

    let dijkstra = directed.shortestPath(from: a, to: c)
    let bidirectional = directed.bidirectionalShortestPath(from: a, to: c)

    #expect(bidirectional.first == a)
    #expect(bidirectional.last == c)
    #expect(
      abs(directed.length(ofPath: dijkstra) - directed.length(ofPath: bidirectional)) < 0.5,
      "Directed bidirectional cost != Dijkstra cost")
  }

}
