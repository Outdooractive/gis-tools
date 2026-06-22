import Foundation
import GISTools

/// Reads tile (raster) data from a GeoPackage database.
enum TileReader {

    /// Reads a single tile blob from a tile table.
    ///
    /// - Parameters:
    ///   - key: The tile key (zoom, column, row in TMS convention).
    ///   - tableName: The tile table to query.
    ///   - db: An open SQLite database handle.
    /// - Returns: The tile blob data, or `nil` if not found.
    static func readTile(
        for key: TileKey,
        from tableName: String,
        in db: SQLiteDB
    ) throws -> Data? {
        let sanitized = GeoPackage.sanitizeIdentifier(tableName)
        let blobs = try db.queryRawBlob("""
            SELECT tile_data FROM \(sanitized)
            WHERE zoom_level = \(key.zoom)
              AND tile_column = \(key.column)
              AND tile_row = \(key.row)
            LIMIT 1;
            """)
        return blobs.first ?? nil
    }

    /// Reads a single tile blob using a MapTile (XYZ convention).
    ///
    /// - Parameters:
    ///   - mapTile: The map tile in XYZ convention.
    ///   - matrixHeight: The total number of tile rows at the tile's
    ///     zoom level.
    ///   - tableName: The tile table to query.
    ///   - db: An open SQLite database handle.
    /// - Returns: The tile blob data, or `nil` if not found.
    static func readTile(
        for mapTile: MapTile,
        matrixHeight: Int,
        from tableName: String,
        in db: SQLiteDB
    ) throws -> Data? {
        let key = TileKey(from: mapTile, matrixHeight: matrixHeight)
        return try readTile(for: key, from: tableName, in: db)
    }

    /// Reads all tiles from a tile table.
    ///
    /// - Parameters:
    ///   - tableName: The tile table to query.
    ///   - db: An open SQLite database handle.
    /// - Returns: Tile blobs keyed by (zoom, column, row).
    static func readAllTiles(
        from tableName: String,
        in db: SQLiteDB
    ) throws -> [TileKey: Data] {
        let sanitized = GeoPackage.sanitizeIdentifier(tableName)
        let rows: [[String: Sendable]] = try db.query("""
            SELECT zoom_level, tile_column, tile_row, tile_data
            FROM \(sanitized);
            """)

        var result: [TileKey: Data] = [:]
        for row in rows {
            guard let zoom = row["zoom_level"] as? Int,
                  let column = row["tile_column"] as? Int,
                  let rowIndex = row["tile_row"] as? Int,
                  let data = row["tile_data"] as? Data
            else { continue }

            let key = TileKey(
                zoom: zoom,
                column: column,
                row: rowIndex)
            result[key] = data
        }
        return result
    }

    /// Reads tile matrix set metadata for a tile table.
    ///
    /// - Parameters:
    ///   - tableName: The tile table name.
    ///   - db: An open SQLite database handle.
    /// - Returns: The tile matrix set metadata, or `nil` if not found.
    static func readTileMatrixSet(
        for tableName: String,
        in db: SQLiteDB
    ) throws -> TileMatrixSet? {
        let escaped = GeoPackage.sanitizeStringLiteral(tableName)
        let rows: [[String: Sendable]] = try db.query("""
            SELECT table_name, srs_id, min_x, min_y, max_x, max_y
            FROM gpkg_tile_matrix_set
            WHERE table_name = \(escaped);
            """)

        guard let row = rows.first,
              let name = row["table_name"] as? String,
              let rawSrsId = row["srs_id"] as? Int,
              let minX = row["min_x"] as? Double,
              let minY = row["min_y"] as? Double,
              let maxX = row["max_x"] as? Double,
              let maxY = row["max_y"] as? Double
        else { return nil }

        return TileMatrixSet(
            tableName: name,
            srsId: rawSrsId,
            bounds: BoundingBox(
                southWest: Coordinate3D(
                    latitude: minY,
                    longitude: minX),
                northEast: Coordinate3D(
                    latitude: maxY,
                    longitude: maxX)))
    }

    /// Reads tile matrix metadata for all zoom levels of a tile table.
    ///
    /// - Parameters:
    ///   - tableName: The tile table name.
    ///   - db: An open SQLite database handle.
    /// - Returns: An array of tile matrix entries, one per zoom level.
    static func readTileMatrices(
        for tableName: String,
        in db: SQLiteDB
    ) throws -> [TileMatrix] {
        let escaped = GeoPackage.sanitizeStringLiteral(tableName)
        let rows: [[String: Sendable]] = try db.query("""
            SELECT table_name, zoom_level, matrix_width, matrix_height,
                   tile_width, tile_height, pixel_x_size, pixel_y_size
            FROM gpkg_tile_matrix
            WHERE table_name = \(escaped)
            ORDER BY zoom_level;
            """)

        return rows.compactMap { row in
            guard let name = row["table_name"] as? String,
                  let zoom = row["zoom_level"] as? Int,
                  let mw = row["matrix_width"] as? Int,
                  let mh = row["matrix_height"] as? Int,
                  let tw = row["tile_width"] as? Int,
                  let th = row["tile_height"] as? Int,
                  let px = row["pixel_x_size"] as? Double,
                  let py = row["pixel_y_size"] as? Double
            else { return nil }

            return TileMatrix(
                tableName: name,
                zoomLevel: zoom,
                matrixWidth: mw,
                matrixHeight: mh,
                tileWidth: tw,
                tileHeight: th,
                pixelXSize: px,
                pixelYSize: py)
        }
    }

    /// Reads a complete tile table including tiles and metadata.
    ///
    /// - Parameters:
    ///   - tableName: The tile table name.
    ///   - db: An open SQLite database handle.
    /// - Returns: A TileTable with matrix set, matrices, and tile data.
    static func readTileTable(
        _ tableName: String,
        in db: SQLiteDB
    ) throws -> TileTable? {
        guard let matrixSet = try readTileMatrixSet(
            for: tableName, in: db)
        else { return nil }

        let matrices = try readTileMatrices(
            for: tableName, in: db)
        let tiles = try readAllTiles(
            from: tableName, in: db)

        return TileTable(
            matrixSet: matrixSet,
            matrices: matrices,
            tiles: tiles)
    }

}
