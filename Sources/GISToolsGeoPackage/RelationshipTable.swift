import Foundation
import GISTools

/// Relationship types defined by the GeoPackage Related Tables Extension.
public enum RelationshipType: String, Sendable {

    /// Media relationship: binary blob content linked to a feature.
    case media = "media"

    /// Simple media relationship: media content without metadata.
    case simpleMedia = "simple_media"

    /// Attribute relationship: non-spatial attribute data.
    case attributes = "attributes"

    /// Features relationship: relationship between feature tables.
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
    /// - Parameters:
    ///   - id: A unique identifier (auto-generated if omitted).
    ///   - tableName: The base feature table name.
    ///   - columnName: The base table geometry column (default `"geom"`).
    ///   - relatedTableName: The target related table name.
    ///   - relatedColumnName: The target table primary key column (default `"id"`).
    ///   - relationName: The relationship type.
    ///   - mappingTableName: Optional mapping table name for many-to-many.
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

// MARK: - Feature convenience (table name)

extension Feature {

    /// Key used inside ``foreignMembers`` to store the GeoPackage table name.
    private static let gpkgTableKey = "_gpkg_table"

    /// The GeoPackage table name this feature belongs to, if known.
    /// Set automatically by the GeoPackage reader.
    public var gpkgTableName: String? {
        get { foreignMembers[Self.gpkgTableKey] as? String }
        set { foreignMembers[Self.gpkgTableKey] = newValue }
    }

}

// MARK: - MediaRow

/// A single row from a GeoPackage media (Related Tables Extension) table.
public struct MediaRow: Sendable, Identifiable {

    /// The primary key value.
    public let id: Int

    /// The raw media blob (PNG / JPEG / WebP).
    public let data: Data

    /// The MIME content type (e.g. `"image/png"`).
    public let contentType: String

    /// Optional user-defined column values.
    public let properties: [String: Sendable]

}

// MARK: - Feature convenience (connection-based)

extension Feature {

    /// Reads related attribute rows for this feature from a GeoPackage
    /// connection.
    ///
    /// Uses ``id`` and ``gpkgTableName`` (both set by the reader) to
    /// auto-resolve the relationship via `gpkgext_relations` and fetch
    /// only the matching rows.
    ///
    /// - Parameter gpkg: An open GeoPackage connection.
    /// - Returns: Attribute rows matching this feature's ID.
    public func relatedAttributes(
        in gpkg: GeoPackageConnection
    ) async throws -> [[String: Sendable]] {
        guard case .int(let rowId) = id,
              let tableName = gpkgTableName
        else { return [] }

        let rels = try await gpkg.readRelations()
        guard let rel = rels.first(where: {
            $0.tableName == tableName && $0.relationName == .attributes
        }) else { return [] }

        let table = try await gpkg.readAttributeTable(
            table: rel.relatedTableName,
            rowId: rowId)
        return table.rows
    }

    /// Reads related media rows for this feature from a GeoPackage
    /// connection.
    ///
    /// Uses ``id`` and ``gpkgTableName`` (both set by the reader) to
    /// auto-resolve the relationship via `gpkgext_relations` and fetch
    /// only the matching rows.
    ///
    /// - Parameter gpkg: An open GeoPackage connection.
    /// - Returns: Media rows matching this feature's ID.
    public func relatedMedia(
        in gpkg: GeoPackageConnection
    ) async throws -> [MediaRow] {
        guard case .int(let rowId) = id,
              let tableName = gpkgTableName
        else { return [] }

        let rels = try await gpkg.readRelations()
        guard let rel = rels.first(where: {
            $0.tableName == tableName && $0.relationName == .media
        }) else { return [] }

        return try await gpkg.readMediaRows(table: rel.relatedTableName, rowId: rowId)
    }

}
