import Foundation
import GISTools

/// Metadata describing a tile pyramid stored in a GeoPackage table.
public struct TileMatrixSet: Sendable {

    /// The tile table name in the GeoPackage.
    public let tableName: String

    /// The spatial reference system identifier.
    public let srsId: Int

    /// The spatial extent of the tile pyramid (in CRS units).
    public let bounds: BoundingBox

    /// Creates a tile matrix set.
    public init(
        tableName: String,
        srsId: Int,
        bounds: BoundingBox
    ) {
        self.tableName = tableName
        self.srsId = srsId
        self.bounds = bounds
    }

}
