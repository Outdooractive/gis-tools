#if EnableGraphAPI
#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Graph partitioning (rectangular tiling)

extension Graph {

    /// One rectangular tile produced by ``partition(intoGridRows:columns:)``.
    public struct Partition: Sendable {

        /// The subgraph contained in this tile: all nodes whose coordinates
        /// fall inside the tile's bounding box, plus every edge whose **both**
        /// endpoints are in the tile.
        public let graph: Graph

        /// The tile's bounding box in the graph's projection.
        public let bounds: BoundingBox

        /// 0-based row index (`0` is the southernmost row).
        public let row: Int

        /// 0-based column index (`0` is the westernmost column).
        public let column: Int

        /// For each node index in `graph`, the original node index it
        /// represents.
        public let originalIndices: [Int]

        /// Edges that cross from this tile to a neighboring tile (one endpoint
        /// in this tile, the other in another partition). Each entry records
        /// the original source/destination node indices and the connecting
        /// edge, so partitions can be stitched back into a single graph.
        public let crossTileEdges: [CrossTileEdge]

    }

    /// A directed edge that straddles two tiles, recorded so partitioned
    /// graphs can be recombined without losing connectivity.
    public struct CrossTileEdge: Sendable {

        /// The original node index of the endpoint that lives **inside** the
        /// partition owning this edge.
        public let localOriginalIndex: Int

        /// The original node index of the endpoint that lives in a **different**
        /// partition.
        public let remoteOriginalIndex: Int

        /// The connecting edge.
        public let edge: Edge

        /// The (row, column) of the partition the remote endpoint belongs to,
        /// or `nil` if it lies outside the grid.
        public let remoteTile: (row: Int, column: Int)?

    }

    /// Splits the graph into a `rows × columns` grid of rectangular tiles for
    /// parallel or tile-based processing (e.g. the vector-tile workflow).
    ///
    /// Each node is assigned to the tile containing its coordinate. A partition
    /// contains all of its nodes plus every edge whose **both** endpoints fall
    /// in the same tile. Edges crossing tile boundaries are returned as
    /// ``Partition/crossTileEdges`` so callers can stitch partitions back into
    /// a single graph. Every original node appears in exactly one partition;
    /// every edge appears in exactly one partition (if internal) or in one
    /// partition's `crossTileEdges` (if crossing).
    ///
    /// Tiles are laid out over the graph's bounding box with even spacing. A
    /// node exactly on a tile boundary is assigned to the tile to its
    /// north/east (the half-open interval `[min, max)`), except the very last
    /// row/column which is closed on both ends to include the maximum
    /// coordinate.
    ///
    /// - Parameters:
    ///   - rows: Number of grid rows (must be >= 1).
    ///   - columns: Number of grid columns (must be >= 1).
    /// - Returns: A 2-D array of partitions (`partitions[row][column]`), or an
    ///   empty array if the graph has no nodes or the grid dimensions are
    ///   invalid.
    public func partition(
        intoGridRows rows: Int,
        columns: Int
    ) -> [[Partition]] {
        guard rows >= 1,
              columns >= 1,
              adjacencyList.isNotEmpty,
              let tiling = RectangularTiling(
                  nodes: adjacencyList.map(\.node),
                  rows: rows,
                  columns: columns)
        else { return [] }

        // Build the inverse map: original index -> (row, column).
        var nodeTile: [(row: Int, column: Int)] = []
        nodeTile.reserveCapacity(adjacencyList.count)
        for edgeList in adjacencyList {
            nodeTile.append(tiling.tile(for: edgeList.node.coordinate))
        }

        // Collect per-tile original node indices and build the compact
        // original->partition index mapping.
        var tileNodes: [[[Int]]] = Array(
            repeating: Array(repeating: [], count: columns),
            count: rows)
        var partitionIndexOfOriginal: [Int?] = Array(
            repeating: nil,
            count: adjacencyList.count)
        for originalIndex in 0..<adjacencyList.count {
            let (row, column) = nodeTile[originalIndex]
            partitionIndexOfOriginal[originalIndex] = tileNodes[row][column].count
            tileNodes[row][column].append(originalIndex)
        }

        // Build each partition's graph and cross-tile edges.
        var partitions: [[Partition]] = []
        partitions.reserveCapacity(rows)
        for row in 0..<rows {
            var partitionRow: [Partition] = []
            partitionRow.reserveCapacity(columns)
            for column in 0..<columns {
                let originalIndices = tileNodes[row][column]
                let partitionGraph = buildPartitionGraph(
                    originalIndices: originalIndices,
                    partitionIndexOfOriginal: partitionIndexOfOriginal,
                    nodeTile: nodeTile,
                    tileRow: row,
                    tileColumn: column)
                let crossTile = collectCrossTileEdges(
                    originalIndices: originalIndices,
                    nodeTile: nodeTile)
                let bounds = tiling.bounds(row: row, column: column)
                partitionRow.append(
                    Partition(
                        graph: partitionGraph,
                        bounds: bounds,
                        row: row,
                        column: column,
                        originalIndices: originalIndices,
                        crossTileEdges: crossTile))
            }
            partitions.append(partitionRow)
        }

        return partitions
    }

    // MARK: - Partition internals

    /// Builds the subgraph for a tile: relabels its nodes compactly and keeps
    /// only edges whose both endpoints are in this tile.
    private func buildPartitionGraph(
        originalIndices: [Int],
        partitionIndexOfOriginal: [Int?],
        nodeTile: [(row: Int, column: Int)],
        tileRow: Int,
        tileColumn: Int
    ) -> Graph {
        var edgeLists: [Graph.EdgeList] = []
        for originalIndex in originalIndices {
            let node = adjacencyList[originalIndex].node
            edgeLists.append(
                EdgeList(
                    node: Node(
                        index: edgeLists.count,
                        coordinate: node.coordinate)))
        }

        for (localIndex, originalIndex) in originalIndices.enumerated() {
            let fromNode = edgeLists[localIndex].node
            for edge in adjacencyList[originalIndex].edges {
                let toOriginal = edge.to.index
                guard let toLocal = partitionIndexOfOriginal[toOriginal] else {
                    continue
                }
                // Keep only edges that stay within this tile. Reverse edges for
                // undirected connections are emitted by the other endpoint's
                // iteration, so emit each stored directed edge as-is.
                let (toRow, toColumn) = nodeTile[toOriginal]
                guard toRow == tileRow, toColumn == tileColumn else { continue }
                let toNode = edgeLists[toLocal].node
                edgeLists[localIndex].edges.append(
                    Edge(
                        from: fromNode,
                        to: toNode,
                        feature: edge.feature,
                        isDirected: edge.isDirected,
                        weight: edge.weight))
            }
        }

        var partition = Graph(
            nodeTolerance: nodeTolerance,
            isDirected: isDirected,
            onewayProperty: onewayProperty)
        partition.adjacencyList = edgeLists
        partition.hasDirectedEdges = hasDirectedEdges

        if let firstCoord = edgeLists.first?.node.coordinate {
            partition.spatialIndex = SpatialIndex(
                tolerance: nodeTolerance,
                referenceLatitude: firstCoord.latitude)
            for newIndex in edgeLists.indices {
                partition.spatialIndex.insert(
                    nodeIndex: newIndex,
                    coordinate: edgeLists[newIndex].node.coordinate)
            }
        }
        else {
            partition.spatialIndex = SpatialIndex(
                tolerance: nodeTolerance,
                referenceLatitude: 0.0)
        }

        return partition
    }

    /// Collects edges that cross from this tile to a different tile: one
    /// endpoint local, the other remote.
    private func collectCrossTileEdges(
        originalIndices: [Int],
        nodeTile: [(row: Int, column: Int)]
    ) -> [CrossTileEdge] {
        var edges: [CrossTileEdge] = []
        var seen: Set<IndexPair> = []
        for originalIndex in originalIndices {
            for edge in adjacencyList[originalIndex].edges {
                let toOriginal = edge.to.index
                let (toRow, toColumn) = nodeTile[toOriginal]
                let (localRow, localColumn) = nodeTile[originalIndex]
                guard toRow != localRow || toColumn != localColumn else {
                    continue
                }

                // Deduplicate undirected pairs (each stored twice).
                let pair = IndexPair(a: originalIndex, b: toOriginal)
                if !edge.isDirected,
                   !seen.insert(pair).inserted
                {
                    continue
                }

                edges.append(
                    CrossTileEdge(
                        localOriginalIndex: originalIndex,
                        remoteOriginalIndex: toOriginal,
                        edge: edge,
                        remoteTile: (row: toRow, column: toColumn)))
            }
        }
        return edges
    }

    // MARK: - Partition support types

    /// Shared rectangular tiling used by ``partition(intoGridRows:columns:)``
    /// and the multi-level routing index.
    ///
    /// The tile assignment is half-open on the lower/western edge and closed on
    /// the upper/eastern edge, except the last row/column which includes the
    /// maximum coordinate.
    struct RectangularTiling: Sendable {

        let rows: Int
        let columns: Int
        let minLat: Double
        let maxLat: Double
        let minLon: Double
        let maxLon: Double
        let rowHeight: Double
        let columnWidth: Double
        let projection: Projection

        init?(nodes: [Node], rows: Int, columns: Int) {
            guard rows >= 1,
                  columns >= 1,
                  let first = nodes.first
            else { return nil }

            var minLat = Double.infinity
            var maxLat = -Double.infinity
            var minLon = Double.infinity
            var maxLon = -Double.infinity
            for node in nodes {
                let coordinate = node.coordinate
                minLat = min(minLat, coordinate.latitude)
                maxLat = max(maxLat, coordinate.latitude)
                minLon = min(minLon, coordinate.longitude)
                maxLon = max(maxLon, coordinate.longitude)
            }

            guard minLat.isFinite,
                  maxLat.isFinite,
                  minLon.isFinite,
                  maxLon.isFinite
            else { return nil }

            let latSpan = max(maxLat - minLat, 0.0)
            let lonSpan = max(maxLon - minLon, 0.0)

            self.rows = rows
            self.columns = columns
            self.minLat = minLat
            self.maxLat = maxLat
            self.minLon = minLon
            self.maxLon = maxLon
            self.rowHeight = latSpan == 0.0 ? 0.0 : latSpan / Double(rows)
            self.columnWidth = lonSpan == 0.0 ? 0.0 : lonSpan / Double(columns)
            self.projection = first.coordinate.projection
        }

        func tile(for coordinate: Coordinate3D) -> (row: Int, column: Int) {
            let lat = coordinate.latitude
            let lon = coordinate.longitude

            var row: Int {
                if rowHeight == 0.0 || lat >= maxLat {
                    return rows - 1
                }
                let value = Int((lat - minLat) / rowHeight)
                return min(max(value, 0), rows - 1)
            }
            var column: Int {
                if columnWidth == 0.0 || lon >= maxLon {
                    return columns - 1
                }
                let value = Int((lon - minLon) / columnWidth)
                return min(max(value, 0), columns - 1)
            }
            return (row, column)
        }

        /// Constructs the bounding box for a tile. The last row/column is
        /// closed on its upper/eastern edge (includes `maxLat`/`maxLon`);
        /// intermediate tiles are closed on their lower/western edge and open
        /// on the upper/eastern edge.
        func bounds(row: Int, column: Int) -> BoundingBox {
            let south = minLat + Double(row) * rowHeight
            let north = (row == rows - 1) ? maxLat : minLat + Double(row + 1) * rowHeight
            let west = minLon + Double(column) * columnWidth
            let east = (column == columns - 1) ? maxLon : minLon + Double(column + 1) * columnWidth
            let southWest = Coordinate3D(x: west, y: south, projection: projection)
            let northEast = Coordinate3D(x: east, y: north, projection: projection)
            return BoundingBox(southWest: southWest, northEast: northEast)
        }

    }

    struct IndexPair: Hashable {

        let a: Int
        let b: Int

        init(a: Int, b: Int) {
            self.a = min(a, b)
            self.b = max(a, b)
        }

    }

}
#endif
