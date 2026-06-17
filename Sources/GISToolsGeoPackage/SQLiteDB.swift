import Foundation
import CSQLite

/// A minimal SQLite wrapper for GeoPackage operations.
/// Not Sendable — always use within a single synchronous context.
final class SQLiteDB {

    private var db: OpaquePointer?

    private let path: String

    init(path: String) throws {
        self.path = path
        try open()
    }

    deinit {
        close()
    }

    // MARK: - Open / Close

    private func open() throws {
        let rc = sqlite3_open(path, &db)
        guard rc == 0 else {  // SQLITE_OK
            throw GeoPackageError.couldNotOpenDatabase(path, lastError())
        }
    }

    func close() {
        guard db != nil else { return }
        sqlite3_close(db)
        db = nil
    }

    // MARK: - Execute (no results)

    func execute(_ sql: String) throws {
        var errMsg: UnsafeMutablePointer<CChar>?
        let rc = sqlite3_exec(db, sql, nil, nil, &errMsg)
        if rc != SQLITE_OK {
            let msg = errMsg.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errMsg)
            throw GeoPackageError.sqliteError(msg)
        }
    }

    // MARK: - Prepare statement

    /// Prepare an SQL statement, returning the handle.
    /// The caller must finalize the returned handle.
    func prepare(_ sql: String) throws -> OpaquePointer {
        var stmt: OpaquePointer?
        let rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        guard rc == 0, let stmt else {
            throw GeoPackageError.sqliteError(lastError())
        }
        return stmt
    }

    // MARK: - Query (returns rows)

    func query(_ sql: String) throws -> [[String: Sendable]] {
        var stmt: OpaquePointer?
        let rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        guard rc == 0, let stmt else {  // SQLITE_OK
            throw GeoPackageError.sqliteError(lastError())
        }
        defer { sqlite3_finalize(stmt) }

        var results: [[String: Sendable]] = []
        while sqlite3_step(stmt) == 100 {  // SQLITE_ROW
            let colCount = sqlite3_column_count(stmt)
            var row: [String: Sendable] = [:]
            for i in 0..<colCount {
                let name = String(cString: sqlite3_column_name(stmt, i))
                let declType = columnDeclaredType(stmt, i)
                row[name] = columnValue(stmt, i, declaredType: declType)
            }
            results.append(row)
        }
        return results
    }

    // MARK: - Query raw blob

    /// Execute a query and return raw blob data for the first column.
    func queryRawBlob(_ sql: String) throws -> [Data?] {
        var stmt: OpaquePointer?
        let rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        guard rc == 0, let stmt else {
            throw GeoPackageError.sqliteError(lastError())
        }
        defer { sqlite3_finalize(stmt) }

        var results: [Data?] = []
        while sqlite3_step(stmt) == 100 {  // SQLITE_ROW
            if sqlite3_column_type(stmt, 0) == 4 {  // SQLITE_BLOB
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

    // MARK: - Error info

    /// The error message from the last failed SQLite operation.
    func lastErrorMessage() -> String {
        lastError()
    }

    // MARK: - Last insert row ID

    func lastInsertRowId() -> Int64 {
        sqlite3_last_insert_rowid(db)
    }

    // MARK: - Private helpers

    private func lastError() -> String {
        guard let db else { return "Database is closed" }
        return String(cString: sqlite3_errmsg(db))
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
        case 5:  // SQLITE_NULL
            return nil

        case 1:  // SQLITE_INTEGER
            let raw = sqlite3_column_int64(stmt, i)
            if declaredType == "boolean" || declaredType == "bool" {
                return raw != 0
            }
            if raw >= Int64(Int.min) && raw <= Int64(Int.max) {
                return Int(raw)
            }
            return raw

        case 2:  // SQLITE_FLOAT
            return sqlite3_column_double(stmt, i)

        case 3:  // SQLITE_TEXT
            let text = String(cString: sqlite3_column_text(stmt, i))
            if declaredType == "date" || declaredType == "datetime" || declaredType == "timestamp" {
                return text
            }
            return text

        case 4:  // SQLITE_BLOB
            guard let bytes = sqlite3_column_blob(stmt, i) else { return nil }
            let length = Int(sqlite3_column_bytes(stmt, i))
            return Data(bytes: bytes, count: length)

        default:
            return nil
        }
    }

    // MARK: - Bind helpers for writes

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
            } else {
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
        // Allocate memory via sqlite3_malloc and let SQLite free it via the destructor.
        // This avoids unsafeBitCast of -1 to a function pointer (SQLITE_TRANSIENT).
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
