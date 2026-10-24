import Foundation

/// Helpers shared by the generic GeoJSON dispatch implementations.
enum GeometryDispatch {

    /// Performs a checked downcast for a generic geometry dispatch path.
    ///
    /// These casts follow a geometry `switch` and are structurally safe, but
    /// an unexpected change in the dispatch invariants should fail with a
    /// useful diagnostic instead of an opaque `as!` trap.
    ///
    /// - Parameters:
    ///    - value: The value to cast.
    ///    - type: The expected concrete type.
    ///    - file: The caller file, captured automatically.
    ///    - line: The caller line, captured automatically.
    /// - Returns: The value cast to `type`.
    @inline(__always)
    static func checkedCast<T>(
        _ value: Any,
        to type: T.Type,
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> T {
        guard let result = value as? T else {
            preconditionFailure(
                "Expected \(T.self) in generic geometry dispatch, got \(Swift.type(of: value))",
                file: file,
                line: line)
        }

        return result
    }

}
