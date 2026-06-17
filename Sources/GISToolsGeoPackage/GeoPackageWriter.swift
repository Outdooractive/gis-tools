import Foundation
import GISTools
import CSQLite

extension FeatureCollection {

    /// Writes the FeatureCollection to a GeoPackage (.gpkg) file.
    ///
    /// - Parameters:
    ///   - url: The file URL to write to.
    ///   - table: The name of the feature table to create (default `"features"`).
    /// - Throws: A ``GeoPackageError`` if the file cannot be written.
    public func writeGeopackage(to url: URL, table: String = "features") throws {
        // Remove existing file to start fresh
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        let db = try SQLiteDB(path: url.path)
        try GeoPackage.createMetadata(in: db)
        try GeoPackageWriter.writeFeatures(self, to: db, table: table)
    }

}

// MARK: - Writer

private enum GeoPackageWriter {

    static func writeFeatures(_ fc: FeatureCollection, to db: SQLiteDB, table: String) throws {
        let features = fc.features
        guard !features.isEmpty else {
            throw GeoPackageError.invalidGeoPackage("Cannot write empty FeatureCollection")
        }

        // Determine geometry type from the first feature
        let firstGeoType = features[0].geometry.type
        let geoTypeName: String
        let hasMixedTypes = features.contains { $0.geometry.type != firstGeoType }
        if hasMixedTypes {
            geoTypeName = "GEOMETRY"
        } else {
            geoTypeName = GeoPackage.geometryTypeName(for: firstGeoType)
        }

        let projection = features[0].projection
        let srsId = GeoPackage.srsId(for: projection)

        // Collect all property keys with their inferred types
        let propertySchema = inferPropertySchema(from: features)

        // Create the feature table
        var createColumns: [String] = []
        var geomColumnName = "geom"

        createColumns.append("\"\(geomColumnName)\" \(geoTypeName)")

        for (key, colType) in propertySchema {
            createColumns.append("\"\(key)\" \(colType)")
        }

        let createSQL = "CREATE TABLE \"\(table)\" (\(createColumns.joined(separator: ", ")));"
        try db.execute(createSQL)

        // Compute bounding box
        var minX = Double.infinity
        var minY = Double.infinity
        var maxX = -Double.infinity
        var maxY = -Double.infinity

        // Insert features
        let colNames = createColumns.map { colDef in
            // Extract bare column name from "\"name\" TYPE"
            colDef.trimmingCharacters(in: .whitespaces)
                .split(separator: " ", maxSplits: 1)
                .first?
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                ?? "geom"
        }
        let colNamesQuoted = colNames.map { "\"\($0)\"" }.joined(separator: ", ")
        let placeholders = createColumns.map { _ in "?" }.joined(separator: ", ")
        let insertSQL = "INSERT INTO \"\(table)\" (\(colNamesQuoted)) VALUES (\(placeholders));"

        for feature in features {
            let geometry = feature.geometry
            let projection = feature.projection

            // Encode geometry to WKB and prepend GeoPackage header
            guard let wkb = WKBCoder.encode(geometry: geometry, byteOrder: .littleEndian, targetProjection: nil) else {
                continue
            }

            // Calculate envelope from geometry
            let envelope = geometry.boundingBox ?? geometry.calculateBoundingBox()
            let headerWkb = WKBHeader.prependHeader(to: wkb, srid: srsId, envelope: envelope)

            // Update bounding box
            if let envelope {
                minX = min(minX, envelope.southWest.longitude)
                minY = min(minY, envelope.southWest.latitude)
                maxX = max(maxX, envelope.northEast.longitude)
                maxY = max(maxY, envelope.northEast.latitude)
            }

            // Build values array
            var values: [Any] = [headerWkb]
            for (key, _) in propertySchema {
                values.append(feature.properties[key] as Any)
            }

            // Insert via prepared statement
            try insertRow(db: db, sql: insertSQL, values: values)
        }

        // Write metadata
        try writeContentsMetadata(db: db, table: table, srsId: srsId, minX: minX, minY: minY, maxX: maxX, maxY: maxY, projection: projection)
        try writeGeometryColumnsMetadata(db: db, table: table, geomColumnName: geomColumnName, geoTypeName: geoTypeName, srsId: srsId)
    }

    // MARK: - Metadata

    private static func writeContentsMetadata(
        db: SQLiteDB, table: String, srsId: Int,
        minX: Double, minY: Double, maxX: Double, maxY: Double,
        projection: Projection
    ) throws {
        let identifier = table
        try db.execute(
            "INSERT INTO gpkg_contents (table_name, data_type, identifier, srs_id, min_x, min_y, max_x, max_y) VALUES ('\(table)', 'features', '\(identifier)', \(srsId), \(minX), \(minY), \(maxX), \(maxY));")
    }

    private static func writeGeometryColumnsMetadata(
        db: SQLiteDB, table: String, geomColumnName: String, geoTypeName: String, srsId: Int
    ) throws {
        try db.execute(
            "INSERT INTO gpkg_geometry_columns (table_name, column_name, geometry_type_name, srs_id, z, m) VALUES ('\(table)', '\(geomColumnName)', '\(geoTypeName)', \(srsId), 0, 0);")
    }

    // MARK: - Schema inference

    /// Infer column types from feature properties.
    private static func inferPropertySchema(from features: [Feature]) -> [(String, String)] {
        var allKeys = Set<String>()
        for f in features {
            for key in f.properties.keys {
                allKeys.insert(key)
            }
        }

        var result: [(String, String)] = []
        for key in allKeys.sorted() {
            let sampleValue = features.compactMap { $0.properties[key] }.first
            let colType = sqliteType(for: sampleValue)
            result.append((key, colType))
        }
        return result
    }

    private static func sqliteType(for value: Any?) -> String {
        guard let value else { return "TEXT" }
        switch value {
        case is Bool: return "BOOLEAN"
        case is Int, is Int64: return "INTEGER"
        case is Double, is Float: return "REAL"
        case is String: return "TEXT"
        default: return "TEXT"
        }
    }

    // MARK: - Row insertion

    private static func insertRow(db: SQLiteDB, sql: String, values: [Any]) throws {
        var stmt: OpaquePointer?
        let sqlCString = (sql as NSString).utf8String
        let rc = sqlite3_prepare_v2(db.db, sqlCString, -1, &stmt, nil)
        guard rc == 0, let stmt else {  // SQLITE_OK
            let err = String(cString: sqlite3_errmsg(db.db))
            throw GeoPackageError.sqliteError("Failed to prepare insert: \(err)")
        }
        defer { sqlite3_finalize(stmt) }

        for (i, value) in values.enumerated() {
            try SQLiteDB.bind(stmt, index: Int32(i + 1), value: value)
        }

        let stepRC = sqlite3_step(stmt)
        guard stepRC == 101 else {  // SQLITE_DONE
            let err = String(cString: sqlite3_errmsg(db.db))
            throw GeoPackageError.sqliteError("Failed to insert row: \(err)")
        }
    }

}


