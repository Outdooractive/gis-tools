import Foundation
import GISTools

// MARK: - Errors

public enum GeoPackageError: LocalizedError {
    case couldNotOpenDatabase(String, String)
    case sqliteError(String)
    case invalidGeoPackage(String)
    case mixedGeometryTypes(String)
    case invalidWKB(String)
    case unsupportedGeometryType(String)

    public var errorDescription: String? {
        switch self {
        case .couldNotOpenDatabase(let path, let detail):
            return "Could not open GeoPackage database at \(path): \(detail)"
        case .sqliteError(let detail):
            return "SQLite error: \(detail)"
        case .invalidGeoPackage(let detail):
            return "Invalid GeoPackage: \(detail)"
        case .mixedGeometryTypes(let detail):
            return "Mixed geometry types: \(detail)"
        case .invalidWKB(let detail):
            return "Invalid WKB geometry: \(detail)"
        case .unsupportedGeometryType(let detail):
            return "Unsupported geometry type: \(detail)"
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
        """

    /// SQL to drop metadata tables (for cleanup).
    static let dropMetadataSQL = """
        DROP TABLE IF EXISTS gpkg_spatial_ref_sys;
        DROP TABLE IF EXISTS gpkg_contents;
        DROP TABLE IF EXISTS gpkg_geometry_columns;
        DROP TABLE IF EXISTS gpkg_extensions;
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
            throw GeoPackageError.invalidGeoPackage("Not a GeoPackage file (invalid application_id)")
        }

        // Verify mandatory tables exist
        let tables = try db.query(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN"
            + " ('gpkg_spatial_ref_sys','gpkg_contents','gpkg_geometry_columns');")
        let tableNames = tables.compactMap { $0["name"] as? String }
        for required in ["gpkg_spatial_ref_sys", "gpkg_contents", "gpkg_geometry_columns"] {
            guard tableNames.contains(required) else {
                throw GeoPackageError.invalidGeoPackage("Missing mandatory table: \(required)")
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

}
