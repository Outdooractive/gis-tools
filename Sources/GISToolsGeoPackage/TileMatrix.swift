import Foundation
import GISTools

/// Metadata for a single zoom level in a tile pyramid.
public struct TileMatrix: Sendable {

    /// The tile table name in the GeoPackage.
    public let tableName: String

    /// The zoom level (0 = whole world in one tile).
    public let zoomLevel: Int

    /// Number of tile columns (x direction).
    public let matrixWidth: Int

    /// Number of tile rows (y direction).
    public let matrixHeight: Int

    /// Width of each tile in pixels.
    public let tileWidth: Int

    /// Height of each tile in pixels.
    public let tileHeight: Int

    /// Horizontal pixel size (in CRS units per pixel).
    public let pixelXSize: Double

    /// Vertical pixel size (in CRS units per pixel).
    public let pixelYSize: Double

    /// Creates a tile matrix for a single zoom level.
    /// - Parameters:
    ///   - tableName: The tile table name.
    ///   - zoomLevel: The zoom level (0 = whole world).
    ///   - matrixWidth: Number of tile columns.
    ///   - matrixHeight: Number of tile rows.
    ///   - tileWidth: Tile width in pixels (default 256).
    ///   - tileHeight: Tile height in pixels (default 256).
    ///   - pixelXSize: Horizontal pixel size in CRS units per pixel.
    ///   - pixelYSize: Vertical pixel size in CRS units per pixel.
    public init(
        tableName: String,
        zoomLevel: Int,
        matrixWidth: Int,
        matrixHeight: Int,
        tileWidth: Int = 256,
        tileHeight: Int = 256,
        pixelXSize: Double,
        pixelYSize: Double
    ) {
        self.tableName = tableName
        self.zoomLevel = zoomLevel
        self.matrixWidth = matrixWidth
        self.matrixHeight = matrixHeight
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.pixelXSize = pixelXSize
        self.pixelYSize = pixelYSize
    }

}
