import Foundation

/// A parser and evaluator for a Reverse Polish Notation (RPN) query DSL
/// used to filter vector tile features by their properties and location.
///
/// The query string syntax supports:
/// - Literal values (strings, numbers) for full-text search across all properties
/// - Property path access via ``.``-separated keys and ``[index]`` subscripts
/// - Comparisons: ``==``, ``!=``, ``>``, ``>=``, ``<``, ``<=``, ``=~`` (regex),
///   ``=*`` (contains), ``=^`` (starts with), ``=$`` (ends with)
/// - Set membership: ``.class in ["primary", "secondary"]``
/// - Boolean operators: ``and``, ``or``, ``not`` (+ ``exists`` for presence check)
/// - Spatial filters: ``near(lat,lon,tolerance)``, ``within(minLon,minLat,maxLon,maxLat)``,
///   ``intersects(minLon,minLat,maxLon,maxLat)``
/// - Grouping with parentheses: ``(A AND B) OR C``
///
/// Example queries:
/// ```
/// .highway == primary and .name =~ '^Main'
/// .class in ["primary", "secondary"] and .name =* "Main"
/// .population > 1000 and within(11.5,3.8,11.6,3.9)
/// .highway == primary and intersects(11.5,3.8,11.6,3.9)
/// (.name == "Berlin" OR .name == "Paris") AND .population > 100000
/// NOT (.name exists) OR .value >= 10
/// ```
public struct QueryParser {

    /// A token in the RPN expression pipeline, representing a comparison,
    /// condition, literal value, spatial predicate, full-text search, or
    /// a property/array-element value reference.
    public enum Expression: Equatable {

        /// A comparison operator between two values.
        public enum Comparison: Equatable {

            /// Equal to (``==``).
            case equals

            /// Not equal to (``!=``).
            case notEquals

            /// Greater than (``>``).
            case greaterThan

            /// Greater than or equal to (``>=``).
            case greaterThanOrEqual

            /// Less than (``<``).
            case lessThan

            /// Less than or equal to (``<=``).
            case lessThanOrEqual

            /// Regular expression match (``=~``).
            case regex

            /// String contains (``=*``).
            case contains

            /// String starts with (``=^``).
            case startsWith

            /// String ends with (``=$``).
            case endsWith

            /// Value in a set (``in``).
            case `in`
        }

        /// A boolean condition joining expressions.
        public enum Condition: Equatable {

            /// Logical AND.
            case and

            /// Logical OR.
            case or

            /// Logical NOT.
            case not

            /// Truthy-value check. Evaluates ``true`` if the preceding value
            /// is non-nil.
            case exists
        }

        /// A key path segment or array index used to reference property values.
        public enum KeyOrIndex: Equatable {

            /// A dictionary key.
            case key(String)

            /// An array index.
            case index(Int)
        }

        /// A comparison operator token.
        case comparison(Comparison)

        /// A boolean condition token.
        case condition(Condition)

        /// A literal value token.
        case literal(AnyHashable)

        /// A set of literal values, used with the ``.in`` comparison.
        case literalSet([AnyHashable])

        /// A spatial proximity predicate: ``near(latitude, longitude, tolerance)``.
        case near(Coordinate3D, Double)

        /// A full-text search token that matches any property value.
        case searchValues(String)

        /// A property value reference, composed of key path segments and/or
        /// array indices (e.g. ``.properties.name``, ``.tags[0]``).
        case value([KeyOrIndex])

        /// A spatial bounding-box predicate: ``within(minLon, minLat, maxLon, maxLat)``.
        /// Returns ``true`` if the feature's geometry is fully contained by the box.
        case within(BoundingBox)

        /// A spatial bounding-box intersection predicate: ``intersects(minLon, minLat, maxLon, maxLat)``.
        /// Returns ``true`` if the feature's geometry intersects the box.
        case intersects(BoundingBox)
    }

    private let reader: Reader?
    private(set) var pipeline: [Expression]?

    /// Creates a parser by tokenizing the given query string.
    ///
    /// - Parameter string: A query string in the RPN-based DSL.
    /// - Returns: A parser, or `nil` if the string cannot be parsed.
    public init?(string: String) {
        self.reader = Reader(characters: Array(string.utf8))

        guard var reader = self.reader,
              parseQuery(reader: &reader)
        else { return nil }
    }

    /// Creates a parser with a pre-built expression pipeline, skipping
    /// string parsing.
    ///
    /// - Parameter pipeline: An ordered array of ``Expression`` tokens in
    ///   Reverse Polish Notation.
    public init(pipeline: [Expression]) {
        self.reader = nil
        self.pipeline = pipeline
    }

    /// Evaluates the expression pipeline against the given feature.
    ///
    /// The pipeline is evaluated as a stack machine in Reverse Polish Notation.
    /// Returns `false` if the pipeline is empty or cannot be reduced.
    ///
    /// - Parameter feature: The feature whose properties and geometry are evaluated.
    /// - Returns: `true` if the pipeline evaluates to a truthy value,
    ///   `false` otherwise.
    public func evaluate(on feature: Feature) -> Bool {
        guard let pipeline else { return false }
        let properties = QueryParser.convertToAnyHashable(feature.properties)

        var stack: [AnyHashable?] = []

        for expression in pipeline {
            switch expression {
            case let .comparison(comparison):
                switch comparison {
                case .equals, .notEquals:
                    guard stack.count >= 2 else { return false }

                    let rawSecond = stack.removeFirst()
                    let rawFirst = stack.removeFirst()
                    let result: Bool
                    if let second = rawSecond,
                       let first = rawFirst
                    {
                        result = comparison == .equals ? (first == second) : (first != second)
                    }
                    else {
                        result = false
                    }
                    stack.insert(result, at: 0)

                case .greaterThan, .greaterThanOrEqual, .lessThan, .lessThanOrEqual:
                    guard stack.count >= 2 else { return false }

                    let rawSecond = stack.removeFirst()
                    let rawFirst = stack.removeFirst()
                    if let first = rawFirst, let second = rawSecond {
                        stack.insert(compare(first: first, second: second, condition: comparison), at: 0)
                    }
                    else {
                        stack.insert(false, at: 0)
                    }

                case .regex:
                    guard stack.count >= 2 else { return false }

                    let rawRegex = stack.removeFirst()
                    let rawValue = stack.removeFirst()
                    if let regex = rawRegex as? String,
                       let value = rawValue as? String
                    {
                        stack.insert(value.matches(regex), at: 0)
                    }
                    else {
                        stack.insert(false, at: 0)
                    }

                case .contains:
                    guard stack.count >= 2 else { return false }

                    let rawNeedle = stack.removeFirst()
                    let rawHaystack = stack.removeFirst()
                    if let needle = rawNeedle as? String,
                       let haystack = rawHaystack as? String
                    {
                        stack.insert(haystack.localizedCaseInsensitiveContains(needle), at: 0)
                    }
                    else {
                        stack.insert(false, at: 0)
                    }

                case .startsWith:
                    guard stack.count >= 2 else { return false }

                    let rawNeedle = stack.removeFirst()
                    let rawHaystack = stack.removeFirst()
                    if let needle = rawNeedle as? String,
                       let haystack = rawHaystack as? String
                    {
                        stack.insert(haystack.lowercased().hasPrefix(needle.lowercased()), at: 0)
                    }
                    else {
                        stack.insert(false, at: 0)
                    }

                case .endsWith:
                    guard stack.count >= 2 else { return false }

                    let rawNeedle = stack.removeFirst()
                    let rawHaystack = stack.removeFirst()
                    if let needle = rawNeedle as? String,
                       let haystack = rawHaystack as? String
                    {
                        stack.insert(haystack.lowercased().hasSuffix(needle.lowercased()), at: 0)
                    }
                    else {
                        stack.insert(false, at: 0)
                    }

                case .in:
                    guard stack.isNotEmpty else { return false }

                    let rawSetValues = stack.removeFirst()
                    guard stack.isNotEmpty else { return false }
                    let rawValue = stack.removeFirst()

                    if let setValues = rawSetValues as? [AnyHashable],
                       let value = rawValue
                    {
                        stack.insert(setValues.contains(value), at: 0)
                    }
                    else {
                        stack.insert(false, at: 0)
                    }
                }

            case let .condition(condition):
                switch condition {
                case .and, .or:
                    guard stack.count >= 2 else { return false }

                    let second = stack.removeFirst()
                    let first = stack.removeFirst()
                    let firstIsTrue = if let bool = first as? Bool { bool } else { first != nil }
                    let secondIsTrue = if let bool = second as? Bool { bool } else { second != nil }

                    if condition == .and {
                        stack.insert(firstIsTrue && secondIsTrue, at: 0)
                    }
                    else {
                        stack.insert(firstIsTrue || secondIsTrue, at: 0)
                    }

                case .not:
                    guard stack.isNotEmpty else { return false }

                    let value = stack.removeFirst()
                    let valueIsTrue = if let bool = value as? Bool { bool } else { value != nil }

                    stack.insert(!valueIsTrue, at: 0)

                case .exists:
                    guard stack.isNotEmpty else { return false }

                    let value = stack.removeFirst()
                    stack.insert(value != nil, at: 0)
                }

            case let .literal(value):
                stack.insert(value, at: 0)

            case let .literalSet(values):
                stack.insert(values as AnyHashable, at: 0)

            case let .near(coordinate, tolerance):
                var result = false
                if let centroid = feature.geometry.centroid {
                    result = coordinate.distance(from: centroid.coordinate) <= tolerance
                }
                stack.insert(result, at: 0)

            case let .within(boundingBox):
                let featureBox = feature.boundingBox ?? feature.calculateBoundingBox()
                stack.insert(featureBox.map { boundingBox.contains($0) } ?? false, at: 0)

            case let .intersects(boundingBox):
                stack.insert(feature.intersects(boundingBox), at: 0)

            case let .searchValues(searchString):
                var result = false
                for value in properties.values.compactMap({ $0 as? String }) {
                    if value.localizedCaseInsensitiveContains(searchString) {
                        result = true
                        break
                    }
                }
                stack.insert(result, at: 0)

            case let .value(keys):
                var current: AnyHashable? = properties

                for keyOrIndex in keys {
                    switch keyOrIndex {
                    case let .key(key):
                        if let object = current as? [String: AnyHashable] {
                            current = object[key]
                        }
                        else {
                            current = nil
                            break
                        }

                    case let .index(index):
                        if let array = current as? [AnyHashable] {
                            current = array.get(at: index)
                        }
                        else {
                            current = nil
                            break
                        }
                    }
                }

                stack.insert(current, at: 0)
            }
        }

        // The stack should contain the result now
        guard stack.count == 1,
              let result = stack.first
        else { return false }

        if let bool = result as? Bool {
            return bool
        }

        return result != nil
    }

    /// Recursively converts a ``[String: Sendable]`` dictionary to ``[String: AnyHashable]``,
    /// handling nested dictionaries and arrays.
    private static func convertToAnyHashable(_ dict: [String: Sendable]) -> [String: AnyHashable] {
        dict.mapValues { value in
            if let nested = value as? [String: Sendable] {
                return convertToAnyHashable(nested) as AnyHashable
            }
            else if let array = value as? [Sendable] {
                return array.compactMap { $0 as? AnyHashable } as AnyHashable
            }
            else if let hashable = value as? AnyHashable {
                return hashable
            }
            else if let int = value as? Int {
                return int
            }
            else if let double = value as? Double {
                return double
            }
            else if let string = value as? String {
                return string
            }
            else if let bool = value as? Bool {
                return bool
            }
            else {
                return String(describing: value)
            }
        }
    }

    /// Converts an ``AnyHashable`` numeric value to ``Double`` for cross-type ordered comparisons.
    /// Handles all standard Swift integer and floating-point types.
    private static func toDouble(_ value: AnyHashable) -> Double? {
        if let v = value as? Double { return v }
        if let v = value as? Int { return Double(v) }
        if let v = value as? Int8 { return Double(v) }
        if let v = value as? Int16 { return Double(v) }
        if let v = value as? Int32 { return Double(v) }
        if let v = value as? Int64 { return Double(v) }
        if let v = value as? UInt { return Double(v) }
        if let v = value as? UInt8 { return Double(v) }
        if let v = value as? UInt16 { return Double(v) }
        if let v = value as? UInt32 { return Double(v) }
        if let v = value as? UInt64 { return Double(v) }
        if let v = value as? Float { return Double(v) }
        return nil
    }

    private func compare(
        first: AnyHashable,
        second: AnyHashable,
        condition: QueryParser.Expression.Comparison
    ) -> Bool {
        // Equality: try direct AnyHashable comparison first (fast path for same-type),
        // then fall back to Double-based cross-type check (e.g. Int(1) == Double(1.0)).
        if condition == .equals || condition == .notEquals {
            if first == second { return condition == .equals }
            if let left = QueryParser.toDouble(first),
               let right = QueryParser.toDouble(second),
               left == right
            {
                return condition == .equals
            }
            return condition == .notEquals
        }

        // Ordered comparisons: promote both sides to Double.
        if let left = QueryParser.toDouble(first),
           let right = QueryParser.toDouble(second)
        {
            return compare(left: left, right: right, condition: condition)
        }

        // String comparison fallback.
        if let left = first as? String,
           let right = second as? String
        {
            return compare(left: left, right: right, condition: condition)
        }

        return false
    }

    private func compare<T: Comparable>(
        left: T,
        right: T,
        condition: QueryParser.Expression.Comparison
    ) -> Bool {
        switch condition {
        case .greaterThan: return left > right
        case .greaterThanOrEqual: return left >= right
        case .lessThan: return left < right
        case .lessThanOrEqual: return left <= right
        default: return false
        }
    }

    private mutating func parseQuery(
        reader: inout Reader,
        until terminator: UInt8? = nil
    ) -> Bool {
        pipeline = []
        reader.skipWhitespace()

        var terms: [Expression] = []
        var comparison: Expression?
        var condition: Expression?
        var isBeginningOfTerm = true

        outer: while let char = reader.peek() {
            // Check for terminator (e.g., ')') when in a sub-expression
            if let terminator, char == terminator {
                break
            }

            // Check for:
            // - and, or, not, exists
            // - ==, !=, >, >=, <, <=, =~, =*, =^, =$
            // - in
            if isBeginningOfTerm {
                let hasAnd = reader.peekWord("and")
                let hasOr = reader.peekWord("or")
                let hasNot = reader.peekWord("not")
                let hasExists = reader.peekWord("exists")
                let hasIn = reader.peekWord("in")
                let hasNear = reader.peekString("near(", caseInsensitive: true)
                let hasWithin = reader.peekString("within(", caseInsensitive: true)
                let hasIntersects = reader.peekString("intersects(", caseInsensitive: true)

                if hasAnd || hasOr || hasNot || hasExists {
                    pipeline?.append(contentsOf: terms)
                    if let comparison {
                        pipeline?.append(comparison)
                    }
                    if let condition {
                        pipeline?.append(condition)
                    }
                    terms = []
                    comparison = nil
                    condition = nil
                    isBeginningOfTerm = false

                    if hasAnd {
                        condition = .condition(.and)
                        reader.moveIndex(by: 3)
                    }
                    else if hasOr {
                        condition = .condition(.or)
                        reader.moveIndex(by: 2)
                    }
                    else if hasNot {
                        pipeline?.append(.condition(.not))
                        reader.moveIndex(by: 3)
                    }
                    else if hasExists {
                        pipeline?.append(.condition(.exists))
                        reader.moveIndex(by: 6)
                    }

                    continue
                }

                if hasIn {
                    pipeline?.append(contentsOf: terms)
                    if let comparison {
                        pipeline?.append(comparison)
                    }
                    if let condition {
                        pipeline?.append(condition)
                    }
                    terms = []
                    comparison = nil
                    condition = nil
                    isBeginningOfTerm = false

                    reader.moveIndex(by: 2)

                    reader.skipWhitespace()
                    guard reader.peek() == UInt8(ascii: "[") else { return false }
                    reader.moveIndex(by: 1)

                    guard let setValues = reader.readLiteralSet() else { return false }

                    terms.append(.literalSet(setValues))
                    comparison = .comparison(.in)
                    continue
                }

                if hasNear {
                    guard let term = reader.readNear() else { return false }

                    isBeginningOfTerm = false
                    terms.append(term)

                    continue
                }

                if hasWithin {
                    guard let term = reader.readWithin() else { return false }

                    isBeginningOfTerm = false
                    terms.append(term)

                    continue
                }

                if hasIntersects {
                    guard let term = reader.readIntersects() else { return false }

                    isBeginningOfTerm = false
                    terms.append(term)

                    continue
                }

                if terms.count == 1,
                   let term = reader.readComparisonExpression()
                {
                    isBeginningOfTerm = false
                    comparison = term
                    continue
                }
            }

            switch char {
            case UInt8(ascii: " "), UInt8(ascii: "\t"), UInt8(ascii: "\n"), UInt8(ascii: "\r"):
                reader.skipWhitespace()
                isBeginningOfTerm = true
                continue

            case UInt8(ascii: "("):
                pipeline?.append(contentsOf: terms)
                if let comparison { pipeline?.append(comparison) }
                if let condition { pipeline?.append(condition) }
                terms = []
                comparison = nil
                condition = nil
                isBeginningOfTerm = false

                reader.moveIndex(by: 1)

                guard parseQuery(reader: &reader, until: UInt8(ascii: ")")) else { return false }

                reader.skipWhitespace()
                guard reader.peek() == UInt8(ascii: ")") else { return false }
                reader.moveIndex(by: 1)

                isBeginningOfTerm = true

            case UInt8(ascii: "."):
                guard let term = reader.readValueExpression() else { return false }
                isBeginningOfTerm = false
                terms.append(term)

            default:
                guard let term = reader.readLiteralExpression() else { return false }
                isBeginningOfTerm = false
                terms.append(term)
            }
        }

        pipeline?.append(contentsOf: terms)
        if let comparison {
            pipeline?.append(comparison)
        }
        if let condition {
            pipeline?.append(condition)
        }

        // Only apply the global-search fallback at the top level (no terminator)
        guard terminator == nil else { return true }

        if pipeline?.allSatisfy({ if case .literal = $0 { true } else { false } }) ?? false,
           let searchString = pipeline?
            .compactMap({ expression in
                if case let .literal(value) = expression {
                    return value as? String
                }
                return nil
            })
            .joined(separator: " ")
        {
            pipeline = [.searchValues(searchString)]
        }

        return true
    }

    // MARK: - Reader

    struct Reader {

        let characters: [UInt8]

        private var index: Int = 0

        init(characters: [UInt8]) {
            self.characters = characters
        }

        mutating func readNextCharacter() -> UInt8? {
            guard index < characters.endIndex else {
                index = characters.endIndex
                return nil
            }

            defer { index += 1 }

            return characters[index]
        }

        mutating func moveIndex(by offset: Int) {
            index += offset
        }

        func peek(withOffset offset: Int = 0) -> UInt8? {
            guard index + offset < characters.endIndex else { return nil }

            return characters[index + offset]
        }

        func peekWord(_ string: String) -> Bool {
            peekString(string, caseInsensitive: true, checkWordBoundary: true)
        }

        func peekString(
            _ string: String,
            caseInsensitive: Bool = true,
            checkWordBoundary: Bool = false
        ) -> Bool {
            guard index + string.count <= characters.endIndex else { return false }

            let peekString = caseInsensitive ? string.lowercased() : string

            for (offset, char) in peekString.utf8.enumerated() {
                var c = characters[index + offset]
                // only ASCII A-Z
                if caseInsensitive, c >= 65, c <= 90 {
                    c += 32
                }

                if c != char { return false }
            }

            if checkWordBoundary {
                guard index + string.count == characters.endIndex
                        || characters[index + string.count] == UInt8(ascii: " ")
                else { return false }
            }

            return true
        }

        @discardableResult
        mutating func skipWhitespace() -> UInt8? {
            var offset = 0

            while let char = peek(withOffset: offset) {
                switch char {
                case UInt8(ascii: " "), UInt8(ascii: "\t"), UInt8(ascii: "\n"), UInt8(ascii: "\r"):
                    offset += 1
                    continue
                default:
                    moveIndex(by: offset)
                    return char
                }
            }

            // Advance past any trailing whitespace so callers don't loop.
            if offset > 0 {
                moveIndex(by: offset)
            }

            return nil
        }

        mutating func readLiteralSet() -> [AnyHashable]? {
            var values: [AnyHashable] = []

            while let char = peek() {
                switch char {
                case UInt8(ascii: "]"):
                    moveIndex(by: 1)
                    return values

                case UInt8(ascii: " "), UInt8(ascii: "\t"), UInt8(ascii: "\n"), UInt8(ascii: "\r"):
                    skipWhitespace()

                case UInt8(ascii: ","):
                    moveIndex(by: 1)
                    skipWhitespace()

                default:
                    guard let value = readSetValue() else { return nil }
                    values.append(value)
                }
            }

            return nil
        }

        /// Reads a single literal value inside a set (delimited by `,`, `]`, or ` `).
        /// Supports quoted strings (single and double) and unquoted tokens.
        private mutating func readSetValue() -> AnyHashable? {
            skipWhitespace()

            // Handle quoted strings.
            if peek() == UInt8(ascii: "\"") {
                guard let quoted = readQuotedString(UInt8(ascii: "\"")) else { return nil }
                return quoted
            }
            if peek() == UInt8(ascii: "'") {
                guard let quoted = readQuotedString(UInt8(ascii: "'")) else { return nil }
                return quoted
            }

            // Read an unquoted token delimited by `,`, `]`, or ` `.
            let startIndex = index
            var offset = 0
            while let char = peek(withOffset: offset) {
                if char == UInt8(ascii: ",") || char == UInt8(ascii: "]") || char == UInt8(ascii: " ") {
                    break
                }
                offset += 1
            }

            guard offset > 0 else { return nil }
            let value = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8) ?? ""
            moveIndex(by: offset)

            if let int = Int(value) { return int }
            if let double = Double(value) { return double }
            return value
        }

        mutating func readValueExpression() -> Expression? {
            guard readNextCharacter() == UInt8(ascii: ".") else { return nil }

            var startIndex = index
            var offset = 0
            var parts: [QueryParser.Expression.KeyOrIndex] = []

            outer: while let char = peek(withOffset: offset) {
                switch char {
                case UInt8(ascii: " "), UInt8(ascii: "\t"), UInt8(ascii: "\n"), UInt8(ascii: "\r"):
                    break outer

                case UInt8(ascii: "."):
                    if let current = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8),
                       current.isNotEmpty
                    {
                        if let index = Int(current) {
                            parts.append(.index(index))
                        }
                        else {
                            parts.append(.key(current))
                        }
                    }

                    moveIndex(by: offset + 1)

                    startIndex = index
                    offset = 0

                case UInt8(ascii: "\""):
                    guard let quotedString = readQuotedString(UInt8(ascii: "\"")) else { return nil }

                    parts.append(.key(quotedString))
                    startIndex = index
                    offset = 0

                case UInt8(ascii: "'"):
                    guard let quotedString = readQuotedString(UInt8(ascii: "'")) else { return nil }

                    parts.append(.key(quotedString))
                    startIndex = index
                    offset = 0

                case UInt8(ascii: "["):
                    guard let arrayIndex = readArrayIndex() else { return nil }

                    parts.append(.index(arrayIndex))
                    startIndex = index
                    offset = 0

                default:
                    offset += 1
                }
            }

            moveIndex(by: offset)

            if let current = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8),
               current.isNotEmpty
            {
                if let index = Int(current) {
                    parts.append(.index(index))
                }
                else {
                    parts.append(.key(current))
                }
            }

            return .value(parts)
        }

        mutating func readLiteralExpression() -> Expression? {
            var startIndex = index
            var offset = 0
            var result = ""

            outer: while let char = peek(withOffset: offset) {
                switch char {
                case UInt8(ascii: " "), UInt8(ascii: "\t"), UInt8(ascii: "\n"), UInt8(ascii: "\r"), UInt8(ascii: ","), UInt8(ascii: ")"):
                    break outer

                case UInt8(ascii: "\""):
                    guard let quotedString = readQuotedString(UInt8(ascii: "\"")) else { return nil }

                    result += quotedString
                    startIndex = index
                    offset = 0

                case UInt8(ascii: "'"):
                    guard let quotedString = readQuotedString(UInt8(ascii: "'")) else { return nil }

                    result += quotedString
                    startIndex = index
                    offset = 0

                default:
                    offset += 1
                }
            }

            moveIndex(by: offset)

            if let current = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8) {
                result += current
            }

            guard result.isNotEmpty else { return nil }

            if let int = Int(result) {
                return .literal(int)
            }
            else if let double = Double(result) {
                return .literal(double)
            }

            return .literal(result)
        }

        mutating func readComparisonExpression() -> Expression? {
            let firstChar = peek()

            guard firstChar == UInt8(ascii: "=")
                    || firstChar == UInt8(ascii: "!")
                    || firstChar == UInt8(ascii: ">")
                    || firstChar == UInt8(ascii: "<")
            else { return nil }

            if let secondChar = peek(withOffset: 1),
               secondChar != UInt8(ascii: " ")
            {
                if secondChar == UInt8(ascii: "=") {
                    if firstChar == UInt8(ascii: "=") {
                        moveIndex(by: 2)
                        return .comparison(.equals)
                    }
                    else if firstChar == UInt8(ascii: "!") {
                        moveIndex(by: 2)
                        return .comparison(.notEquals)
                    }
                    else if firstChar == UInt8(ascii: ">") {
                        moveIndex(by: 2)
                        return .comparison(.greaterThanOrEqual)
                    }
                    else if firstChar == UInt8(ascii: "<") {
                        moveIndex(by: 2)
                        return .comparison(.lessThanOrEqual)
                    }
                }
                else if secondChar == UInt8(ascii: "~") {
                    moveIndex(by: 2)
                    return .comparison(.regex)
                }
                else if secondChar == UInt8(ascii: "*") {
                    moveIndex(by: 2)
                    return .comparison(.contains)
                }
                else if secondChar == UInt8(ascii: "^") {
                    moveIndex(by: 2)
                    return .comparison(.startsWith)
                }
                else if secondChar == UInt8(ascii: "$") {
                    moveIndex(by: 2)
                    return .comparison(.endsWith)
                }
            }
            else {
                if firstChar == UInt8(ascii: ">") {
                    moveIndex(by: 1)
                    return .comparison(.greaterThan)
                }
                else if firstChar == UInt8(ascii: "<") {
                    moveIndex(by: 1)
                    return .comparison(.lessThan)
                }
            }

            return nil
        }

        mutating func readQuotedString(_ quotationCharacter: UInt8) -> String? {
            guard readNextCharacter() == quotationCharacter else { return nil }

            var startIndex = index
            var offset = 0
            var result = ""

            while let char = peek(withOffset: offset) {
                switch char {
                case quotationCharacter:
                    moveIndex(by: offset + 1)

                    guard let current = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8) else { return nil }

                    result += current
                    return result

                case UInt8(ascii: "\\"):
                    moveIndex(by: offset)

                    guard let current = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8),
                          readNextCharacter() == UInt8(ascii: "\\")
                    else { return nil }

                    result += current

                    guard let escaped = readNextCharacter() else { return nil }

                    result += String(decoding: [escaped], as: UTF8.self)

                    startIndex = index
                    offset = 0

                default:
                    offset += 1
                }
            }

            return nil
        }

        private mutating func readArrayIndex() -> Int? {
            guard readNextCharacter() == UInt8(ascii: "[") else { return nil }

            let startIndex = index
            var offset = 0

            while let char = peek(withOffset: offset) {
                switch char {
                case UInt8(ascii: "]"):
                    moveIndex(by: offset + 1)

                    guard let current = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8) else {
                        return nil
                    }

                    return Int(current)

                default:
                    offset += 1
                }
            }

            return nil
        }

        mutating func readNear() -> Expression? {
            guard peekString("near(", caseInsensitive: true) else { return nil }

            moveIndex(by: 5)

            let startIndex = index
            var offset = 0

            while let char = peek(withOffset: offset) {
                switch char {
                case UInt8(ascii: ")"):
                    moveIndex(by: offset + 1)

                    guard let current = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8) else {
                        return nil
                    }

                    let components = current.components(separatedBy: ",").compactMap({ $0.trimmed() })
                    guard components.count == 3,
                          let latitude = Double(components[0]),
                          let longitude = Double(components[1]),
                          let tolerance = Double(components[2])
                    else { return nil }

                    return .near(Coordinate3D(latitude: latitude, longitude: longitude), tolerance)

                default:
                    offset += 1
                }
            }

            return nil
        }

        mutating func readWithin() -> Expression? {
            guard peekString("within(", caseInsensitive: true) else { return nil }

            moveIndex(by: 7)

            let startIndex = index
            var offset = 0

            while let char = peek(withOffset: offset) {
                switch char {
                case UInt8(ascii: ")"):
                    moveIndex(by: offset + 1)

                    guard let current = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8) else {
                        return nil
                    }

                    let components = current.components(separatedBy: ",").compactMap({ $0.trimmed() })
                    guard components.count == 4,
                          let minLon = Double(components[0]),
                          let minLat = Double(components[1]),
                          let maxLon = Double(components[2]),
                          let maxLat = Double(components[3])
                    else { return nil }

                    let sw = Coordinate3D(latitude: minLat, longitude: minLon)
                    let ne = Coordinate3D(latitude: maxLat, longitude: maxLon)
                    let bbox = BoundingBox(southWest: sw, northEast: ne)
                    return .within(bbox)

                default:
                    offset += 1
                }
            }

            return nil
        }

        mutating func readIntersects() -> Expression? {
            guard peekString("intersects(", caseInsensitive: true) else { return nil }

            moveIndex(by: 11)

            let startIndex = index
            var offset = 0

            while let char = peek(withOffset: offset) {
                switch char {
                case UInt8(ascii: ")"):
                    moveIndex(by: offset + 1)

                    guard let current = String(bytes: characters[startIndex ..< startIndex + offset], encoding: .utf8) else {
                        return nil
                    }

                    let components = current.components(separatedBy: ",").compactMap({ $0.trimmed() })
                    guard components.count == 4,
                          let minLon = Double(components[0]),
                          let minLat = Double(components[1]),
                          let maxLon = Double(components[2]),
                          let maxLat = Double(components[3])
                    else { return nil }

                    let sw = Coordinate3D(latitude: minLat, longitude: minLon)
                    let ne = Coordinate3D(latitude: maxLat, longitude: maxLon)
                    let bbox = BoundingBox(southWest: sw, northEast: ne)
                    return .intersects(bbox)

                default:
                    offset += 1
                }
            }

            return nil
        }

    }

}
