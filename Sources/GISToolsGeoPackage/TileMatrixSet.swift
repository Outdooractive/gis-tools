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
    /// - Parameters:
    ///   - tableName: The tile table name.
    ///   - srsId: The spatial reference system identifier.
    ///   - bounds: The spatial extent in CRS units.
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
