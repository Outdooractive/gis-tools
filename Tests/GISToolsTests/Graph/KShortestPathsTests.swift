import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
  import CoreLocation
#endif

/// ``Graph/kShortestPaths(from:to:k:blockedNodes:edgeFilter:)`` tests for
/// Yen's algorithm.
///
/// Coverage spans synthetic graphs where the set of simple paths is fully
/// enumerable, the real-world Immenstadt network, all supported projections,
/// and antimeridian-crossing geometries.
struct KShortestPathsTests {

  // MARK: - Basic behaviour

  @Test
  func kShortestPathsReturnsSingleWhenOnlyOneExists() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
      Coordinate3D(latitude: 10.2, longitude: 20.2),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let paths = graph.kShortestPaths(from: graph.nodes[0], to: graph.nodes[2], k: 5)
    #expect(paths.count == 1)
    #expect(paths[0].count == 3)
    #expect(paths[0].first == graph.nodes[0])
    #expect(paths[0].last == graph.nodes[2])
  }

  @Test
  func kShortestPathsSameNode() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let paths = graph.kShortestPaths(from: graph.nodes[0], to: graph.nodes[0], k: 3)
    #expect(paths.count == 1)
    #expect(paths[0] == [graph.nodes[0]])
  }

  @Test
  func kShortestPathsDisconnected() {
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
    let paths = graph.kShortestPaths(from: graph.nodes[0], to: graph.nodes[2], k: 3)
    #expect(paths.isEmpty)
  }

  @Test
  func kShortestPathsInvalidNodes() {
    let graph = Graph()
    let a = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = Node(index: 1, coordinate: Coordinate3D(latitude: 10.1, longitude: 20.1))
    #expect(graph.kShortestPaths(from: a, to: b, k: 3).isEmpty)
  }

  @Test
  func kShortestPathsFindsTwoAlternatives() {
    // Two distinct simple paths from a to c:
    //   a - b - c   (two short hops)
    //   a - d - c   (two short hops, different middle node)
    // Plus the direct edge a-c would be the shortest; here we omit it so
    // the two via routes are the only simple paths.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.0))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: a, to: d)
    graph.addUndirectedEdge(from: d, to: c)

    let paths = graph.kShortestPaths(from: a, to: c, k: 5)
    #expect(paths.count == 2, "Expected 2 simple paths, got \(paths.count)")

    // Both paths span 3 nodes (a, middle, c).
    for path in paths {
      #expect(path.count == 3)
      #expect(path.first == a)
      #expect(path.last == c)
    }

    // Paths must differ in the middle node.
    let middles = Set(paths.map { $0[1].index })
    #expect(middles.count == 2, "Expected two distinct middle nodes: \(middles)")
  }

  @Test
  func kShortestPathsOrderedByCost() {
    // Three parallel routes a -> c of differing length.
    //   route 1: a - c               (shortest, direct)
    //   route 2: a - b - c           (medium)
    //   route 3: a - d - e - c       (longest)
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.2))
    let e = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.25))
    graph.addUndirectedEdge(from: a, to: c)
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: a, to: d)
    graph.addUndirectedEdge(from: d, to: e)
    graph.addUndirectedEdge(from: e, to: c)

    let paths = graph.kShortestPaths(from: a, to: c, k: 3)
    #expect(paths.count == 3, "Expected 3 paths, got \(paths.count)")

    let costs = paths.map { graph.length(ofPath: $0) }
    for i in 1..<costs.count {
      #expect(costs[i - 1] <= costs[i] + 0.5, "Paths not ordered by cost: \(costs)")
    }
    // The shortest is the direct edge.
    #expect(paths[0].count == 2)
  }

  @Test
  func kShortestPathsRespectsK() {
    // Same three-route graph as the ordering test, but ask for only 2.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.2))
    let e = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.25))
    graph.addUndirectedEdge(from: a, to: c)
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: a, to: d)
    graph.addUndirectedEdge(from: d, to: e)
    graph.addUndirectedEdge(from: e, to: c)

    let paths = graph.kShortestPaths(from: a, to: c, k: 2)
    #expect(paths.count == 2, "Expected exactly 2 paths, got \(paths.count)")
  }

  @Test
  func kShortestPathsFirstMatchesDijkstra() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
    let start = component.first!
    let end = component.last!

    let dijkstra = graph.shortestPath(from: start, to: end)
    let yen = graph.kShortestPaths(from: start, to: end, k: 3)

    #expect(yen.count >= 1)
    #expect(yen[0].first == start)
    #expect(yen[0].last == end)
    #expect(
      abs(graph.length(ofPath: dijkstra) - graph.length(ofPath: yen[0])) < 1.0,
      "Yen's first path should match Dijkstra's cost")
  }

  @Test
  func kShortestPathsAreSimple() throws {
    // Every returned path must be simple (no repeated node).
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
    let start = component.first!
    let end = component.last!

    let paths = graph.kShortestPaths(from: start, to: end, k: 5)
    for path in paths {
      let indices = path.map(\.index)
      #expect(Set(indices).count == indices.count, "Path is not simple: \(indices)")
    }
  }

  @Test
  func kShortestPathsAreDistinct() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
    let start = component.first!
    let end = component.last!

    let paths = graph.kShortestPaths(from: start, to: end, k: 5)
    let keys = Set(paths.map { $0.map(\.index) })
    #expect(keys.count == paths.count, "Duplicate paths returned")
  }

  @Test
  func kShortestPathsWithEdgeFilter() throws {
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
    let paths = graph.kShortestPaths(from: seed, to: end, k: 3, edgeFilter: hikingFilter)

    #expect(paths.count >= 1)
    for path in paths {
      for i in 1..<path.count {
        let edgeFeature = graph.feature(from: path[i - 1], to: path[i])
        let type: String? = edgeFeature?.property(for: "type")
        #expect(
          hikingTypes.contains(type ?? ""), "Non-hiking edge in hiking path: \(type ?? "nil")")
      }
    }
  }

  // MARK: - Projection coverage

  @Test
  func kShortestPathsAcrossProjections() {
    let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978, .noSRID]

    for projection in projections {
      let coords = [
        Coordinate3D(latitude: 10.0, longitude: 20.0).projected(to: projection),
        Coordinate3D(latitude: 10.1, longitude: 20.1).projected(to: projection),
        Coordinate3D(latitude: 10.1, longitude: 20.0).projected(to: projection),
      ]
      var graph = Graph(nodeTolerance: 1.0)
      let a = graph.createNode(at: coords[0])
      let b = graph.createNode(at: coords[1])
      let c = graph.createNode(at: coords[2])
      graph.addUndirectedEdge(from: a, to: b)
      graph.addUndirectedEdge(from: b, to: c)
      graph.addUndirectedEdge(from: c, to: a)

      let paths = graph.kShortestPaths(from: a, to: c, k: 3)
      // Two simple paths: direct a-c, and a-b-c.
      #expect(paths.count == 2, "projection \(projection): got \(paths.count) paths")
      #expect(paths[0].first == a)
      #expect(paths[0].last == c)
    }
  }

  // MARK: - Antimeridian

  @Test
  func kShortestPathsAntimeridian() {
    // Two parallel routes across the antimeridian:
    //   west - east   (direct, short)
    //   west - north - east (long detour)
    var graph = Graph()
    let west = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let east = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    let north = graph.createNode(at: Coordinate3D(latitude: 80.0, longitude: 179.9))
    graph.addUndirectedEdge(from: west, to: east)
    graph.addUndirectedEdge(from: west, to: north)
    graph.addUndirectedEdge(from: north, to: east)

    let paths = graph.kShortestPaths(from: west, to: east, k: 5)
    #expect(paths.count == 2, "Expected 2 paths, got \(paths.count)")
    // The direct crossing is the shortest.
    #expect(paths[0].count == 2)
    #expect(paths[0].first == west)
    #expect(paths[0].last == east)
  }

}
