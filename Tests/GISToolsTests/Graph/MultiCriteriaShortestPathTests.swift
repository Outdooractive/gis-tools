import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
  import CoreLocation
#endif

/// Multi-criteria shortest path tests for
/// ``Graph/shortestPath(from:to:costFunction:blockedNodes:)``.
///
/// Coverage spans cost functions derived from feature properties (distance +
/// elevation, distance + road class penalty), equality with plain Dijkstra
/// when the cost equals edge weight, the real-world Immenstadt network, all
/// supported projections, and antimeridian-crossing geometries.
struct MultiCriteriaShortestPathTests {

  // MARK: - Basic behaviour

  @Test
  func multiCriteriaPath() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
      Coordinate3D(latitude: 10.2, longitude: 20.2),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let path = graph.shortestPath(from: graph.nodes[0], to: graph.nodes[2]) { edge in
      edge.weight
    }
    #expect(path.count == 3)
    #expect(path[0].index == 0)
    #expect(path[2].index == 2)
  }

  @Test
  func multiCriteriaSameNode() {
    let coords = [
      Coordinate3D(latitude: 10.0, longitude: 20.0),
      Coordinate3D(latitude: 10.1, longitude: 20.1),
    ]
    let graph = Graph(featureCollection: FeatureCollection([Feature(LineString(coords)!)]))
    let path = graph.shortestPath(from: graph.nodes[0], to: graph.nodes[0]) { edge in
      edge.weight
    }
    #expect(path.count == 1)
    #expect(path[0] == graph.nodes[0])
  }

  @Test
  func multiCriteriaDisconnected() {
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
    let path = graph.shortestPath(from: graph.nodes[0], to: graph.nodes[2]) { edge in
      edge.weight
    }
    #expect(path.isEmpty)
  }

  @Test
  func multiCriteriaInvalidNodes() {
    let graph = Graph()
    let a = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = Node(index: 1, coordinate: Coordinate3D(latitude: 10.1, longitude: 20.1))
    #expect(graph.shortestPath(from: a, to: b, costFunction: { $0.weight }).isEmpty)
  }

  @Test
  func multiCriteriaMatchesDijkstraWhenCostIsWeight() throws {
    // When the cost function is just edge.weight, the multi-criteria path
    // must match plain Dijkstra.
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
    let start = component.first!
    let end = component.last!

    let dijkstra = graph.shortestPath(from: start, to: end)
    let multi = graph.shortestPath(from: start, to: end) { $0.weight }

    #expect(multi.first == start)
    #expect(multi.last == end)
    #expect(
      abs(graph.length(ofPath: dijkstra) - graph.length(ofPath: multi)) < 1.0,
      "Multi-criteria with weight cost should match Dijkstra")
  }

  // MARK: - Property-driven cost

  @Test
  func multiCriteriaPrefersCheaperFeatureType() {
    // Two parallel routes a -> c of similar geometry but different "type".
    // The cost function penalizes the "primary" road class so the route
    // through the "residential" edge is preferred even though both are
    // roughly the same length.
    let lineA = Feature(
      LineString([
        Coordinate3D(latitude: 10.0, longitude: 20.0),
        Coordinate3D(latitude: 10.05, longitude: 20.05),
        Coordinate3D(latitude: 10.1, longitude: 20.1),
      ])!,
      properties: ["type": "primary"])
    let lineB = Feature(
      LineString([
        Coordinate3D(latitude: 10.0, longitude: 20.0),
        Coordinate3D(latitude: 10.05, longitude: 20.0),
        Coordinate3D(latitude: 10.1, longitude: 20.1),
      ])!,
      properties: ["type": "residential"])

    let graph = Graph(featureCollection: FeatureCollection([lineA, lineB]))
    // Three or four nodes depending on merging; pick endpoints by coord.
    let a = graph.node(at: Coordinate3D(latitude: 10.0, longitude: 20.0), tolerance: 5.0)!
    let c = graph.node(at: Coordinate3D(latitude: 10.1, longitude: 20.1), tolerance: 5.0)!

    let path = graph.shortestPath(from: a, to: c) { edge in
      let type: String = edge.feature?.property(for: "type") ?? ""
      // Penalize "primary" heavily; residential is cheap.
      return type == "primary" ? edge.weight * 100.0 : edge.weight
    }

    #expect(path.first == a)
    #expect(path.last == c)
    // Every edge on the chosen path must be residential.
    for i in 1..<path.count {
      let feature = graph.feature(from: path[i - 1], to: path[i])
      let type: String = feature?.property(for: "type") ?? ""
      #expect(type == "residential", "Path used a primary edge: \(type)")
    }
  }

  @Test
  func multiCriteriaExcludesInfinityCostEdges() {
    // A direct "forbidden" edge with infinite cost is bypassed for a
    // finite two-hop route.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: a, to: c)  // will be excluded by cost

    let path = graph.shortestPath(from: a, to: c) { edge in
      // Exclude the direct a-c edge.
      if edge.from == a, edge.to == c { return .infinity }
      return edge.weight
    }

    #expect(path.count == 3, "Expected the two-hop route, got \(path)")
    #expect(path[0] == a)
    #expect(path[1] == b)
    #expect(path[2] == c)
  }

  @Test
  func multiCriteriaWithBlockedNodes() {
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)

    let blocked = Set([b])
    let path = graph.shortestPath(
      from: a, to: c, costFunction: { $0.weight }, blockedNodes: blocked)
    #expect(path.isEmpty)
  }

  // MARK: - Projection coverage

  @Test
  func multiCriteriaAcrossProjections() {
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

      let path = graph.shortestPath(from: a, to: c) { $0.weight }
      #expect(path.count == 2, "projection \(projection): \(path)")
      #expect(path.first == a)
      #expect(path.last == c)
    }
  }

  // MARK: - Antimeridian

  @Test
  func multiCriteriaCrossesAntimeridian() {
    var graph = Graph()
    let west = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let east = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    graph.addUndirectedEdge(from: west, to: east)

    let path = graph.shortestPath(from: west, to: east) { $0.weight }
    #expect(path.count == 2)
    #expect(path.first == west)
    #expect(path.last == east)
  }

  @Test
  func multiCriteriaAntimeridianShorterThanDetour() {
    var graph = Graph()
    let west = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let east = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    let north = graph.createNode(at: Coordinate3D(latitude: 80.0, longitude: 179.9))
    graph.addUndirectedEdge(from: west, to: east)
    graph.addUndirectedEdge(from: west, to: north)
    graph.addUndirectedEdge(from: north, to: east)

    let path = graph.shortestPath(from: west, to: east) { $0.weight }
    #expect(path.count == 2, "Expected the antimeridian shortcut: \(path)")
    #expect(path.first == west)
    #expect(path.last == east)
  }

}
