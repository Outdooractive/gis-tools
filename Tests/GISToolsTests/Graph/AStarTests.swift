import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
  import CoreLocation
#endif

/// ``Graph/aStarPath(from:to:blockedNodes:edgeFilter:)`` tests.
///
/// A* must return the same optimal paths as Dijkstra while exploring fewer
/// nodes. Coverage spans small synthetic graphs, the real-world Immenstadt
/// network, all supported projections, and antimeridian-crossing geometries.
struct AStarTests {

  // MARK: - Basic behaviour

  @Test
  func aStarPath() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
      Coordinate3D(latitude: 10.2, longitude: 20.2),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let path = graph.aStarPath(from: graph.nodes[0], to: graph.nodes[2])
    #expect(path.count == 3)
    #expect(path[0].index == 0)
    #expect(path[2].index == 2)
  }

  @Test
  func aStarPathSameNode() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let path = graph.aStarPath(from: graph.nodes[0], to: graph.nodes[0])
    #expect(path.count == 1)
    #expect(path[0].index == 0)
  }

  @Test
  func aStarPathDisconnected() {
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
    let path = graph.aStarPath(from: graph.nodes[0], to: graph.nodes[2])
    #expect(path.isEmpty)
  }

  @Test
  func aStarPathWithBlockedNodes() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
      Coordinate3D(latitude: 10.2, longitude: 20.2),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let blocked = Set([graph.nodes[1]])
    let path = graph.aStarPath(from: graph.nodes[0], to: graph.nodes[2], blockedNodes: blocked)
    #expect(path.isEmpty)
  }

  @Test
  func aStarPathInvalidNodes() {
    let graph = Graph()
    let a = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = Node(index: 1, coordinate: Coordinate3D(latitude: 10.1, longitude: 20.1))
    #expect(graph.aStarPath(from: a, to: b).isEmpty)
  }

  @Test
  func aStarPathTakesShorterRoute() {
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

    let path = graph.aStarPath(from: a, to: c)
    #expect(path.count == 2, "Expected the diagonal shortcut: \(path)")
    #expect(path[0] == a)
    #expect(path[1] == c)
  }

  @Test
  func aStarPathWithBranch() {
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)

    let path = graph.aStarPath(from: a, to: c)
    #expect(path.count == 3)
    #expect(path[0].index == a.index)
    #expect(path[2].index == c.index)
  }

  // MARK: - Parity with Dijkstra

  @Test
  func aStarMatchesDijkstraOnRoadNetwork() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!

    // Sample several pairs across the network and compare A* with Dijkstra.
    let samples: [(Node, Node)] = [
      (component.first!, component.last!),
      (component[component.count / 4], component[component.count * 3 / 4]),
      (component[10 % component.count], component[component.count - 11]),
    ]

    for (start, end) in samples {
      let dijkstra = graph.shortestPath(from: start, to: end)
      let aStar = graph.aStarPath(from: start, to: end)

      #expect(aStar.first == start, "A* start mismatch")
      #expect(aStar.last == end, "A* end mismatch")

      let dijkstraLength = graph.length(ofPath: dijkstra)
      let aStarLength = graph.length(ofPath: aStar)

      // A* may find a different but equally-short path; compare cost.
      #expect(
        abs(dijkstraLength - aStarLength) < 0.5,
        "A* (\(aStarLength)m) != Dijkstra (\(dijkstraLength)m)")
    }
  }

  @Test
  func aStarMatchesDijkstraWithEdgeFilter() throws {
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
    let aStar = graph.aStarPath(from: seed, to: end, edgeFilter: hikingFilter)

    #expect(aStar.first == seed)
    #expect(aStar.last == end)
    #expect(
      abs(graph.length(ofPath: dijkstra) - graph.length(ofPath: aStar)) < 0.5,
      "A* (\(graph.length(ofPath: aStar))m) != Dijkstra (\(graph.length(ofPath: dijkstra))m)")
  }

  // MARK: - Projection coverage

  @Test
  func aStarWorksAcrossProjections() throws {
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

      let path = graph.aStarPath(from: a, to: c)
      #expect(path.count == 2, "projection \(projection): \(path)")
      #expect(path.first == a)
      #expect(path.last == c)
    }
  }

  // MARK: - Antimeridian

  @Test
  func aStarCrossesAntimeridian() {
    // Two nodes straddling the antimeridian (+179.9 / -179.9) connected by
    // a single edge. The shortest path must cross the dateline.
    var graph = Graph()
    let west = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let east = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    graph.addUndirectedEdge(from: west, to: east)

    let path = graph.aStarPath(from: west, to: east)
    #expect(path.count == 2, "Expected direct antimeridian crossing: \(path)")
    #expect(path.first == west)
    #expect(path.last == east)
  }

  @Test
  func aStarAntimeridianShorterThanDetour() {
    // west --- east straddles the antimeridian (short).
    // A long detour west -> north -> east stays on the +180 side.
    // A* should prefer the antimeridian edge despite the heuristic, which
    // for EPSG:4326 uses the Haversine great-circle distance and is well
    // defined across the dateline.
    var graph = Graph()
    let west = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let east = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    let north = graph.createNode(at: Coordinate3D(latitude: 80.0, longitude: 179.9))
    graph.addUndirectedEdge(from: west, to: east)  // ~22 km across dateline
    graph.addUndirectedEdge(from: west, to: north)  // ~7_000 km
    graph.addUndirectedEdge(from: north, to: east)  // ~7_000 km

    let path = graph.aStarPath(from: west, to: east)
    #expect(path.count == 2, "Expected the antimeridian shortcut: \(path)")
    #expect(path.first == west)
    #expect(path.last == east)
  }

}
