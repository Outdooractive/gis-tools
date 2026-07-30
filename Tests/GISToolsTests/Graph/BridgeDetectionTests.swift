import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
  import CoreLocation
#endif

/// ``Graph/bridges()`` tests.
///
/// Bridge detection finds edges whose removal disconnects the graph (critical
/// road segments with no alternative route). Coverage spans synthetic graphs
/// with known bridges, the real-world Immenstadt network, all supported
/// projections, antimeridian-crossing geometries, directed graphs (weak
/// connectivity), and parallel-edge handling.
struct BridgeDetectionTests {

  // MARK: - Basic detection

  @Test
  func bridgeInChain() {
    // Linear chain a-b-c-d: every edge is a bridge.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: 20.15))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: d)

    let bridges = graph.bridges()
    #expect(bridges.count == 3, "Expected 3 bridges in a chain, got \(bridges.count)")
  }

  @Test
  func noBridgesInCycle() {
    // A pure cycle has no bridges.
    var graph = Graph()
    let nodes = (0..<4).map { i in
      graph.createNode(
        at: Coordinate3D(
          latitude: 10.0 + 0.01 * Double(i % 2),
          longitude: 20.0 + 0.01 * Double(i / 2)))
    }
    for i in 0..<nodes.count {
      graph.addUndirectedEdge(from: nodes[i], to: nodes[(i + 1) % nodes.count])
    }

    #expect(graph.bridges().isEmpty)
  }

  @Test
  func bridgeConnectingTwoCycles() {
    // Two cycles joined by a single edge: the joining edge is the only
    // bridge.
    //   a - b - c - a    (cycle 1)
    //   d - e - f - d    (cycle 2)
    //   c - d            (the bridge)
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.0))
    let e = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: 20.05))
    let f = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: 20.0))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)  // cycle 1
    graph.addUndirectedEdge(from: d, to: e)
    graph.addUndirectedEdge(from: e, to: f)
    graph.addUndirectedEdge(from: f, to: d)  // cycle 2
    graph.addUndirectedEdge(from: c, to: d)  // bridge

    let bridges = graph.bridges()
    #expect(bridges.count == 1, "Expected 1 bridge, got \(bridges.count)")
    // The bridge connects c and d.
    let bridge = bridges[0]
    let endpoints = Set([bridge.from.index, bridge.to.index])
    #expect(endpoints == Set([c.index, d.index]))
  }

  @Test
  func emptyGraphHasNoBridges() {
    let graph = Graph()
    #expect(graph.bridges().isEmpty)
  }

  @Test
  func singleEdgeIsBridge() {
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)

    let bridges = graph.bridges()
    #expect(bridges.count == 1)
  }

  // MARK: - Parallel edges

  @Test
  func parallelEdgesAreNotBridges() {
    // Two nodes connected by two distinct edges: neither is a bridge
    // (removing one leaves the other as an alternate route).
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: a, to: b)  // parallel edge

    #expect(graph.bridges().isEmpty, "Parallel edges should not be bridges")
  }

  @Test
  func parallelEdgeInOtherwiseBridgePosition() {
    // a - b (two parallel edges) - c (single edge). The a-b parallel pair
    // is not a bridge; the b-c edge is.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: a, to: b)  // parallel
    graph.addUndirectedEdge(from: b, to: c)

    let bridges = graph.bridges()
    #expect(bridges.count == 1, "Expected only b-c as a bridge, got \(bridges.count)")
    let bridge = bridges[0]
    let endpoints = Set([bridge.from.index, bridge.to.index])
    #expect(endpoints == Set([b.index, c.index]))
  }

  // MARK: - Disconnected graph

  @Test
  func bridgesAcrossDisconnectedComponents() {
    // Two separate chains: each edge in each chain is a bridge.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    graph.addUndirectedEdge(from: a, to: b)
    let c = graph.createNode(at: Coordinate3D(latitude: 11.0, longitude: 21.0))
    let d = graph.createNode(at: Coordinate3D(latitude: 11.05, longitude: 21.05))
    graph.addUndirectedEdge(from: c, to: d)

    #expect(graph.bridges().count == 2)
  }

  // MARK: - Real network

  @Test
  func immenstadtBridgesAreActuallyBridges() throws {
    // Every edge reported as a bridge must, when removed, actually
    // disconnect its component.
    let graph = try GraphTestHelper.immenstadtGraph()
    let bridges = graph.bridges()
    #expect(bridges.isNotEmpty, "Real network should have some bridges")

    // Verify a sample of bridges by removing each and checking that the
    // component count increases.
    let originalComponentCount = graph.connectedComponents.count
    var verified = 0
    for bridge in bridges.prefix(20) {
      var modified = graph
      modified.removeUndirectedEdge(from: bridge.from, to: bridge.to)
      let newCount = modified.connectedComponents.count
      #expect(newCount > originalComponentCount, "Bridge removal did not disconnect: \(bridge)")
      verified += 1
    }
    #expect(verified > 0)
  }

  @Test
  func immenstadtNonBridgesStayConnected() throws {
    // Spot-check that a non-bridge edge (one NOT in the bridge set) does
    // not disconnect the graph when removed.
    let graph = try GraphTestHelper.immenstadtGraph()
    let bridgeKeys = Set(graph.bridges().map { BridgeEdgeKey(a: $0.from.index, b: $0.to.index) })
    let originalComponentCount = graph.connectedComponents.count

    // Find an undirected edge that is not a bridge.
    var foundNonBridge = false
    outer: for edgeList in graph.adjacencyList {
      for edge in edgeList.edges {
        let key = BridgeEdgeKey(a: edge.from.index, b: edge.to.index)
        if !bridgeKeys.contains(key) {
          var modified = graph
          modified.removeUndirectedEdge(from: edge.from, to: edge.to)
          #expect(
            modified.connectedComponents.count == originalComponentCount,
            "Non-bridge edge removal disconnected the graph")
          foundNonBridge = true
          break outer
        }
      }
    }
    #expect(foundNonBridge, "Expected at least one non-bridge edge in the network")
  }

  // MARK: - Projection coverage

  @Test
  func bridgesAcrossProjections() {
    let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978, .noSRID]

    for projection in projections {
      // Triangle (no bridges) + a tail (one bridge).
      var graph = Graph(nodeTolerance: 1.0)
      let a = graph.createNode(
        at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(to: projection))
      let b = graph.createNode(
        at: Coordinate3D(latitude: 10.05, longitude: 20.05).projected(to: projection))
      let c = graph.createNode(
        at: Coordinate3D(latitude: 10.05, longitude: 20.0).projected(to: projection))
      let d = graph.createNode(
        at: Coordinate3D(latitude: 10.0, longitude: 20.05).projected(to: projection))
      graph.addUndirectedEdge(from: a, to: b)
      graph.addUndirectedEdge(from: b, to: c)
      graph.addUndirectedEdge(from: c, to: a)  // triangle
      graph.addUndirectedEdge(from: a, to: d)  // bridge to leaf d

      let bridges = graph.bridges()
      #expect(bridges.count == 1, "projection \(projection): got \(bridges.count)")
      let endpoints = Set([bridges[0].from.index, bridges[0].to.index])
      #expect(endpoints == Set([a.index, d.index]), "projection \(projection)")
    }
  }

  // MARK: - Antimeridian

  @Test
  func bridgesAcrossAntimeridian() {
    // Two cycles straddling the antimeridian, joined by a bridge that
    // crosses the dateline.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: -179.95))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 179.9))
    let e = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: -179.95))
    let f = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: -179.9))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)  // cycle 1
    graph.addUndirectedEdge(from: d, to: e)
    graph.addUndirectedEdge(from: e, to: f)
    graph.addUndirectedEdge(from: f, to: d)  // cycle 2
    graph.addUndirectedEdge(from: c, to: d)  // bridge across dateline

    let bridges = graph.bridges()
    #expect(bridges.count == 1, "Expected 1 antimeridian bridge, got \(bridges.count)")
    let endpoints = Set([bridges[0].from.index, bridges[0].to.index])
    #expect(endpoints == Set([c.index, d.index]))
  }

  // MARK: - Directed graphs

  @Test
  func directedOneWayBridge() {
    // One-way chain A -> B -> C in a directed graph: every one-way edge is
    // a weak-connectivity bridge (treating one-way as undirected).
    let oneway1 = Feature(
      LineString([
        Coordinate3D(latitude: 10.0, longitude: 20.0),
        Coordinate3D(latitude: 10.05, longitude: 20.05),
      ])!,
      properties: ["oneway": "yes"])
    let oneway2 = Feature(
      LineString([
        Coordinate3D(latitude: 10.05, longitude: 20.05),
        Coordinate3D(latitude: 10.1, longitude: 20.1),
      ])!,
      properties: ["oneway": "yes"])

    let directed = Graph(
      featureCollection: FeatureCollection([oneway1, oneway2]),
      isDirected: true)

    let bridges = directed.bridges()
    #expect(bridges.count == 2, "Expected both one-way edges as weak bridges, got \(bridges.count)")
  }

  @Test
  func directedTwoWayCycleNoBridge() {
    // Directed graph with a two-way cycle: no bridges (the cycle provides
    // alternate routes in the weak-connectivity sense).
    let twoway = Feature(
      LineString([
        Coordinate3D(latitude: 10.0, longitude: 20.0),
        Coordinate3D(latitude: 10.05, longitude: 20.05),
        Coordinate3D(latitude: 10.05, longitude: 20.0),
        Coordinate3D(latitude: 10.0, longitude: 20.0),
      ])!)

    let directed = Graph(
      featureCollection: FeatureCollection([twoway]),
      isDirected: true)

    #expect(directed.bridges().isEmpty, "Two-way cycle should have no bridges")
  }

  // MARK: - Support

  /// Normalized undirected edge key used only for test-side comparisons.
  private struct BridgeEdgeKey: Hashable {

    let a: Int
    let b: Int

    init(a: Int, b: Int) {
      self.a = min(a, b)
      self.b = max(a, b)
    }

  }

}
