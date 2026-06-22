import Foundation
import GISTools

extension FeatureCollection {

    /// Creates a FeatureCollection from a GeoPackage (.gpkg) file.
    ///
    /// - Parameters:
    ///   - url: The file URL of the GeoPackage database.
    ///   - table: The name of the feature table to read (default `"features"`).
    ///   - boundingBox: An optional bounding box to filter features. When
    ///     set and the GeoPackage has a spatial (rtree) index, only
    ///     features within or intersecting the bounding box are returned.
    /// - Throws: A ``GeoPackageError`` if the file cannot be read or is invalid.
    public init(
        geopackage url: URL,
        table: String = "features",
        boundingBox: BoundingBox? = nil
    ) throws {
        let db = try SQLiteDB(path: url.path)
        try GeoPackage.validateMetadata(in: db)
        let features = try GeoPackageReader.readFeatures(
            from: db,
            table: table,
            boundingBox: boundingBox)
        self.init(features)
    }

}

// MARK: - Reader

private enum GeoPackageReader {

    static func readFeatures(
        from db: SQLiteDB,
        table: String,
        boundingBox: BoundingBox? = nil
    ) throws -> [Feature] {
        // Get geometry column metadata
        let escapedTable = GeoPackage.sanitizeStringLiteral(table)
        let quotedTable = GeoPackage.sanitizeIdentifier(table)
        let geomCols = try db.query(
            "SELECT column_name, geometry_type_name, srs_id, z, m FROM gpkg_geometry_columns WHERE table_name = \(escapedTable);")

        guard let geomMeta = geomCols.first else {
            throw GeoPackageError.invalidGeoPackage("Table '\(table)' not found in gpkg_geometry_columns")
        }

        guard geomCols.count == 1 else {
            throw GeoPackageError.mixedGeometryTypes("Table '\(table)' has multiple geometry columns")
        }

        let geomColumnName = geomMeta["column_name"] as? String ?? "geom"
        let srsId = geomMeta["srs_id"] as? Int ?? 4326

        // Get all column info from the feature table
        let tableInfo = try db.query("PRAGMA table_info(\(quotedTable));")
        let columnNames: [String] = tableInfo.compactMap { $0["name"] as? String }

        guard !columnNames.isEmpty else {
            throw GeoPackageError.invalidGeoPackage("Table '\(table)' has no columns")
        }

        // Resolve row IDs — use rtree index when available
        let rowIds: [Int]?
        if let bbox = boundingBox {
            if try GeoPackage.hasRTreeIndex(for: table, column: geomColumnName, in: db) {
                rowIds = try Self.readRowIdsFromRTree(
                    db: db,
                    table: table,
                    column: geomColumnName,
                    boundingBox: bbox)
            }
            else {
                // No rtree — nil signals in-memory filter below
                rowIds = nil
            }
        }
        else {
            rowIds = nil
        }

        // Build the SQL query
        let rows: [[String: Sendable]]
        if let rowIds,
           !rowIds.isEmpty,
           boundingBox != nil
        {
            let idList = rowIds.map(String.init).joined(separator: ", ")
            rows = try db.query("SELECT * FROM \(quotedTable) WHERE rowid IN (\(idList));")
        }
        else {
            rows = try db.query("SELECT * FROM \(quotedTable);")
        }

        var features: [Feature] = []
        for row in rows {
            guard let wkbData = try extractGeometryBlob(from: row, columnName: geomColumnName, db: db, table: table) else {
                continue
            }

            let header = try WKBHeader.parse(wkbData)
            let geoJson = try WKBCoder.decode(wkb: header.wkbData, sourceSrid: header.srid)

            let projection = GeoPackage.projection(for: srsId)
            let projectedGeoJson = geoJson.projected(to: projection)
            let geometry = projectedGeoJson

            var properties: [String: Sendable] = [:]
            for col in columnNames where col != geomColumnName {
                guard let value = row[col] else { continue }
                if let data = value as? Data {
                    properties[col] = data.base64EncodedString()
                }
                else {
                    properties[col] = value
                }
            }

            let feature = Feature(geometry, properties: properties)
            features.append(feature)
        }

        // If we couldn't use rtree but a bounding box was requested,
        // filter in memory as a fallback
        if let bbox = boundingBox,
           rowIds == nil
        {
            features = features.filter { $0.intersects(bbox) }
        }

        return features
    }

    /// Queries the rtree virtual table for rowids intersecting a bounding box.
    private static func readRowIdsFromRTree(
        db: SQLiteDB,
        table: String,
        column: String,
        boundingBox: BoundingBox
    ) throws -> [Int]? {
        let rtreeName = GeoPackage.rTreeTableName(for: table, column: column)
        let minX = boundingBox.southWest.longitude
        let minY = boundingBox.southWest.latitude
        let maxX = boundingBox.northEast.longitude
        let maxY = boundingBox.northEast.latitude

        let rows = try db.query("""
            SELECT id FROM \(rtreeName)
            WHERE minx <= \(maxX)
              AND maxx >= \(minX)
              AND miny <= \(maxY)
              AND maxy >= \(minY);
            """)
        return rows.compactMap { $0["id"] as? Int }
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
