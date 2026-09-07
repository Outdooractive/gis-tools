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

// MARK: - Decodable

extension JSONValue {

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
