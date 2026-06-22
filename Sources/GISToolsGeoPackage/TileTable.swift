import Foundation
import GISTools

/// A complete tile table descriptor including metadata and tile data.
public struct TileTable: Sendable {

    /// The tile matrix set (spatial extent + SRS).
    public let matrixSet: TileMatrixSet

    /// One entry per zoom level.
    public let matrices: [TileMatrix]

    /// Raw tile blobs keyed by (zoom, column, row).
    public let tiles: [TileKey: Data]

    /// Creates a tile table descriptor.
    public init(
        matrixSet: TileMatrixSet,
        matrices: [TileMatrix],
        tiles: [TileKey: Data]
    ) {
        self.matrixSet = matrixSet
        self.matrices = matrices
        self.tiles = tiles
    }

}

/// A tile locator within a tile pyramid.
public struct TileKey: Hashable, Sendable {

    /// The zoom level.
    public let zoom: Int

    /// The tile column (x, TMS convention: 0 at left).
    public let column: Int

    /// The tile row (y, TMS convention: 0 at bottom).
    public let row: Int

    /// Creates a tile key.
    public init(zoom: Int, column: Int, row: Int) {
        self.zoom = zoom
        self.column = column
        self.row = row
    }

    /// Creates a tile key from a MapTile (XYZ convention).
    ///
    /// Converts the XYZ y-coordinate (0 = top) to TMS (0 = bottom).
    ///
    /// - Parameters:
    ///   - mapTile: The map tile in XYZ convention.
    ///   - matrixHeight: The total number of tile rows at this zoom level.
    public init(
        from mapTile: MapTile,
        matrixHeight: Int
    ) {
        self.zoom = mapTile.z
        self.column = mapTile.x
        self.row = mapTile.tmsRow(matrixHeight: matrixHeight)
    }

}
