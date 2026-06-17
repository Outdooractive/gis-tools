import Foundation
import GISTools

extension FeatureCollection {

    /// Creates a FeatureCollection from a GeoPackage (.gpkg) file.
    ///
    /// - Parameters:
    ///   - url: The file URL of the GeoPackage database.
    ///   - table: The name of the feature table to read (default `"features"`).
    /// - Throws: A ``GeoPackageError`` if the file cannot be read or is invalid.
    public init(geopackage url: URL, table: String = "features") throws {
        let db = try SQLiteDB(path: url.path)
        try GeoPackage.validateMetadata(in: db)
        let features = try GeoPackageReader.readFeatures(from: db, table: table)
        self.init(features)
    }

}

// MARK: - Reader

private enum GeoPackageReader {

    static func readFeatures(from db: SQLiteDB, table: String) throws -> [Feature] {
        // Get geometry column metadata
        let geomCols = try db.query(
            "SELECT column_name, geometry_type_name, srs_id, z, m FROM gpkg_geometry_columns WHERE table_name = '\(table)';")

        guard let geomMeta = geomCols.first else {
            throw GeoPackageError.invalidGeoPackage("Table '\(table)' not found in gpkg_geometry_columns")
        }

        guard geomCols.count == 1 else {
            throw GeoPackageError.mixedGeometryTypes("Table '\(table)' has multiple geometry columns")
        }

        let geomColumnName = geomMeta["column_name"] as? String ?? "geom"
        let srsId = geomMeta["srs_id"] as? Int ?? 4326

        // Get all column info from the feature table
        let tableInfo = try db.query("PRAGMA table_info('\(table)');")
        let columnNames: [String] = tableInfo.compactMap { $0["name"] as? String }

        guard !columnNames.isEmpty else {
            throw GeoPackageError.invalidGeoPackage("Table '\(table)' has no columns")
        }

        // Read all rows
        let rows: [[String: Sendable]] = try db.query("SELECT * FROM \"\(table)\";")

        var features: [Feature] = []
        for row in rows {
            guard let wkbData = try extractGeometryBlob(from: row, columnName: geomColumnName, db: db, table: table) else {
                continue
            }

            // Parse the geometry
            let header = try WKBHeader.parse(wkbData)
            let geoJson = try WKBCoder.decode(wkb: header.wkbData, sourceSrid: header.srid)

            // Determine target projection from the table's SRS
            let projection = GeoPackage.projection(for: srsId)
            let projectedGeoJson = geoJson.projected(to: projection)

            let geometry = projectedGeoJson

            // Build properties
            var properties: [String: Sendable] = [:]
            for col in columnNames where col != geomColumnName {
                guard let value = row[col] else { continue }
                if let data = value as? Data {
                    properties[col] = data.base64EncodedString()
                } else {
                    properties[col] = value
                }
            }

            let feature = Feature(geometry, properties: properties)
            features.append(feature)
        }

        return features
    }

    private static func extractGeometryBlob(
        from row: [String: Sendable],
        columnName: String,
        db: SQLiteDB,
        table: String
    ) throws -> Data? {
        row[columnName] as? Data
    }

}
