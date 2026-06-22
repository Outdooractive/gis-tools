import Foundation
import GISTools

// MARK: - Validation result

/// The result of validating a GeoPackage file against the OGC GeoPackage 1.2 specification.
public struct GeoPackageValidation: Sendable {

    /// Whether the file passed all validation checks.
    public let isValid: Bool

    /// Fatal issues that violate the spec.
    public let errors: [GeoPackageValidationIssue]

    /// Non-fatal issues that may indicate problems.
    public let warnings: [GeoPackageValidationIssue]

    /// Creates a validation result.
    public init(
        errors: [GeoPackageValidationIssue] = [],
        warnings: [GeoPackageValidationIssue] = []
    ) {
        self.errors = errors
        self.warnings = warnings
        self.isValid = errors.isEmpty
    }

}

/// A GeoPackage spec violation.  Each case carries the relevant context
/// and can produce a human-readable ``message``.
public enum GeoPackageValidationIssue: Sendable {

    case invalidApplicationId
    case invalidUserVersion
    case missingMandatoryTable(_ table: String)
    case missingRecommendedTable(_ table: String)
    case missingRequiredColumn(_ table: String, _ column: String)
    case emptySrsTable
    case unknownDataType(_ table: String, _ type: String)
    case missingReferencedTable(_ table: String)
    case invalidSrsReference(_ context: String, _ srsId: Int)
    case invalidGeometryType(_ table: String, _ type: String)
    case invalidZValue(_ table: String, _ value: Int)
    case invalidMValue(_ table: String, _ value: Int)
    case invalidStructure(_ detail: String)
    case missingTileMatrixSet
    case missingTileMatrix
    case missingTileMatrixEntry(_ table: String)
    case invalidExtensionScope(_ name: String, _ scope: String)
    case missingGeometryColumnsForFeatures

    /// A human-readable message describing the issue.
    public var message: String {
        switch self {
        case .invalidApplicationId:
            return "Invalid application_id — expected GP10 or GPKG"
        case .invalidUserVersion:
            return "Invalid or missing user_version — expected >= 10200 (1.2.0)"
        case .missingMandatoryTable(let name):
            return "Missing mandatory table: \(name)"
        case .missingRecommendedTable(let name):
            return "Missing recommended table: \(name)"
        case .missingRequiredColumn(let table, let column):
            return "\(table) missing required column: \(column)"
        case .emptySrsTable:
            return "gpkg_spatial_ref_sys is empty — no SRS entries"
        case .unknownDataType(let table, let type):
            return "gpkg_contents: '\(table)' has unknown data_type '\(type)'"
        case .missingReferencedTable(let table):
            return "gpkg_contents: table '\(table)' does not exist"
        case .invalidSrsReference(let context, let id):
            return "'\(context)' references non-existent srs_id \(id)"
        case .invalidGeometryType(let table, let type):
            return "gpkg_geometry_columns: '\(table)' has invalid geometry_type '\(type)'"
        case .invalidZValue(let table, let value):
            return "gpkg_geometry_columns: '\(table)' has invalid z value \(value)"
        case .invalidMValue(let table, let value):
            return "gpkg_geometry_columns: '\(table)' has invalid m value \(value)"
        case .invalidStructure(let detail):
            return "Invalid table structure: \(detail)"
        case .missingTileMatrixSet:
            return "Missing gpkg_tile_matrix_set — required when tile tables exist"
        case .missingTileMatrix:
            return "Missing gpkg_tile_matrix — required when tile tables exist"
        case .missingTileMatrixEntry(let table):
            return "gpkg_tile_matrix_set: missing entry for tile table '\(table)'"
        case .invalidExtensionScope(let name, let scope):
            return "gpkg_extensions: '\(name)' has invalid scope '\(scope)'"
        case .missingGeometryColumnsForFeatures:
            return "gpkg_contents has feature tables but gpkg_geometry_columns is empty"
        }
    }

}

// MARK: - Validation

extension GeoPackage {

    /// Validates a `.gpkg` file against the OGC GeoPackage 1.2 specification.
    ///
    /// - Parameter url: The file URL of a GeoPackage database.
    /// - Returns: A ``GeoPackageValidation`` result listing errors and warnings.
    public static func validate(url: URL) throws -> GeoPackageValidation {
        let db = try SQLiteDB(path: url.path)
        defer { db.close() }

        var errors: [GeoPackageValidationIssue] = []
        var warnings: [GeoPackageValidationIssue] = []

        try validateApplicationId(db, errors: &errors)
        try validateUserVersion(db, errors: &errors)

        let allTables = try collectTableNames(db)
        validateCoreTables(allTables, errors: &errors, warnings: &warnings)
        try validateSrsTable(db, allTables: allTables, errors: &errors, warnings: &warnings)

        let contentsRows = try readContentsRows(db, allTables: allTables)
        try validateContentsTable(db, contentsRows: contentsRows, allTables: allTables, errors: &errors, warnings: &warnings)

        if allTables.contains("gpkg_geometry_columns") {
            try validateGeometryColumns(db, contentsRows: contentsRows, errors: &errors, warnings: &warnings)
        }

        let tileTables = contentsRows.filter { $0.dataType == "tiles" }
        if !tileTables.isEmpty {
            try validateTileMetadata(db, tileTables: tileTables, allTables: allTables, errors: &errors, warnings: &warnings)
        }

        if allTables.contains("gpkg_extensions") {
            try validateExtensions(db, errors: &errors, warnings: &warnings)
        }

        return GeoPackageValidation(errors: errors, warnings: warnings)
    }

    // MARK: - Private helpers

    private static func collectTableNames(_ db: SQLiteDB) throws -> Set<String> {
        let rows = try db.query(
            "SELECT name FROM sqlite_master WHERE type='table';")
        return Set(rows.compactMap { $0["name"] as? String })
    }

    private static func readContentsRows(_ db: SQLiteDB, allTables: Set<String>) throws -> [ContentsRow] {
        guard allTables.contains("gpkg_contents") else { return [] }
        let rows = try db.query(
            "SELECT table_name, data_type, identifier, srs_id FROM gpkg_contents;")
        return rows.compactMap { row in
            guard let name = row["table_name"] as? String,
                  let type = row["data_type"] as? String else { return nil }
            return ContentsRow(
                tableName: name,
                dataType: type,
                identifier: row["identifier"] as? String,
                srsId: row["srs_id"] as? Int)
        }
    }

    private struct ContentsRow: Sendable {
        let tableName: String
        let dataType: String
        let identifier: String?
        let srsId: Int?
    }

    // MARK: - Checks

    private static func validateApplicationId(_ db: SQLiteDB, errors: inout [GeoPackageValidationIssue]) throws {
        let appId = try db.query("PRAGMA application_id;")
        guard let first = appId.first,
              let raw = first["application_id"] as? Int,
              raw == Int(GeoPackage.applicationIdGP10)
                || raw == Int(GeoPackage.applicationIdGPKG)
        else {
            errors.append(.invalidApplicationId)
            return
        }
    }

    private static func validateUserVersion(_ db: SQLiteDB, errors: inout [GeoPackageValidationIssue]) throws {
        let uv = try db.query("PRAGMA user_version;")
        guard let first = uv.first,
              let raw = first["user_version"] as? Int,
              raw >= GeoPackage.userVersion
        else {
            errors.append(.invalidUserVersion)
            return
        }
    }

    private static func validateCoreTables(
        _ allTables: Set<String>,
        errors: inout [GeoPackageValidationIssue],
        warnings: inout [GeoPackageValidationIssue]
    ) {
        for name in ["gpkg_spatial_ref_sys", "gpkg_contents"] {
            if !allTables.contains(name) {
                errors.append(.missingMandatoryTable(name))
            }
        }

        if !allTables.contains("gpkg_extensions") {
            warnings.append(.missingRecommendedTable("gpkg_extensions"))
        }
    }

    private static func validateSrsTable(
        _ db: SQLiteDB,
        allTables: Set<String>,
        errors: inout [GeoPackageValidationIssue],
        warnings: inout [GeoPackageValidationIssue]
    ) throws {
        guard allTables.contains("gpkg_spatial_ref_sys") else { return }

        let requiredCols = ["srs_id", "srs_name", "organization",
                            "organization_coordsys_id", "definition"]
        let colInfo = try db.query("PRAGMA table_info(gpkg_spatial_ref_sys);")
        let existingCols = Set(colInfo.compactMap { $0["name"] as? String })
        for col in requiredCols where !existingCols.contains(col) {
            errors.append(.missingRequiredColumn("gpkg_spatial_ref_sys", col))
        }

        let count = try db.query("SELECT count(*) as cnt FROM gpkg_spatial_ref_sys;")
        if let first = count.first, (first["cnt"] as? Int ?? 0) == 0 {
            warnings.append(.emptySrsTable)
        }
    }

    private static func validateContentsTable(
        _ db: SQLiteDB,
        contentsRows: [ContentsRow],
        allTables: Set<String>,
        errors: inout [GeoPackageValidationIssue],
        warnings: inout [GeoPackageValidationIssue]
    ) throws {
        guard allTables.contains("gpkg_contents") else { return }

        if contentsRows.isEmpty {
            warnings.append(.emptySrsTable)
            return
        }

        let validDataTypes: Set<String> = [
            "features", "tiles", "2d-gridded-coverage", "attributes",
        ]

        for row in contentsRows {
            if !validDataTypes.contains(row.dataType) {
                warnings.append(.unknownDataType(row.tableName, row.dataType))
            }
            if !allTables.contains(row.tableName) {
                errors.append(.missingReferencedTable(row.tableName))
            }
            if let srsId = row.srsId {
                let srsCheck = try db.query(
                    "SELECT 1 FROM gpkg_spatial_ref_sys WHERE srs_id = \(srsId) LIMIT 1;")
                if srsCheck.isEmpty {
                    warnings.append(.invalidSrsReference(row.tableName, srsId))
                }
            }
        }
    }

    private static func validateGeometryColumns(
        _ db: SQLiteDB,
        contentsRows: [ContentsRow],
        errors: inout [GeoPackageValidationIssue],
        warnings: inout [GeoPackageValidationIssue]
    ) throws {
        let geomCols = try db.query("SELECT * FROM gpkg_geometry_columns;")

        let validGeoTypes: Set<String> = [
            "GEOMETRY", "POINT", "LINESTRING", "POLYGON",
            "MULTIPOINT", "MULTILINESTRING", "MULTIPOLYGON",
            "GEOMETRYCOLLECTION",
        ]

        for col in geomCols {
            guard let table = col["table_name"] as? String,
                  let geoType = col["geometry_type_name"] as? String,
                  let srsId = col["srs_id"] as? Int,
                  let z = col["z"] as? Int,
                  let m = col["m"] as? Int
            else {
                errors.append(.invalidStructure("gpkg_geometry_columns"))
                continue
            }

            if !validGeoTypes.contains(geoType) {
                warnings.append(.invalidGeometryType(table, geoType))
            }
            if ![0, 1, 2].contains(z) {
                warnings.append(.invalidZValue(table, z))
            }
            if ![0, 1, 2].contains(m) {
                warnings.append(.invalidMValue(table, m))
            }

            let srsCheck = try db.query(
                "SELECT 1 FROM gpkg_spatial_ref_sys WHERE srs_id = \(srsId) LIMIT 1;")
            if srsCheck.isEmpty {
                errors.append(.invalidSrsReference("gpkg_geometry_columns/\(table)", srsId))
            }

            if !contentsRows.contains(where: { $0.tableName == table }) {
                warnings.append(.invalidStructure("gpkg_geometry_columns/\(table) not in gpkg_contents"))
            }
        }

        let featureTables = contentsRows.filter { $0.dataType == "features" }
        if !featureTables.isEmpty, geomCols.isEmpty {
            warnings.append(.missingGeometryColumnsForFeatures)
        }
    }

    private static func validateTileMetadata(
        _ db: SQLiteDB,
        tileTables: [ContentsRow],
        allTables: Set<String>,
        errors: inout [GeoPackageValidationIssue],
        warnings: inout [GeoPackageValidationIssue]
    ) throws {
        if !allTables.contains("gpkg_tile_matrix_set") {
            errors.append(.missingTileMatrixSet)
        }
        if !allTables.contains("gpkg_tile_matrix") {
            errors.append(.missingTileMatrix)
        }
        guard allTables.contains("gpkg_tile_matrix_set") else { return }

        let tmsRows = try db.query("SELECT table_name, srs_id FROM gpkg_tile_matrix_set;")
        let tmsTables = Set(tmsRows.compactMap { $0["table_name"] as? String })

        for tileTable in tileTables {
            if !tmsTables.contains(tileTable.tableName) {
                errors.append(.missingTileMatrixEntry(tileTable.tableName))
            }
            if let srsId = tileTable.srsId {
                let srsCheck = try db.query(
                    "SELECT 1 FROM gpkg_spatial_ref_sys WHERE srs_id = \(srsId) LIMIT 1;")
                if srsCheck.isEmpty {
                    warnings.append(.invalidSrsReference("tile/\(tileTable.tableName)", srsId))
                }
            }
        }
    }

    private static func validateExtensions(
        _ db: SQLiteDB,
        errors: inout [GeoPackageValidationIssue],
        warnings: inout [GeoPackageValidationIssue]
    ) throws {
        let validScopes: Set<String> = ["read-write", "write-only"]
        let rows = try db.query("SELECT extension_name, scope FROM gpkg_extensions;")

        for row in rows {
            guard let name = row["extension_name"] as? String,
                  let scope = row["scope"] as? String
            else {
                warnings.append(.invalidStructure("gpkg_extensions row"))
                continue
            }
            if !validScopes.contains(scope) {
                warnings.append(.invalidExtensionScope(name, scope))
            }
        }
    }

}
