import Foundation
import CSQLite

/// A thread-safe SQLite wrapper for GeoPackage operations.
///
/// All SQLite C API calls are serialised through an internal queue so
/// the handle can be used from any task without synchronisation issues.
final class SQLiteDB: @unchecked Sendable {

    private var db: OpaquePointer?
    private let path: String
    private let queue = DispatchQueue(
        label: "com.gistools.geopackage.sqlite",
        qos: .userInitiated)

    init(path: String) throws {
        self.path = path
        var handle: OpaquePointer?
        let rc = sqlite3_open(path, &handle)
        guard rc == SQLITE_OK, let handle else {
            let msg = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            throw GeoPackageError.couldNotOpenDatabase(path: path, detail: msg)
        }
        db = handle
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    /// Close the database connection.
    func close() {
        queue.sync {
            guard let handle = db else { return }
            sqlite3_close(handle)
            db = nil
        }
    }

    // MARK: - Execute (no results)

    func execute(_ sql: String) throws {
        try queue.sync {
            var errMsg: UnsafeMutablePointer<CChar>?
            let rc = sqlite3_exec(db, sql, nil, nil, &errMsg)
            if rc != SQLITE_OK {
                let msg = errMsg.map { String(cString: $0) } ?? "Unknown error"
                sqlite3_free(errMsg)
                throw GeoPackageError.sqliteError(detail: msg)
            }
        }
    }

    // MARK: - Prepare statement

    /// Prepare an SQL statement, returning the handle.
    /// The caller must finalise the returned handle.
    func prepare(_ sql: String) throws -> OpaquePointer {
        try queue.sync {
            var stmt: OpaquePointer?
            let rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
            guard rc == 0, let stmt else {
                throw GeoPackageError.sqliteError(detail: lastError())
            }
            return stmt
        }
    }

    // MARK: - Query (returns rows)

    func query(_ sql: String) throws -> [[String: Sendable]] {
        try queue.sync { try _query(sql) }
    }

    // MARK: - Query raw blob

    func queryRawBlob(_ sql: String) throws -> [Data?] {
        try queue.sync { try _queryRawBlob(sql) }
    }

    // MARK: - Write with bindings (single statement)

    /// Prepares, binds, steps and finalises an INSERT/UPDATE/DELETE.
    func write(sql: String, values: [Any]) throws {
        try queue.sync {
            let stmt = try _prepare(sql)
            defer { sqlite3_finalize(stmt) }

            for (i, value) in values.enumerated() {
                try SQLiteDB.bind(stmt, index: Int32(i + 1), value: value)
            }

            let rc = sqlite3_step(stmt)
            guard rc == SQLITE_DONE else {
                throw GeoPackageError.sqliteError(detail: "Write failed, rc=\(rc)")
            }
        }
    }

    // MARK: - Error info

    func lastErrorMessage() -> String {
        queue.sync { lastError() }
    }

    // MARK: - Last insert row ID

    func lastInsertRowId() -> Int64 {
        queue.sync { sqlite3_last_insert_rowid(db) }
    }

    // MARK: - Private helpers (called on queue)

    private func lastError() -> String {
        guard let db else { return "Database is closed" }
        return String(cString: sqlite3_errmsg(db))
    }

    private func _prepare(_ sql: String) throws -> OpaquePointer {
        var stmt: OpaquePointer?
        let rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        guard rc == 0, let stmt else {
            throw GeoPackageError.sqliteError(detail: lastError())
        }
        return stmt
    }

    private func _query(_ sql: String) throws -> [[String: Sendable]] {
        let stmt = try _prepare(sql)
        defer { sqlite3_finalize(stmt) }

        var results: [[String: Sendable]] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let colCount = sqlite3_column_count(stmt)
            var row: [String: Sendable] = [:]
            for i in 0 ..< colCount {
                let name = String(cString: sqlite3_column_name(stmt, i))
                let declType = columnDeclaredType(stmt, i)
                row[name] = columnValue(stmt, i, declaredType: declType)
            }
            results.append(row)
        }
        return results
    }

    private func _queryRawBlob(_ sql: String) throws -> [Data?] {
        let stmt = try _prepare(sql)
        defer { sqlite3_finalize(stmt) }

        var results: [Data?] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if sqlite3_column_type(stmt, 0) == SQLITE_BLOB {
                guard let bytes = sqlite3_column_blob(stmt, 0) else {
                    results.append(nil)
                    continue
                }
                let length = Int(sqlite3_column_bytes(stmt, 0))
                results.append(Data(bytes: bytes, count: length))
            }
            else {
                results.append(nil)
            }
        }
        return results
    }

    private func columnDeclaredType(_ stmt: OpaquePointer, _ i: Int32) -> String {
        guard let ptr = sqlite3_column_decltype(stmt, i) else { return "" }
        return String(cString: ptr).lowercased()
    }

    private func columnValue(
        _ stmt: OpaquePointer,
        _ i: Int32,
        declaredType: String
    ) -> (any Sendable)? {
        let type = sqlite3_column_type(stmt, i)

        switch type {
        case SQLITE_NULL:
            return nil

        case SQLITE_INTEGER:
            let raw = sqlite3_column_int64(stmt, i)
            if declaredType == "boolean" || declaredType == "bool" {
                return raw != 0
            }
            if raw >= Int64(Int.min) && raw <= Int64(Int.max) {
                return Int(raw)
            }
            return raw

        case SQLITE_FLOAT:
            return sqlite3_column_double(stmt, i)

        case SQLITE_TEXT:
            guard let text = sqlite3_column_text(stmt, i) else { return nil }
            return String(cString: text)

        case SQLITE_BLOB:
            guard let bytes = sqlite3_column_blob(stmt, i) else { return nil }
            let length = Int(sqlite3_column_bytes(stmt, i))
            return Data(bytes: bytes, count: length)

        default:
            return nil
        }
    }

    // MARK: - Bind helpers (static, can be called from anywhere)

    /// Bind a value to a prepared statement at the given 1-based index.
    static func bind(
        _ stmt: OpaquePointer,
        index: Int32,
        value: Any?
    ) throws {
        guard let value else {
            sqlite3_bind_null(stmt, index)
            return
        }

        switch value {
        case let v as Bool:
            sqlite3_bind_int64(stmt, index, v ? 1 : 0)
        case let v as Int:
            sqlite3_bind_int64(stmt, index, Int64(v))
        case let v as Int64:
            sqlite3_bind_int64(stmt, index, v)
        case let v as Double:
            sqlite3_bind_double(stmt, index, v)
        case let v as String:
            if isBase64(v) {
                guard let data = Data(base64Encoded: v) else {
                    bindText(stmt, index: index, string: v)
                    return
                }
                bindBlob(stmt, index: index, data: data)
            }
            else {
                bindText(stmt, index: index, string: v)
            }
        case let v as Data:
            bindBlob(stmt, index: index, data: v)
        default:
            bindText(stmt, index: index, string: "\(value)")
        }
    }

    private static func bindText(
        _ stmt: OpaquePointer,
        index: Int32,
        string: String
    ) {
        let utf8 = Array(string.utf8)
        let buf = sqlite3_malloc(Int32(utf8.count + 1))
        guard let buf else { return }

        buf.assumingMemoryBound(to: UInt8.self).initialize(from: utf8, count: utf8.count)
        buf.assumingMemoryBound(to: UInt8.self).advanced(by: utf8.count).pointee = 0
        sqlite3_bind_text(stmt, index, buf.assumingMemoryBound(to: CChar.self), -1, sqlite3_free)
    }

    private static func bindBlob(
        _ stmt: OpaquePointer,
        index: Int32,
        data: Data
    ) {
        let count = data.count
        let buf = sqlite3_malloc(Int32(count))
        guard let buf else { return }

        data.copyBytes(to: buf.assumingMemoryBound(to: UInt8.self), count: count)
        _ = sqlite3_bind_blob(stmt, index, buf, Int32(count), sqlite3_free)
    }

    private static func isBase64(_ s: String) -> Bool {
        guard s.count >= 4 else { return false }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "+/="))
        guard s.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        guard Data(base64Encoded: s) != nil else { return false }

        return true
    }

}
