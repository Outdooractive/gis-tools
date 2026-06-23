import Foundation
import GISTools

/// A persistent connection to a GeoPackage file.
///
/// All read and write operations are available as instance methods on
/// this actor, so you can batch multiple operations without repeatedly
/// opening and closing the file.
///
/// ```swift
/// let gpkg = try await GeoPackageConnection(url: url)
/// defer { await gpkg.close() }
///
/// let all = try await gpkg.readFeatures(table: "countries")
/// let page = try await gpkg.readFeatures(table: "countries", limit: 50, offset: 0)
/// let attrs = try await gpkg.readAttributeTable(table: "info", rowId: 42)
/// ```
///
/// The existing convenience APIs (`FeatureCollection(geopackage:)`,
/// `GeoPackage.readAttributeTable(from:)`, etc.) are implemented on
/// top of this actor and remain fully backward compatible.
public actor GeoPackageConnection {

    private let db: SQLiteDB

    /// Opens a connection to a GeoPackage file.
    /// - Parameter url: The file URL of a `.gpkg` database.
    public init(url: URL) throws {
        db = try SQLiteDB(path: url.path)
    }

    /// Opens a connection to a GeoPackage file.
    /// - Parameter path: The file system path of a `.gpkg` database.
    public init(path: String) throws {
        db = try SQLiteDB(path: path)
    }

    /// Closes the connection.  The instance should not be used after
    /// calling this method.
    public func close() {
        db.close()
    }

    /// The underlying SQLite database handle, exposed for `FeatureStream`.
    /// Use only from a single task at a time.
    nonisolated var _db: SQLiteDB { db }

}

// MARK: - Metadata

extension GeoPackageConnection {

    /// Creates the mandatory GeoPackage metadata tables in the database.
    /// Idempotent — safe to call on an existing GeoPackage.
    public func createMetadata() throws {
        try GeoPackage.createMetadata(in: db)
    }

    /// Validates the GeoPackage metadata tables against the OGC
    /// GeoPackage 1.2 specification.
    /// - Returns: A ``GeoPackageValidation`` result.
    @discardableResult
    public func validate() throws -> GeoPackageValidation {
        try GeoPackage.validate(in: db)
    }

    /// Reads the `gpkg_contents` table and returns all registered tables.
    public func readContents() throws -> [GeoPackageTable] {
        try GeoPackage.readContents(from: db)
    }

    /// Checks whether a spatial (rtree) index exists for the given
    /// feature table and geometry column.
    /// - Parameters:
    ///   - table: The feature table name.
    ///   - column: The geometry column name.
    public func hasRTreeIndex(for table: String, column: String) throws -> Bool {
        try GeoPackage.hasRTreeIndex(for: table, column: column, in: db)
    }

}

// MARK: - Features

extension GeoPackageConnection {

    /// Reads all features from a feature table.
    public func readFeatures(
        table: String,
        boundingBox: BoundingBox? = nil
    ) throws -> [Feature] {
        try GeoPackageReader.readFeatures(from: db, table: table, boundingBox: boundingBox)
    }

    /// Reads a page of features from a feature table.
    public func readFeatures(
        table: String,
        limit: Int,
        offset: Int,
        boundingBox: BoundingBox? = nil
    ) throws -> [Feature] {
        try GeoPackageReader.readFeatures(from: db, table: table, boundingBox: boundingBox, limit: limit, offset: offset)
    }

    /// Returns an async sequence of features from a feature table.
    public func features(
        table: String,
        boundingBox: BoundingBox? = nil
    ) -> FeatureStream {
        FeatureStream(db: db, table: table, boundingBox: boundingBox)
    }

    /// Writes features to a feature table.
    public func write(
        features fc: FeatureCollection,
        to table: String,
        createSpatialIndex: Bool = false
    ) throws {
        try GeoPackageWriter.writeFeatures(
            fc, to: db, table: table,
            createSpatialIndex: createSpatialIndex)
    }

}

// MARK: - Attribute tables

extension GeoPackageConnection {

    /// Reads a non-spatial attribute table.
    /// - Parameters:
    ///   - table: The attribute table name.
    ///   - rowId: Optional row ID to filter by (SQL-level `WHERE id = ?`).
    public func readAttributeTable(table: String, rowId: Int? = nil) throws -> AttributeTable {
        try GeoPackage.readAttributeTable(from: db, table: table, rowId: rowId)
    }

    /// Writes an attribute table and optionally creates a relationship.
    /// - Parameters:
    ///   - table: The attribute table to write.
    ///   - relationship: Optional relationship to link to a feature table.
    public func write(attributeTable table: AttributeTable, relationship: RelationRow? = nil) throws {
        try GeoPackage.writeAttributeTable(table, in: db)
        if let rel = relationship {
            try registerRelatedTablesExtension()
            try write(relation: rel)
        }
    }

}

// MARK: - Media tables

extension GeoPackageConnection {

    /// Reads a media table.
    /// - Parameter table: The media table name.
    public func readMediaTable(table: String) throws -> MediaTable {
        try GeoPackage.readMediaTable(from: db, table: table)
    }

    /// Reads media rows filtered by a specific row ID.
    /// - Parameters:
    ///   - table: The media table name.
    ///   - rowId: The primary key value to filter by.
    public func readMediaRows(table: String, rowId: Int) throws -> [MediaRow] {
        try GeoPackage.readMediaRows(from: db, table: table, rowId: rowId)
    }

    /// Writes a media table and optionally creates a relationship.
    /// - Parameters:
    ///   - table: The media table to write.
    ///   - relationship: Optional relationship to link to a feature table.
    public func write(mediaTable table: MediaTable, relationship: RelationRow? = nil) throws {
        try GeoPackage.writeMediaTable(table, in: db)
        if let rel = relationship {
            try registerRelatedTablesExtension()
            try write(relation: rel)
        }
    }

}

// MARK: - Tiles

extension GeoPackageConnection {

    /// Reads a single tile blob from a tile table.
    /// - Parameters:
    ///   - key: The tile identifier (zoom, column, row).
    ///   - table: The tile table name.
    /// - Returns: The tile data, or `nil` if not found.
    public func readTile(for key: TileKey, from table: String) throws -> Data? {
        try TileReader.readTile(for: key, from: table, in: db)
    }

    /// Reads all tiles from a tile table.
    /// - Parameter table: The tile table name.
    public func readAllTiles(from table: String) throws -> [TileKey: Data] {
        try TileReader.readAllTiles(from: table, in: db)
    }

    /// Reads the tile matrix set metadata for a tile table.
    /// - Parameter table: The tile table name.
    public func readTileMatrixSet(for table: String) throws -> TileMatrixSet? {
        try TileReader.readTileMatrixSet(for: table, in: db)
    }

    /// Reads the tile matrix metadata for all zoom levels.
    /// - Parameter table: The tile table name.
    public func readTileMatrices(for table: String) throws -> [TileMatrix] {
        try TileReader.readTileMatrices(for: table, in: db)
    }

    /// Reads a complete tile table including metadata and tile data.
    /// - Parameter table: The tile table name.
    public func readTileTable(_ table: String) throws -> TileTable? {
        try TileReader.readTileTable(table, in: db)
    }

    /// Creates a tile table with the standard GeoPackage schema.
    /// - Parameter name: The tile table name.
    public func createTileTable(_ name: String) throws {
        try TileWriter.createTileTable(name, in: db)
    }

    /// Writes a single tile blob to a tile table.
    /// - Parameters:
    ///   - tileData: The raw tile image data.
    ///   - key: The tile identifier (zoom, column, row).
    ///   - table: The tile table name.
    public func write(tileData: Data, for key: TileKey, to table: String) throws {
        try TileWriter.write(tileData: tileData, for: key, to: table, in: db)
    }

    /// Writes a complete tile pyramid including metadata tables.
    public func writeTilePyramid(
        tiles: [TileKey: Data],
        to tableName: String,
        srsId: Int = 3857,
        matrixSetBounds: BoundingBox,
        matrices: [TileMatrix],
        identifier: String? = nil,
        description: String? = nil
    ) throws {
        try TileWriter.writeTilePyramid(
            tiles: tiles, to: tableName,
            srsId: srsId, matrixSetBounds: matrixSetBounds,
            matrices: matrices,
            identifier: identifier, description: description,
            in: db)
    }

}

// MARK: - Relationships

extension GeoPackageConnection {

    /// Reads all relationship rows from `gpkgext_relations`.
    public func readRelations() throws -> [RelationRow] {
        try GeoPackage.readRelations(in: db)
    }

    /// Inserts a relationship row into `gpkgext_relations`.
    /// - Parameter relation: The relationship descriptor.
    public func write(relation: RelationRow) throws {
        try GeoPackage.writeRelation(relation, in: db)
    }

    /// Registers the Related Tables Extension in `gpkg_extensions`.
    public func registerRelatedTablesExtension() throws {
        try GeoPackage.registerRelatedTablesExtension(in: db)
    }

}
