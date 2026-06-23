import Foundation
import GISTools

/// Metadata for a table listed in `gpkg_contents`.
public struct GeoPackageTable: Sendable {

    /// The table name in the GeoPackage.
    public let tableName: String

    /// The data type (e.g. `"features"` or `"tiles"`).
    public let dataType: String

    /// An optional human-readable identifier.
    public let identifier: String?

    /// An optional description.
    public let description: String?

    /// The spatial reference system identifier, if set.
    public let srsId: Int?

    /// The spatial extent, if set.
    public let bounds: BoundingBox?

    /// Creates a GeoPackage table descriptor.
    /// - Parameters:
    ///   - tableName: The table name in the GeoPackage.
    ///   - dataType: The data type (e.g. `"features"` or `"tiles"`).
    ///   - identifier: An optional human-readable identifier.
    ///   - description: An optional description.
    ///   - srsId: The spatial reference system identifier.
    ///   - bounds: The spatial extent.
    public init(
        tableName: String,
        dataType: String,
        identifier: String? = nil,
        description: String? = nil,
        srsId: Int? = nil,
        bounds: BoundingBox? = nil
    ) {
        self.tableName = tableName
        self.dataType = dataType
        self.identifier = identifier
        self.description = description
        self.srsId = srsId
        self.bounds = bounds
    }

}
