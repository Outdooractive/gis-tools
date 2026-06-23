import Foundation
import GISTools

/// Relationship types defined by the GeoPackage Related Tables Extension.
public enum RelationshipType: String, Sendable {
    case media = "media"
    case simpleMedia = "simple_media"
    case attributes = "attributes"
    case features = "features"
}

/// A single row from the `gpkgext_relations` metadata table.
public struct RelationRow: Sendable {

    /// A unique identifier for this relationship.
    public let id: String

    /// The base table name.
    public let tableName: String

    /// The base table column (typically `"geom"` for features).
    public let columnName: String

    /// The related (target) table name.
    public let relatedTableName: String

    /// The related table column (typically `"id"`).
    public let relatedColumnName: String

    /// The relationship type name.
    public let relationName: RelationshipType

    /// An optional mapping table name (for many-to-many relationships).
    public let mappingTableName: String?

    /// Creates a relation row.
    public init(
        id: String = UUID().uuidString,
        tableName: String,
        columnName: String = "geom",
        relatedTableName: String,
        relatedColumnName: String = "id",
        relationName: RelationshipType,
        mappingTableName: String? = nil
    ) {
        self.id = id
        self.tableName = tableName
        self.columnName = columnName
        self.relatedTableName = relatedTableName
        self.relatedColumnName = relatedColumnName
        self.relationName = relationName
        self.mappingTableName = mappingTableName
    }

}

// MARK: - GeoPackage helpers

extension GeoPackage {

    /// Returns all relationship rows from `gpkgext_relations`.
    static func readRelations(in db: SQLiteDB) throws -> [RelationRow] {
        let rows = try db.query(
            "SELECT id, table_name, column_name, related_table_name,"
            + " related_column_name, relation_name, mapping_table_name"
            + " FROM gpkgext_relations;")

        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let tableName = row["table_name"] as? String,
                  let columnName = row["column_name"] as? String,
                  let relatedTable = row["related_table_name"] as? String,
                  let relatedCol = row["related_column_name"] as? String,
                  let relationRaw = row["relation_name"] as? String,
                  let relationName = RelationshipType(rawValue: relationRaw)
            else { return nil }

            return RelationRow(
                id: id,
                tableName: tableName,
                columnName: columnName,
                relatedTableName: relatedTable,
                relatedColumnName: relatedCol,
                relationName: relationName,
                mappingTableName: row["mapping_table_name"] as? String)
        }
    }

    /// Inserts a relation row into `gpkgext_relations`.
    static func writeRelation(
        _ relation: RelationRow,
        in db: SQLiteDB
    ) throws {
        let escapedId = GeoPackage.sanitizeStringLiteral(relation.id)
        let escapedTable = GeoPackage.sanitizeStringLiteral(relation.tableName)
        let escapedCol = GeoPackage.sanitizeStringLiteral(relation.columnName)
        let escapedRelated = GeoPackage.sanitizeStringLiteral(relation.relatedTableName)
        let escapedRelCol = GeoPackage.sanitizeStringLiteral(relation.relatedColumnName)
        let escapedRelName = GeoPackage.sanitizeStringLiteral(relation.relationName.rawValue)
        let mapping = relation.mappingTableName.map {
            GeoPackage.sanitizeStringLiteral($0)
        } ?? "NULL"

        try db.execute("""
            INSERT INTO gpkgext_relations
            (id, table_name, column_name, related_table_name,
             related_column_name, relation_name, mapping_table_name)
            VALUES (\(escapedId), \(escapedTable), \(escapedCol),
            \(escapedRelated), \(escapedRelCol), \(escapedRelName), \(mapping));
            """)
    }

    /// Registers the Related Tables Extension in `gpkg_extensions`.
    static func registerRelatedTablesExtension(in db: SQLiteDB) throws {
        try db.execute("""
            INSERT OR IGNORE INTO gpkg_extensions
            (table_name, column_name, extension_name, definition, scope)
            VALUES (NULL, NULL,
            'gpkgext_relations',
            'http://www.geopackage.org/spec/related_tables',
            'read-write');
            """)
    }

}

// MARK: - Feature convenience

extension Feature {

    /// Reads the related attribute rows for this feature from a GeoPackage.
    ///
    /// Uses the feature's ``id`` (set by the GeoPackage reader) to match
    /// against the related table's primary key.
    ///
    /// - Parameters:
    ///   - geopackage: The file URL of a GeoPackage database.
    ///   - relation: The relationship descriptor (from `gpkgext_relations`).
    /// - Returns: Filtered rows matching this feature's ID, or empty.
    public func relatedAttributes(
        from geopackage: URL,
        using relation: RelationRow
    ) throws -> [[String: Sendable]] {
        guard case .int(let rowId) = id else { return [] }

        let table = try GeoPackage.readAttributeTable(
            from: geopackage,
            table: relation.relatedTableName,
            rowId: rowId)
        return table.rows
    }

    /// Reads the related media rows for this feature from a GeoPackage.
    public func relatedMedia(
        from geopackage: URL,
        using relation: RelationRow
    ) throws -> [MediaTable] {
        guard case .int(let rowId) = id else { return [] }

        let table = try GeoPackage.readMediaTable(
            from: geopackage,
            table: relation.relatedTableName)

        // For media tables, we return entries matching the feature ID
        let matching = table.rowIds
            .enumerated()
            .filter { $1 == Int64(rowId) }
            .map { $0.offset }
        guard !matching.isEmpty else { return [] }
        return [table]  // Return full table; user can index via rowIds
    }

}

// MARK: - FeatureCollection convenience

extension FeatureCollection {

    /// Reads all relationship entries from a GeoPackage that reference
    /// the given table name.
    public static func relationships(
        for tableName: String,
        in geopackage: URL
    ) throws -> [RelationRow] {
        let db = try SQLiteDB(path: geopackage.path)
        defer { db.close() }

        return try GeoPackage.readRelations(in: db)
            .filter {
                $0.tableName == tableName || $0.relatedTableName == tableName
            }
    }

    /// Loads an attribute table related to this feature collection
    /// from a GeoPackage file.
    ///
    /// Uses the first ``RelationRow`` in `gpkgext_relations` where
    /// `table_name` matches the given table name and
    /// `relation_name` is `"attributes"`.
    public static func loadRelatedAttributes(
        for tableName: String,
        from geopackage: URL
    ) throws -> AttributeTable? {
        let db = try SQLiteDB(path: geopackage.path)
        defer { db.close() }

        let rels = try GeoPackage.readRelations(in: db)
        guard let rel = rels.first(where: {
            $0.tableName == tableName && $0.relationName == .attributes
        }) else { return nil }

        return try GeoPackage.readAttributeTable(from: geopackage, table: rel.relatedTableName)
    }

    /// Loads a media table related to this feature collection
    /// from a GeoPackage file.
    public static func loadRelatedMedia(
        for tableName: String,
        from geopackage: URL
    ) throws -> MediaTable? {
        let rels = try Self.relationships(for: tableName, in: geopackage)
        guard let rel = rels.first(where: {
            $0.tableName == tableName && $0.relationName == .media
        }) else { return nil }

        return try GeoPackage.readMediaTable(from: geopackage, table: rel.relatedTableName)
    }

}
