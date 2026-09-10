import Foundation

/// A JSON value.
///
/// ``Feature/properties`` and ``GeoJson/foreignMembers`` store JSON-compatible
/// values as `[String: Sendable]`. ``JSONValue`` is their typed counterpart:
/// it can be created from any of those values (`init?(value:)`), supports
/// exhaustive pattern matching, and round-trips through `Codable`.
///
/// Numbers are normalized: an integral number (e.g. `3.0`) is represented as
/// `.int(3)`, so values compare and hash consistently regardless of how a
/// producer encoded them. Integers beyond `Int.max` fall back to `.number`
/// (with precision loss above 2^53, like the JavaScript ecosystem).
///
/// Equality follows the same philosophy: an integer and a number compare
/// equal when the number is exactly that integer (`.int(3)` equals
/// `.number(3.0)`), including inside arrays and objects. Integer-vs-integer
/// and double-vs-double comparisons remain exact.
///
/// JSON `null` has no literal syntax (to keep `nil` and `Optional` semantics
/// unambiguous); use the `.null` case.
public enum JSONValue: Hashable, Sendable, Codable {

    /// A string.
    case string(String)
    /// A number.
    case number(Double)
    /// An integer.
    case int(Int)
    /// A boolean.
    case bool(Bool)
    /// An array.
    case array([JSONValue])
    /// An object.
    case object([String: JSONValue])
    /// JSON `null`.
    case null

}

// MARK: - Access

extension JSONValue {

    /// `true` if the receiver is `.null`.
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    /// The receiver as a `String`, or `nil` if it is not a string.
    public var stringValue: String? {
        if case let .string(string) = self { return string }
        return nil
    }

    /// The receiver as a `Bool`, or `nil` if it is not a boolean.
    public var boolValue: Bool? {
        if case let .bool(bool) = self { return bool }
        return nil
    }

    /// The receiver as an `Int`, or `nil` if it is not exactly representable
    /// as an integer.
    ///
    /// Integral numbers are converted, so `.number(3.0)` returns `3`, while
    /// fractional numbers return `nil`.
    public var intValue: Int? {
        if case let .int(int) = self { return int }
        if case let .number(double) = self { return Int(exactly: double) }
        return nil
    }

    /// The receiver as a `Double`, or `nil` if it is not a number.
    ///
    /// Integers are converted, so `.int(3)` returns `3.0`.
    public var doubleValue: Double? {
        if case let .number(double) = self { return double }
        if case let .int(int) = self { return Double(int) }
        return nil
    }

    /// The receiver as a `[JSONValue]`, or `nil` if it is not an array.
    public var arrayValue: [JSONValue]? {
        if case let .array(array) = self { return array }
        return nil
    }

    /// The receiver as a `[String: JSONValue]`, or `nil` if it is not an object.
    public var objectValue: [String: JSONValue]? {
        if case let .object(object) = self { return object }
        return nil
    }

}

// MARK: - Subscripts

extension JSONValue {

    /// Access an object member by key.
    ///
    /// Subscripts chain for nested access: `value["a"]?["b"]?[0]`.
    ///
    /// - Parameter key: The member key
    /// - Returns: The member value, or `nil` for missing keys and non-object values
    public subscript(key: String) -> JSONValue? {
        objectValue?[key]
    }

    /// Access an array element by index.
    ///
    /// Subscripts chain for nested access: `value["a"]?["b"]?[0]`.
    ///
    /// - Parameter index: The element index
    /// - Returns: The element value, or `nil` for out-of-bounds indices and
    ///            non-array values
    public subscript(index: Int) -> JSONValue? {
        guard case let .array(array) = self, array.indices.contains(index) else { return nil }

        return array[index]
    }

}

// MARK: - Coercion

extension JSONValue {

    /// The receiver as an `Int`, coercing numeric strings when possible.
    ///
    /// Accepts `.int`, integral `.number` (e.g. `.number(3.0)`), and strings
    /// like `"3"` or `"3.0"`. Fractional numbers and non-numeric strings
    /// return `nil`.
    public var coercedIntValue: Int? {
        if case let .string(string) = self {
            return Double(string).flatMap({ Int(exactly: $0) })
        }

        return intValue
    }

    /// The receiver as a `Double`, coercing numeric strings when possible.
    ///
    /// Accepts `.number`, `.int`, and strings like `"3"` or `"3.5"`.
    public var coercedDoubleValue: Double? {
        if case let .string(string) = self { return Double(string) }

        return doubleValue
    }

    /// The receiver as a `Bool`, coercing string representations when possible.
    ///
    /// Accepts `.bool` and the strings `"true"`, `"false"`, `"1"` and `"0"`
    /// (case-insensitive). Numbers are never converted to booleans.
    public var coercedBoolValue: Bool? {
        if case let .string(string) = self {
            switch string.lowercased() {
            case "true", "1": return true
            case "false", "0": return false
            default: return nil
            }
        }

        return boolValue
    }

    /// The receiver as a `String`, or `nil` if it is not a string.
    ///
    /// Strings are never synthesized from other values.
    public var coercedStringValue: String? {
        stringValue
    }

}

// MARK: - Conversion

extension JSONValue {

    /// Try to initialize a `JSONValue` from any property-style value
    /// (as stored in ``Feature/properties`` and ``GeoJson/foreignMembers``).
    ///
    /// Numbers are normalized to `.int` when they can be represented exactly.
    /// Values that are not JSON-compatible (e.g. `Data` or custom types) fail.
    ///
    /// - Parameter value: The value to convert
    public init?(value: Any?) {
        guard let value else { return nil }

        if value is NSNull {
            self = .null
            return
        }

        if let string = JsonCoercion.string(value) {
            self = .string(string)
            return
        }

        if let bool = JsonCoercion.bool(value) {
            self = .bool(bool)
            return
        }

        if let int = JsonCoercion.int(value) {
            self = .int(int)
            return
        }

        if let double = JsonCoercion.double(value) {
            self = .number(double)
            return
        }

        if let dictionary = JsonCoercion.dictionary(value) {
            var result: [String: JSONValue] = [:]
            result.reserveCapacity(dictionary.count)

            for (key, element) in dictionary {
                guard let jsonValue = JSONValue(value: element) else { return nil }
                result[key] = jsonValue
            }

            self = .object(result)
            return
        }

        if let elements = JsonCoercion.array(value) {
            var result: [JSONValue] = []
            result.reserveCapacity(elements.count)

            for element in elements {
                guard let jsonValue = JSONValue(value: element) else { return nil }
                result.append(jsonValue)
            }

            self = .array(result)
            return
        }

        return nil
    }

    /// The receiver as a `Sendable` JSON value (the representation used by
    /// ``Feature/properties`` and ``GeoJson/foreignMembers``).
    public var asSendable: Sendable {
        switch self {
        case .string(let string): string
        case .number(let double): double
        case .int(let int): int
        case .bool(let bool): bool
        case .array(let array): array.map({ $0.asSendable })
        case .object(let object): object.mapValues({ $0.asSendable })
        case .null: NSNull()
        }
    }

}

// MARK: - Parsing

extension JSONValue {

    /// Try to initialize from JSON data.
    ///
    /// Integral numbers (including fractional input such as `3.0`) normalize
    /// to `.int`, like `init(from:)`.
    ///
    /// - Parameter jsonData: The JSON data
    public init?(jsonData: Data) {
        guard let value = try? JSONDecoder().decode(JSONValue.self, from: jsonData) else { return nil }

        self = value
    }

    /// Try to initialize from a JSON string.
    ///
    /// Integral numbers (including fractional input such as `3.0`) normalize
    /// to `.int`, like `init(from:)`.
    ///
    /// - Parameter jsonString: The JSON string
    public init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return nil }

        self.init(jsonData: data)
    }

}

// MARK: - Literals

extension JSONValue: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = .string(value)
    }

}

extension JSONValue: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) {
        self = .int(value)
    }

}

extension JSONValue: ExpressibleByFloatLiteral {

    public init(floatLiteral value: Double) {
        if let int = Int(exactly: value) {
            self = .int(int)
        }
        else {
            self = .number(value)
        }
    }

}

extension JSONValue: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }

}

extension JSONValue: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }

}

extension JSONValue: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        var object: [String: JSONValue] = [:]
        object.reserveCapacity(elements.count)

        for (key, value) in elements {
            object[key] = value
        }

        self = .object(object)
    }

}

// MARK: - Equatable & Hashable

extension JSONValue {

    public static func == (lhs: JSONValue, rhs: JSONValue) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null):
            true
        case (.bool(let lhsValue), .bool(let rhsValue)):
            lhsValue == rhsValue
        case (.string(let lhsValue), .string(let rhsValue)):
            lhsValue == rhsValue
        case (.int(let lhsValue), .int(let rhsValue)):
            lhsValue == rhsValue
        case (.number(let lhsValue), .number(let rhsValue)):
            lhsValue == rhsValue
        case (.int(let intValue), .number(let doubleValue)),
             (.number(let doubleValue), .int(let intValue)):
            Int(exactly: doubleValue) == intValue
        case (.array(let lhsValue), .array(let rhsValue)):
            lhsValue == rhsValue
        case (.object(let lhsValue), .object(let rhsValue)):
            lhsValue == rhsValue
        default:
            false
        }
    }

    public func hash(into hasher: inout Hasher) {
        // `.int` and `.number` share a tag so that equal numbers hash equal.
        // Integers hash as their `Double` conversion, which is exact for
        // every value that can compare equal to a `.number` (|value| <= 2^53);
        // larger integers only ever collide, which is allowed.
        switch self {
        case .string(let string):
            hasher.combine(Tag.string)
            hasher.combine(string)
        case .number(let double):
            hasher.combine(Tag.number)
            hasher.combine(double)
        case .int(let int):
            hasher.combine(Tag.number)
            hasher.combine(Double(int))
        case .bool(let bool):
            hasher.combine(Tag.bool)
            hasher.combine(bool)
        case .array(let array):
            hasher.combine(Tag.array)
            hasher.combine(array)
        case .object(let object):
            hasher.combine(Tag.object)
            hasher.combine(object)
        case .null:
            hasher.combine(Tag.null)
        }
    }

    /// Case tags for `hash(into:)`.
    private enum Tag {

        case string
        case number
        case bool
        case array
        case object
        case null

    }

}

// MARK: - Description

extension JSONValue: CustomStringConvertible, CustomDebugStringConvertible {

    /// The receiver as a compact JSON string (object keys sorted).
    ///
    /// Values that cannot be represented in JSON (e.g. `NaN`) render as
    /// `<invalid>`.
    public var description: String {
        asJsonString() ?? "<invalid>"
    }

    /// The receiver as a compact JSON string, suitable for debugging.
    public var debugDescription: String {
        description
    }

}

extension JSONValue {

    /// The receiver as JSON data (object keys sorted).
    ///
    /// - Parameter prettyPrinted: When `true`, format the output with indentation
    /// - Returns: The JSON data, or `nil` if the value cannot be represented
    ///            in JSON (e.g. `NaN`)
    public func asJsonData(prettyPrinted: Bool = false) -> Data? {
        let encoder = JSONEncoder()

        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        else {
            encoder.outputFormatting = [.sortedKeys]
        }

        return try? encoder.encode(self)
    }

    /// The receiver as a JSON string (object keys sorted).
    ///
    /// - Parameter prettyPrinted: When `true`, format the output with indentation
    /// - Returns: The JSON string, or `nil` if the value cannot be represented
    ///            in JSON (e.g. `NaN`)
    public func asJsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return nil }

        return String(data: data, encoding: .utf8)
    }

}

// MARK: - Decodable

extension JSONValue {

    /// Convert a property-style dictionary into a `[String: JSONValue]` dictionary.
    ///
    /// - Parameter dictionary: The property-style dictionary
    /// - Returns: The values as ``JSONValue`` (normalizing numbers along the way)
    /// - Throws: A `DecodingError` if a value is not JSON-compatible
    static func jsonDictionary(from dictionary: [String: Sendable]) throws -> [String: JSONValue] {
        var jsonDictionary: [String: JSONValue] = [:]
        jsonDictionary.reserveCapacity(dictionary.count)

        for (key, value) in dictionary {
            guard let jsonValue = JSONValue(value: value) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: [],
                    debugDescription: "The value for key \"\(key)\" is not JSON-compatible"))
            }
            jsonDictionary[key] = jsonValue
        }

        return jsonDictionary
    }

    /// Decode a `[String: Sendable]` dictionary into a `Decodable` type.
    ///
    /// The values are converted to ``JSONValue`` (normalizing numbers along
    /// the way), encoded to JSON, and decoded with the given decoder — so
    /// `JSONDecoder` strategies apply and real `DecodingError`s are thrown
    /// instead of failing silently.
    ///
    /// - Parameters:
    ///    - dictionary: The property-style dictionary
    ///    - type: The type to decode into
    ///    - decoder: The decoder to use
    /// - Returns: The decoded value
    /// - Throws: A `DecodingError` if the dictionary cannot be decoded into
    ///           the given type, or if a value is not JSON-compatible
    static func decode<T: Decodable>(
        _ dictionary: [String: Sendable],
        as type: T.Type,
        decoder: JSONDecoder
    ) throws -> T {
        let jsonDictionary = try jsonDictionary(from: dictionary)
        let data = try JSONEncoder().encode(jsonDictionary)
        return try decoder.decode(T.self, from: data)
    }

}

// MARK: - Codable

extension JSONValue {

    /// Try to decode any JSON value.
    ///
    /// Integral numbers (including fractional input such as `3.0`) decode to
    /// `.int`, keeping values comparable across producers.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }

        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }

        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
            return
        }

        if let int = try? container.decode(Int.self) {
            self = .int(int)
            return
        }

        if let double = try? container.decode(Double.self) {
            if let int = Int(exactly: double) {
                self = .int(int)
            }
            else {
                self = .number(double)
            }
            return
        }

        if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
            return
        }

        if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
            return
        }

        throw DecodingError.dataCorrupted(.init(
            codingPath: decoder.codingPath,
            debugDescription: "Unsupported JSON value"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let string): try container.encode(string)
        case .number(let double): try container.encode(double)
        case .int(let int): try container.encode(int)
        case .bool(let bool): try container.encode(bool)
        case .array(let array): try container.encode(array)
        case .object(let object): try container.encode(object)
        case .null: try container.encodeNil()
        }
    }

}
