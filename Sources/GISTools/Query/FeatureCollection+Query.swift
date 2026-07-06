import Foundation

extension Array where Element == Feature {

    /// Evaluate a query DSL string against all features in this array
    /// and return only the matching features.
    ///
    /// The query syntax supports property comparisons, full-text search,
    /// boolean logic, set membership, and spatial predicates.
    /// See the `QueryParser` documentation for the full grammar.
    ///
    /// - Parameter term: A query string in the query DSL format.
    /// - Returns: An array of matching features, or `nil` if the query
    ///   string is invalid.
    public func query(term: String) -> [Feature]? {
        guard let parser = QueryParser(string: term) else { return nil }
        return filter { parser.evaluate(on: $0) }
    }

}

extension FeatureCollection {

    /// Evaluate a query DSL string against all features in this collection
    /// and return a new collection containing only the matching features.
    ///
    /// The query syntax supports property comparisons, full-text search,
    /// boolean logic, set membership, and spatial predicates.
    /// See the `QueryParser` documentation for the full grammar.
    ///
    /// - Parameter term: A query string in the query DSL format.
    /// - Returns: A filtered FeatureCollection, or `nil` if the query
    ///   string is invalid.
    public func query(term: String) -> FeatureCollection? {
        guard let parser = QueryParser(string: term) else { return nil }
        let matches = features.filter { parser.evaluate(on: $0) }
        return FeatureCollection(matches)
    }

}
