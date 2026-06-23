import Foundation
import GISTools

// MARK: - Errors

public enum GeoPackageError: LocalizedError {

    /// The GeoPackage database file could not be opened.
    /// - Parameter path: The file path.
    /// - Parameter detail: The underlying SQLite error message.
    case couldNotOpenDatabase(path: String, detail: String)

    /// An SQLite operation returned an unexpected error.
    /// - Parameter detail: The error message from SQLite.
    case sqliteError(detail: String)

    /// The file is not a valid GeoPackage or violates the spec.
    /// - Parameter detail: A description of the violation.
    case invalidGeoPackage(detail: String)

    /// A feature table has more than one geometry column, which is not supported.
    /// - Parameter detail: A description of the conflict.
    case mixedGeometryTypes(detail: String)

    /// The stored WKB geometry data could not be parsed.
    /// - Parameter detail: A description of the parsing failure.
    case invalidWKB(detail: String)

    /// A geometry type used in the file is not supported by this library.
    /// - Parameter type: The unsupported type name.
    case unsupportedGeometryType(type: String)

    public var errorDescription: String? {
        switch self {
        case .couldNotOpenDatabase(let path, let detail):
            "Could not open GeoPackage database at \(path): \(detail)"
        case .sqliteError(let detail):
            "SQLite error: \(detail)"
        case .invalidGeoPackage(let detail):
            "Invalid GeoPackage: \(detail)"
        case .mixedGeometryTypes(let detail):
            "Mixed geometry types: \(detail)"
        case .invalidWKB(let detail):
            "Invalid WKB geometry: \(detail)"
        case .unsupportedGeometryType(let detail):
            "Unsupported geometry type: \(detail)"
        }
    }
}

// MARK: - GeoPackage metadata

/// Manages the mandatory GeoPackage metadata tables.
enum GeoPackage {

    /// The minimum GeoPackage version supported.
    static let supportedVersion = "1.2.0"

    /// Standard WKB geometry type codes per GeoPackage spec.
    enum GeometryType: String, CaseIterable {
        case geometryCollection = "GEOMETRYCOLLECTION"
        case point = "POINT"
        case lineString = "LINESTRING"
        case polygon = "POLYGON"
        case multiPoint = "MULTIPOINT"
        case multiLineString = "MULTILINESTRING"
        case multiPolygon = "MULTIPOLYGON"

        static func from(wkbType: UInt8) -> GeometryType? {
            switch wkbType {
            case 0: return .geometryCollection
            case 1: return .point
            case 2: return .lineString
            case 3: return .polygon
            case 4: return .multiPoint
            case 5: return .multiLineString
            case 6: return .multiPolygon
            case 7: return .geometryCollection
            default: return nil
            }
        }
    }

    // MARK: - SQL constants

    static let applicationIdGP10: Int32 = 1196437808  // "GP10" (GeoPackage spec default)
    static let applicationIdGPKG: Int32 = 1196444487  // "GPKG" (used by GDAL)
    static let userVersion: Int32 = 10200  // 1.2.0

    /// SQL to create the mandatory GeoPackage metadata tables.
    static let createMetadataSQL = """
        CREATE TABLE IF NOT EXISTS gpkg_spatial_ref_sys (
            srs_id INTEGER PRIMARY KEY,
            srs_name TEXT NOT NULL,
            srs_type TEXT NOT NULL,
            organization TEXT NOT NULL,
            organization_coordsys_id INTEGER NOT NULL,
            definition TEXT NOT NULL,
            description TEXT
        );

        CREATE TABLE IF NOT EXISTS gpkg_contents (
            table_name TEXT NOT NULL PRIMARY KEY,
            data_type TEXT NOT NULL,
            identifier TEXT,
            description TEXT DEFAULT '',
            last_change DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%S.000Z','now')),
            min_x DOUBLE,
            min_y DOUBLE,
            max_x DOUBLE,
            max_y DOUBLE,
            srs_id INTEGER,
            CONSTRAINT fk_gc_srs FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys(srs_id)
        );

        CREATE TABLE IF NOT EXISTS gpkg_geometry_columns (
            table_name TEXT NOT NULL,
            column_name TEXT NOT NULL,
            geometry_type_name TEXT NOT NULL,
            srs_id INTEGER NOT NULL,
            z TINYINT NOT NULL,
            m TINYINT NOT NULL,
            CONSTRAINT pk_geom_cols PRIMARY KEY (table_name, column_name),
            CONSTRAINT fk_gc_table FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name),
            CONSTRAINT fk_gc_srs FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys(srs_id)
        );

        CREATE TABLE IF NOT EXISTS gpkg_extensions (
            table_name TEXT,
            column_name TEXT,
            extension_name TEXT NOT NULL,
            definition TEXT NOT NULL,
            scope TEXT NOT NULL,
            CONSTRAINT ge_tce UNIQUE (table_name, column_name, extension_name)
        );

        CREATE TABLE IF NOT EXISTS gpkg_tile_matrix_set (
            table_name TEXT NOT NULL PRIMARY KEY,
            srs_id INTEGER NOT NULL,
            min_x DOUBLE NOT NULL,
            min_y DOUBLE NOT NULL,
            max_x DOUBLE NOT NULL,
            max_y DOUBLE NOT NULL,
            CONSTRAINT fk_gtms_table FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name),
            CONSTRAINT fk_gtms_srs FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys(srs_id)
        );

        CREATE TABLE IF NOT EXISTS gpkg_tile_matrix (
            table_name TEXT NOT NULL,
            zoom_level INTEGER NOT NULL,
            matrix_width INTEGER NOT NULL,
            matrix_height INTEGER NOT NULL,
            tile_width INTEGER NOT NULL,
            tile_height INTEGER NOT NULL,
            pixel_x_size DOUBLE NOT NULL,
            pixel_y_size DOUBLE NOT NULL,
            CONSTRAINT pk_ttm PRIMARY KEY (table_name, zoom_level),
            CONSTRAINT fk_ttm_table FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name)
        );

        CREATE TABLE IF NOT EXISTS gpkg_data_columns (
            table_name TEXT NOT NULL,
            column_name TEXT NOT NULL,
            name TEXT,
            title TEXT,
            description TEXT,
            mime_type TEXT,
            constraint_name TEXT,
            CONSTRAINT pk_data_columns PRIMARY KEY (table_name, column_name),
            CONSTRAINT fk_dc_table FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name)
        );

        CREATE TABLE IF NOT EXISTS gpkg_data_column_constraints (
            constraint_name TEXT NOT NULL,
            constraint_type TEXT NOT NULL,
            value TEXT,
            min_value DOUBLE,
            min_value_inclusive BOOLEAN,
            max_value DOUBLE,
            max_value_inclusive BOOLEAN,
            description TEXT,
            CONSTRAINT pk_data_col_constr PRIMARY KEY (constraint_name, constraint_type, value)
        );

        CREATE TABLE IF NOT EXISTS gpkgext_relations (
            id TEXT PRIMARY KEY,
            table_name TEXT NOT NULL,
            column_name TEXT NOT NULL,
            related_table_name TEXT NOT NULL,
            related_column_name TEXT NOT NULL,
            relation_name TEXT NOT NULL,
            mapping_table_name TEXT
        );
        """

    /// SQL to drop metadata tables (for cleanup).
    static let dropMetadataSQL = """
        DROP TABLE IF EXISTS gpkg_spatial_ref_sys;
        DROP TABLE IF EXISTS gpkg_contents;
        DROP TABLE IF EXISTS gpkg_geometry_columns;
        DROP TABLE IF EXISTS gpkg_extensions;
        DROP TABLE IF EXISTS gpkg_tile_matrix;
        DROP TABLE IF EXISTS gpkg_tile_matrix_set;
        DROP TABLE IF EXISTS gpkg_data_columns;
        DROP TABLE IF EXISTS gpkg_data_column_constraints;
        DROP TABLE IF EXISTS gpkgext_relations;
        """

    // MARK: - Schema setup

    /// Initialize a GeoPackage database with the mandatory metadata tables.
    static func createMetadata(in db: SQLiteDB) throws {
        // Set application ID and user version for GeoPackage identification
        try db.execute("PRAGMA application_id = \(applicationIdGP10);")
        try db.execute("PRAGMA user_version = \(userVersion);")
        try db.execute(createMetadataSQL)
        try insertDefaultSRS(db)
    }

    /// Validate that an existing database is a valid GeoPackage.
    static func validateMetadata(in db: SQLiteDB) throws {
        let appId = try db.query("PRAGMA application_id;")
        guard let first = appId.first,
              let raw = first["application_id"] as? Int,
              raw == Int(applicationIdGP10) || raw == Int(applicationIdGPKG)
        else {
            throw GeoPackageError.invalidGeoPackage(detail: "Not a GeoPackage file (invalid application_id)")
        }

        // Verify mandatory tables exist
        let tables = try db.query(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN"
            + " ('gpkg_spatial_ref_sys','gpkg_contents','gpkg_geometry_columns');")
        let tableNames = tables.compactMap { $0["name"] as? String }
        for required in ["gpkg_spatial_ref_sys", "gpkg_contents", "gpkg_geometry_columns"] {
            guard tableNames.contains(required) else {
                throw GeoPackageError.invalidGeoPackage(detail: "Missing mandatory table: \(required)")
            }
        }
    }

    // MARK: - Default SRS

    /// Insert the default Spatial Reference Systems used by this library.
    static func insertDefaultSRS(_ db: SQLiteDB) throws {
        let existing = try db.query("SELECT count(*) as cnt FROM gpkg_spatial_ref_sys;")
        if let first = existing.first, (first["cnt"] as? Int ?? 0) > 0 {
            return
        }

        let srs: [(srsId: Int, name: String, type: String, org: String, orgId: Int, def: String, desc: String?)] = [
            (4326, "WGS 84 geodetic", "geographic", "EPSG", 4326,
             "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AUTHORITY[\"EPSG\",\"4326\"]]",
             "WGS 84"),
            (3857, "WGS 84 / Pseudo-Mercator", "projected", "EPSG", 3857,
             "PROJCS[\"WGS 84 / Pseudo-Mercator\",GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AUTHORITY[\"EPSG\",\"4326\"]],PROJECTION[\"Mercator_1SP\"],PARAMETER[\"central_meridian\",0],PARAMETER[\"scale_factor\",1],PARAMETER[\"false_easting\",0],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH],AUTHORITY[\"EPSG\",\"3857\"]]",
             "WGS 84 / Pseudo-Mercator"),
            (4978, "WGS 84 / ECEF", "geocentric", "EPSG", 4978,
             "GEOCCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Geocentric X\",OTHER],AXIS[\"Geocentric Y\",OTHER],AXIS[\"Geocentric Z\",OTHER],AUTHORITY[\"EPSG\",\"4978\"]]",
             "WGS 84 / ECEF"),
        ]

        for s in srs {
            let desc = s.desc.map { "'\($0)'" } ?? "NULL"
            try db.execute(
                "INSERT INTO gpkg_spatial_ref_sys (srs_id, srs_name, srs_type, organization, organization_coordsys_id, definition, description) VALUES (\(s.srsId), '\(s.name)', '\(s.type)', '\(s.org)', \(s.orgId), '\(s.def.replacingOccurrences(of: "'", with: "''"))', \(desc));")
        }
    }

    // MARK: - SRS lookup

    /// Map a Projection to the corresponding GeoPackage SRS ID.
    static func srsId(for projection: Projection) -> Int {
        switch projection {
        case .epsg4326: return 4326
        case .epsg3857: return 3857
        case .epsg4978: return 4978
        case .noSRID: return 4326  // default
        }
    }

    /// Map a GeoPackage SRS ID to the library's Projection.
    static func projection(for srsId: Int) -> Projection {
        switch srsId {
        case 4326: return .epsg4326
        case 3857: return .epsg3857
        case 4978: return .epsg4978
        default: return .epsg4326
        }
    }

    /// Sanitize a SQL identifier (table name, column name) to prevent SQL injection.
    /// Wraps the name in double quotes and escapes embedded quotes.
    static func sanitizeIdentifier(_ name: String) -> String {
        let escaped = name.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    /// Sanitize a SQL string literal value to prevent SQL injection.
    /// Escapes single quotes by doubling them.
    static func sanitizeStringLiteral(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "'", with: "''")
        return "'\(escaped)'"
    }

    /// Map a GeoJson geometry type to a GeoPackage geometry type name.
    static func geometryTypeName(for type: GeoJsonType) -> String {
        switch type {
        case .point: return "POINT"
        case .multiPoint: return "MULTIPOINT"
        case .lineString: return "LINESTRING"
        case .multiLineString: return "MULTILINESTRING"
        case .polygon: return "POLYGON"
        case .multiPolygon: return "MULTIPOLYGON"
        case .geometryCollection: return "GEOMETRYCOLLECTION"
        default: return "GEOMETRY"
        }
    }

    /// Reads the `gpkg_contents` table and returns a list of available
    /// tables with their type and metadata.
    ///
    /// - Parameter db: An open SQLite database handle.
    /// - Returns: An array of ``GeoPackageTable`` entries.
    static func readContents(from db: SQLiteDB) throws -> [GeoPackageTable] {
        try db.query(
            "SELECT table_name, data_type, identifier, description,"
            + " min_x, min_y, max_x, max_y, srs_id"
            + " FROM gpkg_contents ORDER BY table_name;"
        ).compactMap { row in
            guard let tableName = row["table_name"] as? String,
                  let dataType = row["data_type"] as? String
            else { return nil }

            let identifier = row["identifier"] as? String
            let description = row["description"] as? String
            let srsId = row["srs_id"] as? Int
            let bounds: BoundingBox?
            if let minX = row["min_x"] as? Double,
               let minY = row["min_y"] as? Double,
               let maxX = row["max_x"] as? Double,
               let maxY = row["max_y"] as? Double
            {
                bounds = BoundingBox(
                    southWest: Coordinate3D(latitude: minY, longitude: minX),
                    northEast: Coordinate3D(latitude: maxY, longitude: maxX))
            }
            else {
                bounds = nil
            }

            return GeoPackageTable(
                tableName: tableName,
                dataType: dataType,
                identifier: identifier,
                description: description,
                srsId: srsId,
                bounds: bounds)
        }
    }

    /// Opens a GeoPackage file and reads the `gpkg_contents` table.
    ///
    /// - Parameter url: The file URL of a GeoPackage database.
    /// - Returns: An array of ``GeoPackageTable`` entries.
    static func readContents(from url: URL) throws -> [GeoPackageTable] {
        let db = try SQLiteDB(path: url.path)
        defer { db.close() }
        return try GeoPackage.readContents(from: db)
    }

    // MARK: - Spatial index helpers

    /// Returns the SQL identifier of the rtree virtual table for a given
    /// feature table and geometry column.
    static func rTreeTableName(for table: String, column: String) -> String {
        GeoPackage.sanitizeIdentifier("rtree_\(table)_\(column)")
    }

    /// Checks whether a spatial (rtree) index exists for the given feature
    /// table and geometry column.
    ///
    /// Returns `true` if either `gpkg_extensions` registers a
    /// `gpkg_rtree_index` extension for the table/column pair, or the
    /// rtree virtual table exists in `sqlite_master`.
    static func hasRTreeIndex(
        for table: String,
        column: String,
        in db: SQLiteDB
    ) throws -> Bool {
        // Check gpkg_extensions
        let escapedTable = GeoPackage.sanitizeStringLiteral(table)
        let escapedCol = GeoPackage.sanitizeStringLiteral(column)
        let extRows = try db.query("""
            SELECT 1 FROM gpkg_extensions
            WHERE table_name = \(escapedTable)
              AND column_name = \(escapedCol)
              AND extension_name = 'gpkg_rtree_index'
            LIMIT 1;
            """)
        if !extRows.isEmpty {
            return true
        }

        // Fallback: check if the rtree virtual table exists
        let rtreeName = GeoPackage.sanitizeStringLiteral("rtree_\(table)_\(column)")
        let tableRows = try db.query("""
            SELECT 1 FROM sqlite_master
            WHERE type = 'table'
              AND name = \(rtreeName)
            LIMIT 1;
            """)
        return tableRows.isEmpty == false
    }

}
