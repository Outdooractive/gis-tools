import Foundation
import Testing

@testable import GISTools

#if canImport(CoreLocation)
  import CoreLocation
#endif

/// ``Graph/partition(intoGridRows:columns:)`` tests.
///
/// Graph partitioning splits the graph into a rectangular grid of tiles for
/// parallel or tile-based processing. Each node lands in exactly one tile;
/// internal edges stay within their tile, and cross-tile edges are reported
/// separately for stitching. Coverage spans synthetic grids, the real-world
/// Immenstadt network, all supported projections, antimeridian-spanning
/// graphs, and the round-trip (recombining partitions recovers the original).
struct PartitioningTests {

  // MARK: - Basic tiling

  @Test
  func partitionShapeMatchesGrid() {
    // 3x3 grid of nodes -> partition into 3x3 should give 9 single-node
    // tiles.
    var graph = Graph()
    for r in 0..<3 {
      for c in 0..<3 {
        let node = graph.createNode(
          at: Coordinate3D(
            latitude: 10.0 + Double(r) * 0.01,
            longitude: 20.0 + Double(c) * 0.01))
        // Connect each node to its right and down neighbor to add edges.
        if c > 0 {
          let left = graph.node(
            at: Coordinate3D(
              latitude: 10.0 + Double(r) * 0.01,
              longitude: 20.0 + Double(c - 1) * 0.01),
            tolerance: 1.0)!
          graph.addUndirectedEdge(from: left, to: node)
        }
        if r > 0 {
          let up = graph.node(
            at: Coordinate3D(
              latitude: 10.0 + Double(r - 1) * 0.01,
              longitude: 20.0 + Double(c) * 0.01),
            tolerance: 1.0)!
          graph.addUndirectedEdge(from: up, to: node)
        }
      }
    }

    let partitions = graph.partition(intoGridRows: 3, columns: 3)
    #expect(partitions.count == 3)
    #expect(partitions[0].count == 3)
    // Each tile has exactly one node.
    for row in partitions {
      for tile in row {
        #expect(tile.graph.nodeCount == 1, "Expected 1 node per tile, got \(tile.graph.nodeCount)")
      }
    }
  }

  @Test
  func partitionCoversAllNodes() throws {
    // Every original node must appear in exactly one partition.
    let graph = try GraphTestHelper.immenstadtGraph()
    let originalCount = graph.nodeCount
    let partitions = graph.partition(intoGridRows: 4, columns: 4)
    #expect(partitions.count == 4)

    var totalPartitioned = 0
    for row in partitions {
      for tile in row {
        totalPartitioned += tile.graph.nodeCount
      }
    }
    #expect(
      totalPartitioned == originalCount,
      "Partitioned \(totalPartitioned) != original \(originalCount)")
  }

  @Test
  func emptyGraphReturnsEmpty() {
    let graph = Graph()
    #expect(graph.partition(intoGridRows: 2, columns: 2).isEmpty)
  }

  @Test
  func invalidDimensionsReturnEmpty() {
    var graph = Graph()
    _ = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    #expect(graph.partition(intoGridRows: 0, columns: 2).isEmpty)
    #expect(graph.partition(intoGridRows: 2, columns: 0).isEmpty)
  }

  @Test
  func singleTileRecontainsWholeGraph() {
    // A 1x1 partition should contain every node and every edge.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))
    let b = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.05))
    let c = graph.createNode(at: Coordinate3D(latitude: 10.05, longitude: 20.0))
    graph.addUndirectedEdge(from: a, to: b)
    graph.addUndirectedEdge(from: b, to: c)
    graph.addUndirectedEdge(from: c, to: a)

    let partitions = graph.partition(intoGridRows: 1, columns: 1)
    #expect(partitions.count == 1)
    let tile = partitions[0][0]
    #expect(tile.graph.nodeCount == 3)
    // All edges internal (no cross-tile).
    #expect(tile.crossTileEdges.isEmpty)
    // Edge count: each undirected edge is stored twice.
    #expect(tile.graph.directedEdgeCount == 6)
  }

  // MARK: - Edge partitioning

  @Test
  func internalEdgesStayInTile() {
    // Two tiles, each with an internal edge; one edge crosses the boundary.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))  // tile (0,0)
    let b = graph.createNode(at: Coordinate3D(latitude: 10.01, longitude: 20.01))  // tile (0,0)
    let c = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.2))  // tile (0,1)
    let d = graph.createNode(at: Coordinate3D(latitude: 10.01, longitude: 20.21))  // tile (0,1)
    graph.addUndirectedEdge(from: a, to: b)  // internal to (0,0)
    graph.addUndirectedEdge(from: c, to: d)  // internal to (0,1)
    graph.addUndirectedEdge(from: b, to: c)  // crosses (0,0) -> (0,1)

    let partitions = graph.partition(intoGridRows: 1, columns: 2)
    #expect(partitions.count == 1)
    #expect(partitions[0].count == 2)
    let left = partitions[0][0]
    let right = partitions[0][1]

    #expect(left.graph.nodeCount == 2)
    #expect(right.graph.nodeCount == 2)
    // Each tile keeps its internal edge (stored twice per undirected edge).
    #expect(left.graph.directedEdgeCount == 2, "Left tile should keep the a-b edge")
    #expect(right.graph.directedEdgeCount == 2, "Right tile should keep the c-d edge")
    // The cross-tile b-c edge is reported in each tile's crossTileEdges
    // (once from each side, deduped to one entry).
    #expect(
      left.crossTileEdges.count == 1,
      "Left tile should have 1 cross edge, got \(left.crossTileEdges.count)")
    #expect(
      right.crossTileEdges.count == 1,
      "Right tile should have 1 cross edge, got \(right.crossTileEdges.count)")
  }

  @Test
  func crossTileEdgesReferenceRemotes() {
    // Verify the cross-tile edge records correct local/remote indices.
    var graph = Graph()
    let a = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.0))  // tile (0,0)
    let b = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 20.2))  // tile (0,1)
    graph.addUndirectedEdge(from: a, to: b)

    let partitions = graph.partition(intoGridRows: 1, columns: 2)
    let left = partitions[0][0]
    #expect(left.crossTileEdges.count == 1)
    let cross = left.crossTileEdges[0]
    #expect(cross.localOriginalIndex == a.index)
    #expect(cross.remoteOriginalIndex == b.index)
    #expect(cross.remoteTile?.column == 1)
    #expect(cross.remoteTile?.row == 0)
  }

  // MARK: - Round-trip recombination

  @Test
  func recombineRecoversOriginalEdges() throws {
    // Partition a graph, then verify that internal edges plus cross-tile
    // edges account for every original directed edge instance.
    //
    // Accounting: each original directed instance is either internal to a
    // tile (counted in `directedEdgeCount`) or crosses a boundary. An
    // undirected crossing edge has 2 directed instances, each reported
    // once by the tile of its source endpoint. A one-way crossing edge has
    // 1 directed instance, reported by its source tile. So summing
    // crossTileEdges across all tiles yields exactly the count of crossing
    // directed instances, and `internal + crossTotal == original`.
    let graph = try GraphTestHelper.immenstadtGraph()
    let originalDirectedEdgeCount = graph.directedEdgeCount
    let partitions = graph.partition(intoGridRows: 3, columns: 3)
    #expect(partitions.count == 3)

    var internalEdges = 0
    var crossEdges = 0
    for row in partitions {
      for tile in row {
        internalEdges += tile.graph.directedEdgeCount
        crossEdges += tile.crossTileEdges.count
      }
    }
    #expect(
      internalEdges + crossEdges == originalDirectedEdgeCount,
      "Internal \(internalEdges) + cross \(crossEdges) != original \(originalDirectedEdgeCount)")
  }

  // MARK: - Projection coverage

  @Test
  func partitionAcrossProjections() {
    let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978, .noSRID]

    for projection in projections {
      var graph = Graph(nodeTolerance: 1.0)
      let a = graph.createNode(
        at: Coordinate3D(latitude: 10.0, longitude: 20.0).projected(to: projection))
      let b = graph.createNode(
        at: Coordinate3D(latitude: 10.05, longitude: 20.05).projected(to: projection))
      let c = graph.createNode(
        at: Coordinate3D(latitude: 10.05, longitude: 20.0).projected(to: projection))
      graph.addUndirectedEdge(from: a, to: b)
      graph.addUndirectedEdge(from: b, to: c)
      graph.addUndirectedEdge(from: c, to: a)

      let partitions = graph.partition(intoGridRows: 2, columns: 2)
      #expect(partitions.count == 2, "projection \(projection)")
      #expect(partitions[0].count == 2, "projection \(projection)")

      // All nodes accounted for.
      var total = 0
      for row in partitions {
        for tile in row {
          total += tile.graph.nodeCount
        }
      }
      #expect(total == 3, "projection \(projection): \(total) nodes partitioned")
    }
  }

  // MARK: - Antimeridian

  @Test
  func partitionAcrossAntimeridian() {
    // Graph straddling the antimeridian: two nodes at +179.9/-179.9. Split
    // by longitude into 2 columns; each node lands in its own tile and the
    // connecting edge becomes cross-tile.
    var graph = Graph()
    let west = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: 179.9))
    let east = graph.createNode(at: Coordinate3D(latitude: 10.0, longitude: -179.9))
    graph.addUndirectedEdge(from: west, to: east)

    let partitions = graph.partition(intoGridRows: 1, columns: 2)
    #expect(partitions.count == 1)
    #expect(partitions[0].count == 2)

    var totalNodes = 0
    var crossCount = 0
    for tile in partitions[0] {
      totalNodes += tile.graph.nodeCount
      crossCount += tile.crossTileEdges.count
    }
    #expect(totalNodes == 2, "Both nodes must be partitioned across the dateline")
    #expect(
      crossCount == 2,
      "The dateline edge must be reported as cross-tile from both sides, got \(crossCount)")
  }

  // MARK: - Directed graphs

  @Test
  func directedOneWayEdgePartitioned() {
    // One-way edge A->B across a tile boundary: it is stored once in the
    // original graph (only in A's adjacency), so only the source tile
    // reports it as a cross-tile edge.
    let oneway = Feature(
      LineString([
        Coordinate3D(latitude: 10.0, longitude: 20.0),
        Coordinate3D(latitude: 10.0, longitude: 20.2),
      ])!,
      properties: ["oneway": "yes"])

    let directed = Graph(
      featureCollection: FeatureCollection([oneway]),
      isDirected: true)

    let partitions = directed.partition(intoGridRows: 1, columns: 2)
    #expect(partitions.count == 1)
    #expect(partitions[0].count == 2)
    let left = partitions[0][0]
    let right = partitions[0][1]
    #expect(left.graph.nodeCount == 1)
    #expect(right.graph.nodeCount == 1)
    // The directed one-way edge crosses the boundary and is reported only
    // from the source tile (A), since the edge is stored once.
    #expect(
      left.crossTileEdges.count == 1,
      "Source tile should report the cross edge, got \(left.crossTileEdges.count)")
    #expect(
      right.crossTileEdges.count == 0,
      "Destination tile has no outgoing cross edge, got \(right.crossTileEdges.count)")
  }

  // MARK: - Real network

  @Test
  func immenstadtPartitionBalancesNodes() throws {
    let graph = try GraphTestHelper.immenstadtGraph()
    let partitions = graph.partition(intoGridRows: 4, columns: 4)
    #expect(partitions.count == 4)
    #expect(partitions[0].count == 4)

    // No tile should be empty (the network spans the whole bbox).
    var emptyTiles = 0
    for row in partitions {
      for tile in row {
        if tile.graph.nodeCount == 0 { emptyTiles += 1 }
      }
    }
    #expect(emptyTiles == 0, "Expected no empty tiles, got \(emptyTiles)")

    // Tile bounds should tile the full bbox without gaps.
    // (Sanity: the union of column widths covers the longitude range.)
    let topRow = partitions[0]
    let westLeft = topRow.first!.bounds.southWest.longitude
    let eastRight = topRow.last!.bounds.northEast.longitude
    #expect(eastRight > westLeft, "Tile row should span west to east")
  }

}
