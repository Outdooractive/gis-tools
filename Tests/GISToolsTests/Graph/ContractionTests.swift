import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
  import CoreLocation
#endif

/// ``Graph/contracted()`` and ``Graph/expandPath(_:using:)`` tests.
///
/// Chain contraction removes degree-2 pass-through nodes and merges their
/// edges (summed weight). It must preserve topology, total route length, and
/// connectivity, and expansion must reconstruct the original chain.
/// Coverage spans synthetic graphs, the real-world Immenstadt network, all
/// supported projections, antimeridian-crossing geometries, and directed
/// graphs (one-way edges preserved).
struct ContractionTests {

  // MARK: - Basic contraction

  @Test
  func contractsStraightChain() throws {
    // a - b - c - d: b and c are degree-2 chain nodes -> removed.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: 20.15))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: d)

    let result = try #require(graph.contracted())
    #expect(result.graph.nodeCount == 2, "Expected 2 nodes, got \(result.graph.nodeCount)")
    // The two endpoints a and d survive.
    let survivorIndices = Set(result.originalIndices)
    #expect(survivorIndices.contains(a.index))
    #expect(survivorIndices.contains(d.index))
    // b and c are gone.
    #expect(result.contractedIndexOfOriginal[b.index] == nil)
    #expect(result.contractedIndexOfOriginal[c.index] == nil)
  }

  @Test
  func mergedEdgeWeightIsSum() throws {
    // a - b - c: contraction merges a-b-c into a single a-c edge whose
    // weight equals a-b + b-c.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)

    let result = try #require(graph.contracted())
    let weight = result.graph.weight(
      from: result.graph.nodes[0],
      to: result.graph.nodes[1])
    let originalAB = graph.weight(from: a, to: b)!
    let originalBC = graph.weight(from: b, to: c)!
    #expect(weight != nil)
    #expect(
      abs(weight! - (originalAB + originalBC)) < 0.001,
      "Merged weight \(weight!) should equal sum \(originalAB + originalBC)")
  }

  @Test
  func preservesBranchNodes() throws {
    // Star: b is a hub (degree 3), not contractible. The arms are leaves
    // (degree 1) and not contractible either. So nothing is removed.
    var graph = Graph()
    let center = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let n1 = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    let n2 = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.05))
    let n3 = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    graph.addUndirectedEdge(from: center, to: n1)
    graph.addUndirectedEdge(from: center, to: n2)
    graph.addUndirectedEdge(from: center, to: n3)

    let result = try #require(graph.contracted())
    #expect(result.graph.nodeCount == 4, "Expected no contraction, got \(result.graph.nodeCount)")
  }

  @Test
  func emptyGraphReturnsNil() {
    let graph = Graph()
    #expect(graph.contracted() == nil)
  }

  @Test
  func contractsNoOpWhenAlreadyMinimal() throws {
    // Two nodes, one edge: nothing to contract.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    graph.addUndirectedEdge(from: a, to: b)

    let result = try #require(graph.contracted())
    #expect(result.graph.nodeCount == 2)
  }

  @Test
  func contractsLongChain() throws {
    // a - b - c - d - e - f: only b,c,d,e are degree-2 -> contracted to a-f.
    var graph = Graph()
    let coords = (0...5).map { i in
      Coordinate3D(latitude: 10.0 + Double(i) * 0.01, longitude: 20.0)
    }
    let nodes = coords.map { graph.createNode(at: $0) }
    for i in 0..<nodes.count - 1 {
      graph.addUndirectedEdge(from: nodes[i], to: nodes[i + 1])
    }

    let result = try #require(graph.contracted())
    #expect(result.graph.nodeCount == 2, "Got \(result.graph.nodeCount)")
    #expect(result.originalIndices.contains(nodes.first!.index))
    #expect(result.originalIndices.contains(nodes.last!.index))
  }

  // MARK: - Connectivity / topology preservation

  @Test
  func contractedGraphPreservesConnectivity() throws {
    // Triangle with an extra chain node: a - b - c - a, plus a - d - c.
    // The triangle's three nodes (a, b, c) each have adjacent neighbors, so
    // none is contracted (the cycle is preserved). Node d has neighbors
    // a and c that are already adjacent, so d is also preserved. The graph
    // stays at 4 nodes — contraction never destroys existing cycles or
    // creates parallel edges.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)  // triangle
    graph.addUndirectedEdge(from: a, to: d)
    graph.addUndirectedEdge(from: d, to: c)  // a-d-c, but a and c are adjacent

    let result = try #require(graph.contracted())
    #expect(
      result.graph.nodeCount == 4,
      "Expected no contraction (cycle preserved), got \(result.graph.nodeCount)")
    // Connectivity is trivially preserved: nothing changed.
    let path = result.graph.shortestPath(
      from: result.graph.node(withIndex: 0)!,
      to: result.graph.node(withIndex: 1)!)
    #expect(path.count == 2, "Expected direct edge still present: \(path)")
  }

  @Test
  func contractionCollapsesChainButNotCycle() throws {
    // a-b-c-d-a square (no diagonal) + d-e-f spur.
    // In the square, the candidate path a-b-c has both ends anchored on the
    // *same* node d. Removing it would collapse the cycle, so the square is
    // preserved entirely (a,b,c,d all kept). Only the spur's interior node
    // e is removed (its anchors d and f are distinct), collapsing d-e-f to
    // a single d-f edge. Routing stays correct: every original shortest
    // path cost is preserved.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.1))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.0))
    let e = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: 20.0))
    let f = graph.createNode(at: Coordinate3D(latitude: 10.2, longitude: 20.0))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: d)
    graph.addUndirectedEdge(from: d, to: a)  // square
    graph.addUndirectedEdge(from: d, to: e)
    graph.addUndirectedEdge(from: e, to: f)  // spur

    let result = try #require(graph.contracted())
    // Square preserved (4 nodes) + spur collapsed (e removed) = 5 nodes.
    #expect(result.graph.nodeCount == 5, "Expected 5 nodes, got \(result.graph.nodeCount)")
    #expect(result.contractedIndexOfOriginal[e.index] == nil, "Spur interior e should be removed")
    // All square nodes survive.
    for node in [a, b, c, d, f] {
      #expect(
        result.contractedIndexOfOriginal[node.index] != nil, "Node \(node.index) should survive")
    }

    // The spur's merged d-f edge weight equals d-e + e-f.
    let contractedD = result.graph.nodes[result.contractedIndexOfOriginal[d.index]!]
    let contractedF = result.graph.nodes[result.contractedIndexOfOriginal[f.index]!]
    let mergedWeight = result.graph.weight(from: contractedD, to: contractedF)!
    let originalSpur = graph.weight(from: d, to: e)! + graph.weight(from: e, to: f)!
    #expect(abs(mergedWeight - originalSpur) < 0.001, "Spur merge weight mismatch")

    // Routing on the contracted graph must give the same cost as the
    // original for an arbitrary pair.
    let origStart = a
    let origEnd = f
    guard let cStart = result.contractedIndexOfOriginal[origStart.index],
      let cEnd = result.contractedIndexOfOriginal[origEnd.index]
    else {
      Issue.record("Endpoint mapping failed")
      return
    }
    let contractedPath = result.graph.shortestPath(
      from: result.graph.node(withIndex: cStart)!,
      to: result.graph.node(withIndex: cEnd)!)
    #expect(contractedPath.isNotEmpty)
    let expanded = try #require(graph.expandPath(contractedPath, using: result))
    let originalPath = graph.shortestPath(from: origStart, to: origEnd)
    #expect(
      abs(graph.length(ofPath: expanded) - graph.length(ofPath: originalPath)) < 0.001,
      "Contracted route \(graph.length(ofPath: expanded))m != original \(graph.length(ofPath: originalPath))m"
    )
  }

  // MARK: - Path expansion

  @Test
  func expandPathReconstructsChain() throws {
    // a - b - c - d contracted to a - d. Expanding a-d path yields a-b-c-d.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.1, longitude: 20.1))
    let d = graph.createNode(at: Coordinate3D(latitude: 10.15, longitude: 20.15))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: d)

    let result = try #require(graph.contracted())
    let contractedPath = result.graph.shortestPath(
      from: result.graph.nodes[0],
      to: result.graph.nodes[1])
    #expect(contractedPath.count == 2)

    let expanded = try #require(graph.expandPath(contractedPath, using: result))
    #expect(expanded.count == 4, "Expanded path should have 4 nodes, got \(expanded.count)")
    #expect(expanded.first == a)
    #expect(expanded.last == d)
    #expect(Set(expanded.map(\.index)) == Set([a, b, c, d].map(\.index)))
  }

  @Test
  func expandPathPreservesTotalLength() throws {
    // The total length of an expanded path must equal the original
    // (uncontracted) shortest path length.
    var graph = Graph()
    let nodes = (0...5).map { i in
      Coordinate3D(latitude: 10.0 + Double(i) * 0.01, longitude: 20.0)
    }.map { graph.createNode(at: $0) }
    for i in 0..<nodes.count - 1 {
      graph.addUndirectedEdge(from: nodes[i], to: nodes[i + 1])
    }

    let result = try #require(graph.contracted())
    let contractedPath = result.graph.shortestPath(
      from: result.graph.nodes[0],
      to: result.graph.nodes[1])
    let expanded = try #require(graph.expandPath(contractedPath, using: result))

    let originalPath = graph.shortestPath(from: nodes.first!, to: nodes.last!)
    #expect(
      abs(graph.length(ofPath: expanded) - graph.length(ofPath: originalPath)) < 0.001,
      "Expanded length should match original")
  }

  // MARK: - Routing on the contracted graph

  @Test
  func contractedRoutingMatchesOriginalCost() throws {
    // On the real Immenstadt network, the contracted graph should produce
    // the same shortest-path cost as the original (just faster and with
    // fewer nodes).
    let graph = try GraphTestHelper.immenstadtGraph()
    let component = graph.connectedComponents.max(by: { $0.count < $1.count })!
    let start = component.first!
    let end = component.last!

    let originalPath = graph.shortestPath(from: start, to: end)
    let originalLength = graph.length(ofPath: originalPath)

    let result = try #require(graph.contracted())
    #expect(result.graph.nodeCount < graph.nodeCount, "Contraction should reduce node count")

    // Map original endpoints to contracted nodes.
    guard let contractedStart = result.contractedIndexOfOriginal[start.index],
      let contractedEnd = result.contractedIndexOfOriginal[end.index]
    else {
      Issue.record("Endpoint not found in contracted graph")
      return
    }

    let contractedPath = result.graph.shortestPath(
      from: result.graph.node(withIndex: contractedStart)!,
      to: result.graph.node(withIndex: contractedEnd)!)
    #expect(contractedPath.isNotEmpty)
    let expanded = try #require(graph.expandPath(contractedPath, using: result))
    let expandedLength = graph.length(ofPath: expanded)

    #expect(
      abs(originalLength - expandedLength) < 5.0,
      "Contracted route length \(expandedLength)m != original \(originalLength)m")
  }

  // MARK: - Projection coverage

  @Test
  func contractionAcrossProjections() throws {
    let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978, .noSRID]

    for projection in projections {
      var graph = Graph(nodeTolerance: 1.0)
      let a = graph.createNode(
        at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(to: projection))
      let b = graph.createNode(
        at: Coordinate3D(latitude: 10.05, longitude: 20.05).projected(to: projection))
      let c = graph.createNode(
        at: Coordinate3D(latitude: 10.1, longitude: 20.1).projected(to: projection))
      graph.addUndirectedEdge(from: a, to: b)
      graph.addUndirectedEdge(from: b, to: c)

      let result = try #require(graph.contracted())
      #expect(result.graph.nodeCount == 2, "projection \(projection): \(result.graph.nodeCount)")
      #expect(result.contractedIndexOfOriginal[b.index] == nil)

      let weight = result.graph.weight(
        from: result.graph.nodes[0],
        to: result.graph.nodes[1])!
      let original = graph.weight(from: a, to: b)! + graph.weight(from: b, to: c)!
      #expect(abs(weight - original) < 0.001, "projection \(projection) weight mismatch")
    }
  }

  // MARK: - Antimeridian

  @Test
  func contractionAcrossAntimeridian() throws {
    // a (179.9) - b (-179.95) - c (-179.9): b is degree-2 across the
    // dateline and should be contracted; the merged edge a-c must still
    // span the antimeridian.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.95))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)

    let result = try #require(graph.contracted())
    #expect(result.graph.nodeCount == 2)
    #expect(result.contractedIndexOfOriginal[b.index] == nil)

    let weight = result.graph.weight(
      from: result.graph.nodes[0],
      to: result.graph.nodes[1])!
    let original = graph.weight(from: a, to: b)! + graph.weight(from: b, to: c)!
    #expect(abs(weight - original) < 1.0, "Antimeridian merged weight mismatch")
  }

  // MARK: - Directed graphs

  @Test
  func directedOneWayEdgesNotContracted() throws {
    // One-way chain A -> B -> C: B has one outgoing + one incoming
    // directed edge, but our contraction only handles undirected (two-way)
    // pass-through nodes, so nothing is removed. This preserves one-way
    // routing correctness.
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

    let result = try #require(directed.contracted())
    #expect(result.graph.nodeCount == 3, "One-way nodes should not be contracted")
  }

  @Test
  func directedTwoWayChainStillContracted() throws {
    // In a directed graph, a two-way chain (no oneway tag) is still stored
    // as undirected edges and should still be contracted.
    let twoway1 = Feature(
      LineString([
        Coordinate3D(latitude: 10.0, longitude: 20.0),
        Coordinate3D(latitude: 10.05, longitude: 20.05),
      ])!)
    let twoway2 = Feature(
      LineString([
        Coordinate3D(latitude: 10.05, longitude: 20.05),
        Coordinate3D(latitude: 10.1, longitude: 20.1),
      ])!)

    let directed = Graph(
      featureCollection: FeatureCollection([twoway1, twoway2]),
      isDirected: true)

    let result = try #require(directed.contracted())
    #expect(
      result.graph.nodeCount == 2, "Two-way chain should be contracted even in directed graph")
  }

}
