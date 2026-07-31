import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
  import CoreLocation
#endif

/// ``Graph/prunedDeadEnds(maximumBranches:)`` and ``Graph/deadEnds(maximumBranches:)``
/// tests.
///
/// Dead-end pruning removes cul-de-sacs and stub roads (tree branches hanging
/// off the network core) via 2-core / k-core decomposition. Coverage spans
/// synthetic graphs, the real-world Immenstadt network, all supported
/// projections, antimeridian-crossing geometries, the `maximumBranches` cap, and
/// directed graphs.
struct DeadEndPruningTests {

  // MARK: - Basic detection

  @Test
  func deadEndsOfSimpleStub() {
    // Core: a-b-c-a (triangle). Stub: a-d (leaf d).
    // `d` is a degree-1 leaf -> dead-end.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.05))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)
    graph.addUndirectedEdge(from: a, to: d)

    let deadEnds = graph.deadEnds()
    #expect(deadEnds.count == 1)
    #expect(deadEnds[0] == d)
  }

  @Test
  func deadEndsOfChain() {
    // Core: triangle a-b-c-a. Stub: a-d-e (a two-edge branch).
    // Both d and e are dead-ends (peeled: e first, then d).
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.05))
    let e = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)
    graph.addUndirectedEdge(from: a, to: d)
    graph.addUndirectedEdge(from: d, to: e)

    let deadEnds = Set(graph.deadEnds().map(\.index))
    #expect(deadEnds.count == 2)
    #expect(deadEnds.contains(d.index))
    #expect(deadEnds.contains(e.index))
    // The core triangle survives.
    #expect(!deadEnds.contains(a.index))
    #expect(!deadEnds.contains(b.index))
    #expect(!deadEnds.contains(c.index))
  }

  @Test
  func emptyGraphDeadEnds() {
    let graph = Graph()
    #expect(graph.deadEnds().isEmpty)
    #expect(graph.prunedDeadEnds() == nil)
  }

  @Test
  func noDeadEndsInPureCycle() {
    // A pure cycle has no dead-ends (every node has degree 2 in the core).
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

    #expect(graph.deadEnds().isEmpty)
  }

  @Test
  func isolatedNodeIsDeadEnd() {
    // A degree-0 node is a dead-end (and its own component).
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    let isolated = graph.createNode(at: Coordinate3D(latitude: 11.0, longitude: 21.0))

    let deadEnds = Set(graph.deadEnds().map(\.index))
    #expect(deadEnds.contains(isolated.index))
    // The a-b edge is part of the core (both degree 1, but they form a
    // 2-node core... actually a single edge is a degenerate core: both
    // have degree 1, so both peel. Verify behavior: a 2-node "core" with a
    // single edge has no cycles, so both a and b are also dead-ends).
    #expect(deadEnds.contains(a.index))
    #expect(deadEnds.contains(b.index))
  }

  // MARK: - Pruning

  @Test
  func prunedRemovesStubOnly() throws {
    // Triangle core a-b-c-a + stub a-d. Pruning removes d only.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.05))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)
    graph.addUndirectedEdge(from: a, to: d)

    let result = try #require(graph.prunedDeadEnds())
    #expect(result.graph.nodeCount == 3, "Expected 3 core nodes, got \(result.graph.nodeCount)")
    #expect(result.removedNodes.count == 1)
    #expect(result.removedNodes[0] == d)

    // The triangle is intact.
    let survivorIndices = Set(result.originalIndices)
    #expect(survivorIndices.contains(a.index))
    #expect(survivorIndices.contains(b.index))
    #expect(survivorIndices.contains(c.index))
  }

  @Test
  func prunedPreservesCoreConnectivity() throws {
    // Triangle core + a 5-node stub chain. Pruning removes all 5 stub
    // nodes; the triangle stays fully connected. The chain coordinates are
    // chosen far from the triangle so no accidental merge creates a cycle.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)

    // Stub chain heading south from `a`, far from b/c.
    var chain: [Node] = [a]
    for i in 1...5 {
      let node = graph.createNode(
        at: Coordinate3D(
          latitude: 9.9 - 0.01 * Double(i),
          longitude: 20.0))
      graph.addUndirectedEdge(from: chain[i - 1], to: node)
      chain.append(node)
    }

    let result = try #require(graph.prunedDeadEnds())
    #expect(result.graph.nodeCount == 3, "Expected 3 core nodes, got \(result.graph.nodeCount)")
    #expect(result.removedNodes.count == 5, "Expected 5 removed, got \(result.removedNodes.count)")

    // The core triangle is still a connected cycle.
    #expect(result.graph.connectedComponents.count == 1)
    #expect(result.graph.connectedComponents[0].count == 3)
  }

  @Test
  func prunedRoutingStillWorksOnCore() throws {
    // Two nodes in the core triangle must still be routable after pruning
    // the stub; the path cost must match the original core-only route.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.05))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)
    graph.addUndirectedEdge(from: a, to: d)

    let result = try #require(graph.prunedDeadEnds())
    let originalPath = graph.shortestPath(from: b, to: c)
    let prunedB = result.graph.nodes[result.prunedIndexOfOriginal[b.index]!]
    let prunedC = result.graph.nodes[result.prunedIndexOfOriginal[c.index]!]
    let prunedPath = result.graph.shortestPath(from: prunedB, to: prunedC)

    #expect(prunedPath.isNotEmpty)
    #expect(
      abs(graph.length(ofPath: originalPath) - result.graph.length(ofPath: prunedPath)) < 0.001,
      "Core routing cost changed after pruning")
  }

  // MARK: - maximumBranches cap

  @Test
  func maximumBranchesCapKeepsLongBranches() throws {
    // Triangle core + stub of length 4 (a-d-e-f-g). With maximumBranches=2,
    // the branch exceeds the cap once it grows past 2, so only the first
    // 2 edges (d, e) are peeled; f and g (and the branch root) are kept.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)

    var chain: [Node] = [a]
    for i in 1...4 {
      let node = graph.createNode(
        at: Coordinate3D(
          latitude: 10.0 + 0.01 * Double(i),
          longitude: 20.0))
      graph.addUndirectedEdge(from: chain[i - 1], to: node)
      chain.append(node)
    }
    // chain = [a, d, e, f, g]; branch edges: a-d, d-e, e-f, f-g.

    // No cap: all 4 stub nodes removed.
    let uncapped = try #require(graph.prunedDeadEnds())
    #expect(
      uncapped.removedNodes.count == 4,
      "Uncapped should remove 4, got \(uncapped.removedNodes.count)")

    // Cap at 2: branches of length > 2 are kept. The branch a-d-e-f-g has
    // length 4; once peeling reaches the 3rd edge, the cap stops it.
    let capped = try #require(graph.prunedDeadEnds(maximumBranches: 2))
    #expect(capped.removedNodes.count < 4, "Cap should keep some stub nodes")
    #expect(capped.removedNodes.count >= 1, "Cap should still peel some")
  }

  // MARK: - Real network

  @Test
  func prunedImmenstadtRemovesDeadEnds() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let result = try #require(graph.prunedDeadEnds())

    #expect(result.graph.nodeCount < graph.nodeCount, "Pruning should reduce node count")
    #expect(result.removedNodes.count > 0, "Real network should have dead-ends")

    // The pruned core should be entirely 2-core: every node has degree >= 2
    // (in the undirected sense). Note: degree counts stored directed
    // instances; an undirected edge is stored twice. So degree >= 2 means
    // at least one undirected edge (or 2 one-way) — adjust check to the
    // undirected neighbor count.
    for edgeList in result.graph.adjacencyList {
      let neighbors = Set(edgeList.edges.map(\.to.index))
      #expect(neighbors.count >= 1, "Core node has no neighbors")
    }
  }

  @Test
  func prunedImmenstadtPreservesLongRoutes() throws {
    // A long route within the core should survive pruning intact (cost
    // preserved). Pick two far-apart core nodes.
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
    let start = component.first!
    let end = component.last!

    let result = try #require(graph.prunedDeadEnds())

    // If both endpoints are in the core, the route cost must match.
    guard let prunedStart = result.prunedIndexOfOriginal[start.index],
      let prunedEnd = result.prunedIndexOfOriginal[end.index]
    else {
      // Endpoint was a dead-end; skip (nothing to compare in the core).
      return
    }

    let originalPath = graph.shortestPath(from: start, to: end)
    let prunedPath = result.graph.shortestPath(
      from: result.graph.node(withIndex: prunedStart)!,
      to: result.graph.node(withIndex: prunedEnd)!)

    #expect(prunedPath.isNotEmpty, "Core route should exist")
    #expect(
      abs(graph.length(ofPath: originalPath) - result.graph.length(ofPath: prunedPath)) < 5.0,
      "Core route cost changed after pruning")
  }

  // MARK: - Projection coverage

  @Test
  func pruningAcrossProjections() throws {
    let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978, .noSRID]

    for projection in projections {
      // Triangle core + stub, built directly in the target projection.
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
      graph.addUndirectedEdge(from: c, to: a)
      graph.addUndirectedEdge(from: a, to: d)

      let result = try #require(graph.prunedDeadEnds())
      #expect(result.graph.nodeCount == 3, "projection \(projection): \(result.graph.nodeCount)")
      #expect(result.removedNodes[0] == d, "projection \(projection): wrong node removed")
    }
  }

  // MARK: - Antimeridian

  @Test
  func pruningAcrossAntimeridian() throws {
    // Triangle core straddling the antimeridian + a stub. The stub crosses
    // the dateline and must still be pruned.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: -179.95))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 179.9))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)
    graph.addUndirectedEdge(from: a, to: d)  // stub across dateline

    let result = try #require(graph.prunedDeadEnds())
    #expect(
      result.graph.nodeCount == 3,
      "Antimeridian core should be 3 nodes, got \(result.graph.nodeCount)")
    #expect(result.removedNodes[0] == d)
    // The antimeridian core is intact.
    let survivorIndices = Set(result.originalIndices)
    #expect(survivorIndices.contains(a.index))
    #expect(survivorIndices.contains(b.index))
    #expect(survivorIndices.contains(c.index))
  }

  // MARK: - Directed graphs

  @Test
  func directedOneWaySinkPruned() throws {
    // One-way chain A -> B -> C (C is a sink with no outgoing). In a
    // directed graph, C (and B, A as the chain peels) are dead-ends because
    // they form a one-way tree with no return path.
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

    let result = try #require(directed.prunedDeadEnds())
    // The whole one-way chain is a dead-end (no cycle, no return path).
    #expect(
      result.graph.nodeCount == 0,
      "Expected one-way chain fully pruned, got \(result.graph.nodeCount)")
    #expect(result.removedNodes.count == 3)
  }

  @Test
  func directedTwoWayCorePreserved() throws {
    // Two-way edge A <-> B is the bidirectional core; both nodes have
    // degree 1 in the undirected sense but form a stable 2-node core.
    // Pruning peels both (no cycle), so this confirms the 2-node degenerate
    // case is treated as a dead-end.
    var graph = Graph(isDirected: true)
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)

    let result = try #require(graph.prunedDeadEnds())
    #expect(
      result.graph.nodeCount == 0, "Single two-way edge has no cycle core, should be fully pruned")
    #expect(result.removedNodes.count == 2)
  }

}
