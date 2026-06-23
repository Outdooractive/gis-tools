import Foundation
import CSQLite
import GISTools

// MARK: - FeatureCollection convenience

extension FeatureCollection {

    /// Creates a FeatureCollection from a GeoPackage (.gpkg) file.
    ///
    /// - Parameters:
    ///   - geopackage: The file URL of a GeoPackage database.
    ///   - table: The name of the feature table to read (default `"features"`).
    ///   - boundingBox: An optional bounding box to filter features. When
    ///     set and the GeoPackage has a spatial (rtree) index, only
    ///     features within or intersecting the bounding box are returned.
    /// - Throws: A ``GeoPackageError`` if the file cannot be read or is invalid.
    public init(
        geopackage url: URL,
        table: String = "features",
        boundingBox: BoundingBox? = nil
    ) async throws {
        let conn = try GeoPackageConnection(url: url, skipValidation: true)
        try await conn.validate()
        let features = try await conn.readFeatures(table: table, boundingBox: boundingBox)
        self.init(features)
    }

}

// MARK: - Async FeatureStream

/// An `AsyncSequence` that yields features from a GeoPackage feature
/// table one at a time without loading the entire result set into memory.
public struct FeatureStream: AsyncSequence {

    public typealias Element = Feature
    private let db: SQLiteDB
    private let table: String
    private let boundingBox: BoundingBox?

    init(db: SQLiteDB,
         table: String,
         boundingBox: BoundingBox? = nil
    ) {
        self.db = db
        self.table = table
        self.boundingBox = boundingBox
    }

    /// Creates the async iterator for the feature stream.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(db: db, table: table, boundingBox: boundingBox)
    }

    /// An async iterator that yields features one at a time.
    /// Created by ``FeatureStream.makeAsyncIterator()``.
    public struct AsyncIterator: AsyncIteratorProtocol {

        private let db: SQLiteDB
        private let table: String
        private let boundingBox: BoundingBox?
        private var stmt: OpaquePointer?
        private var geomColumnName: String = "geom"
        private var srsId: Int = 4326
        private var columnNames: [String] = []
        private var started = false
        private var finished = false

        init(db: SQLiteDB,
             table: String,
             boundingBox: BoundingBox?
        ) {
            self.db = db
            self.table = table
            self.boundingBox = boundingBox
        }

        public mutating func next() async throws -> Feature? {
            if finished { return nil }
            if !started {
                try start()
                started = true
            }
            return fetchNext()
        }

        private mutating func start() throws {
            let escapedTable = GeoPackage.sanitizeStringLiteral(table)
            let quotedTable = GeoPackage.sanitizeIdentifier(table)

            let geomCols = try db.query(
                "SELECT column_name, geometry_type_name, srs_id, z, m FROM gpkg_geometry_columns WHERE table_name = \(escapedTable);")

            guard let geomMeta = geomCols.first else {
                throw GeoPackageError.invalidGeoPackage(detail: "Table '\(table)' not found in gpkg_geometry_columns")
            }
            guard geomCols.count == 1 else {
                throw GeoPackageError.mixedGeometryTypes(detail: "Table '\(table)' has multiple geometry columns")
            }

            geomColumnName = geomMeta["column_name"] as? String ?? "geom"
            srsId = geomMeta["srs_id"] as? Int ?? 4326

            let tableInfo = try db.query("PRAGMA table_info(\(quotedTable));")
            columnNames = tableInfo.compactMap { $0["name"] as? String }
            guard !columnNames.isEmpty else {
                throw GeoPackageError.invalidGeoPackage(detail: "Table '\(table)' has no columns")
            }

            let rtreeAvailable = try GeoPackage.hasRTreeIndex(for: table, column: geomColumnName, in: db)

            let selectSQL = "SELECT rowid, *"
            let rtreeJoinSQL: String
            if let bbox = boundingBox, rtreeAvailable {
                let rtreeName = GeoPackage.rTreeTableName(for: table, column: geomColumnName)
                let minX = bbox.southWest.longitude
                let minY = bbox.southWest.latitude
                let maxX = bbox.northEast.longitude
                let maxY = bbox.northEast.latitude
                rtreeJoinSQL = " INNER JOIN \(rtreeName) ON rowid = \(rtreeName).id WHERE \(rtreeName).minx <= \(maxX) AND \(rtreeName).maxx >= \(minX) AND \(rtreeName).miny <= \(maxY) AND \(rtreeName).maxy >= \(minY)"
            }
            else {
                rtreeJoinSQL = ""
            }

            let sql = "\(selectSQL) FROM \(quotedTable)\(rtreeJoinSQL);"
            stmt = try db.prepare(sql)
        }

        private mutating func fetchNext() -> Feature? {
            guard let stmt else { return nil }

            while true {
                let rc = sqlite3_step(stmt)
                guard rc == SQLITE_ROW else {
                    sqlite3_finalize(stmt)
                    self.stmt = nil
                    finished = true
                    return nil
                }

                let colCount = sqlite3_column_count(stmt)
                var row: [String: Sendable] = [:]
                for i in 0 ..< colCount {
                    guard let name = sqlite3_column_name(stmt, i).map({ String(cString: $0) }) else { continue }
                    switch sqlite3_column_type(stmt, i) {
                    case SQLITE_INTEGER:
                        row[name] = Int(sqlite3_column_int64(stmt, i))
                    case SQLITE_FLOAT:
                        row[name] = sqlite3_column_double(stmt, i)
                    case SQLITE_TEXT:
                        if let text = sqlite3_column_text(stmt, i) {
                            row[name] = String(cString: text)
                        }
                    case SQLITE_BLOB:
                        if let bytes = sqlite3_column_blob(stmt, i) {
                            let length = Int(sqlite3_column_bytes(stmt, i))
                            row[name] = Data(bytes: bytes, count: length)
                        }
                    default:
                        break
                    }
                }

                guard let wkbData = row[geomColumnName] as? Data,
                      let header = try? WKBHeader.parse(wkbData),
                      let geoJson = try? WKBCoder.decode(wkb: header.wkbData, sourceSrid: header.srid)
                else { continue }

                let projection = GeoPackage.projection(for: srsId)
                let projectedGeoJson = geoJson.projected(to: projection)

                let gpkgRowId = row["rowid"] as? Int

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

                var feature = Feature(projectedGeoJson, properties: properties)
                if let rowId = gpkgRowId {
                    feature.id = .int(rowId)
                }
                feature.gpkgTableName = table

                // In-memory bbox filter fallback for when rtree is unavailable
                if let bbox = boundingBox, !feature.intersects(bbox) {
                    continue
                }

                return feature
            }
        }
    }

}

// MARK: - Reader

enum GeoPackageReader {

    static func readFeatures(
        from db: SQLiteDB,
        table: String,
        boundingBox: BoundingBox? = nil,
        limit: Int? = nil,
        offset: Int = 0
    ) throws -> [Feature] {
        // Get geometry column metadata
        let escapedTable = GeoPackage.sanitizeStringLiteral(table)
        let quotedTable = GeoPackage.sanitizeIdentifier(table)
        let geomCols = try db.query(
            "SELECT column_name, geometry_type_name, srs_id, z, m FROM gpkg_geometry_columns WHERE table_name = \(escapedTable);")

        guard let geomMeta = geomCols.first else {
            throw GeoPackageError.invalidGeoPackage(detail: "Table '\(table)' not found in gpkg_geometry_columns")
        }

        guard geomCols.count == 1 else {
            throw GeoPackageError.mixedGeometryTypes(detail: "Table '\(table)' has multiple geometry columns")
        }

        let geomColumnName = geomMeta["column_name"] as? String ?? "geom"
        let srsId = geomMeta["srs_id"] as? Int ?? 4326

        // Get all column info from the feature table
        let tableInfo = try db.query("PRAGMA table_info(\(quotedTable));")
        let columnNames: [String] = tableInfo.compactMap { $0["name"] as? String }

        guard !columnNames.isEmpty else {
            throw GeoPackageError.invalidGeoPackage(detail: "Table '\(table)' has no columns")
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

        // Build the SQL query (include rowid for foreign key references)
        let selectSQL = "SELECT rowid, *"
        let limitSQL: String
        if let limit {
            limitSQL = " LIMIT \(limit) OFFSET \(offset)"
        }
        else {
            limitSQL = ""
        }

        let rows: [[String: Sendable]]
        if let rowIds,
           !rowIds.isEmpty,
           boundingBox != nil
        {
            let idList = rowIds.map(String.init).joined(separator: ", ")
            rows = try db.query("\(selectSQL) FROM \(quotedTable) WHERE rowid IN (\(idList))\(limitSQL);")
        }
        else {
            rows = try db.query("\(selectSQL) FROM \(quotedTable)\(limitSQL);")
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

            // Extract row ID for feature
            let gpkgRowId = row["rowid"] as? Int ?? row["id"] as? Int

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

            var feature = Feature(geometry, properties: properties)
            if let rowId = gpkgRowId {
                feature.id = .int(rowId)
            }
            feature.gpkgTableName = table
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
