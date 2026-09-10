import Foundation
@testable import GISTools
import Testing

struct JSONValueTests {

    // MARK: - Conversion

    // Validates conversion of scalar values, including number normalization.
    @Test
    func conversionScalars() async throws {
        #expect(JSONValue(value: "hello") == .string("hello"))
        #expect(JSONValue(value: true) == .bool(true))
        #expect(JSONValue(value: false) == .bool(false))
        #expect(JSONValue(value: 3) == .int(3))
        #expect(JSONValue(value: Int64(-5)) == .int(-5))
        #expect(JSONValue(value: UInt(7)) == .int(7))
        #expect(JSONValue(value: 3.0) == .int(3))
        #expect(JSONValue(value: 3.5) == .number(3.5))
        #expect(JSONValue(value: Float(2.0)) == .int(2))
        #expect(JSONValue(value: Float(2.5)) == .number(2.5))
        #expect(JSONValue(value: NSNull()) == .null)
        #expect(JSONValue(value: nil) == nil)
    }

    // Validates that booleans are not misread as numbers and vice versa
    // (both are NSNumber-backed after JSON parsing).
    @Test
    func conversionBoolDisambiguation() async throws {
        #expect(JSONValue(value: NSNumber(value: true)) == .bool(true))
        #expect(JSONValue(value: NSNumber(value: false)) == .bool(false))
        #expect(JSONValue(value: NSNumber(value: 1)) == .int(1))
        #expect(JSONValue(value: NSNumber(value: 0)) == .int(0))
        #expect(JSONValue(value: NSNumber(value: 3.0)) == .int(3))
        #expect(JSONValue(value: NSNumber(value: 3.5)) == .number(3.5))
    }

    // Validates that integers beyond the Int range fall back to .number.
    @Test
    func conversionLargeNumbers() async throws {
        // 9223372036854775807 is Int.max
        #expect(JSONValue(value: UInt64(9_223_372_036_854_775_807)) == .int(9_223_372_036_854_775_807))
        #expect(JSONValue(value: NSNumber(value: UInt64(9_223_372_036_854_775_807))) == .int(9_223_372_036_854_775_807))

        // 9223372036854775808 is Int.max + 1
        #expect(JSONValue(value: UInt64(9_223_372_036_854_775_808)) == .number(9_223_372_036_854_775_808.0))
        #expect(JSONValue(value: NSNumber(value: UInt64(9_223_372_036_854_775_808))) == .number(9_223_372_036_854_775_808.0))
    }

    // Validates conversion of nested structures.
    @Test
    func conversionNested() async throws {
        let list: [Sendable] = [1, "two", 3.0]
        let dictionary: [String: Sendable] = [
            "name": "test",
            "count": 3,
            "fractional": 3.5,
            "flag": true,
            "nothing": NSNull(),
            "list": list,
            "nested": ["inner": 1.0],
        ]

        let jsonValue = try #require(JSONValue(value: dictionary))

        #expect(jsonValue == .object([
            "name": .string("test"),
            "count": .int(3),
            "fractional": .number(3.5),
            "flag": .bool(true),
            "nothing": .null,
            "list": .array([.int(1), .string("two"), .int(3)]),
            "nested": .object(["inner": .int(1)]),
        ]))
    }

    // Validates that non-JSON values fail conversion.
    @Test
    func conversionNotJson() async throws {
        #expect(JSONValue(value: Data([0x01])) == nil)

        struct Custom: Sendable {}
        #expect(JSONValue(value: Custom()) == nil)
    }

    // MARK: - Typed accessors

    // Validates the typed accessors for each case.
    @Test
    func accessors() async throws {
        #expect(JSONValue.string("hello").stringValue == "hello")
        #expect(JSONValue.string("hello").intValue == nil)
        #expect(JSONValue.string("hello").boolValue == nil)

        #expect(JSONValue.bool(true).boolValue == true)
        #expect(JSONValue.bool(true).doubleValue == nil)

        #expect(JSONValue.int(3).intValue == 3)
        #expect(JSONValue.int(3).doubleValue == 3.0)
        #expect(JSONValue.int(3).stringValue == nil)

        #expect(JSONValue.number(3.0).intValue == 3)
        #expect(JSONValue.number(3.5).intValue == nil)
        #expect(JSONValue.number(3.5).doubleValue == 3.5)

        #expect(JSONValue.array([.int(1)]).arrayValue == [.int(1)])
        #expect(JSONValue.array([.int(1)]).objectValue == nil)

        #expect(JSONValue.object(["a": .int(1)]).objectValue == ["a": .int(1)])
        #expect(JSONValue.object(["a": .int(1)]).arrayValue == nil)

        #expect(JSONValue.null.isNull)
        #expect(!JSONValue.int(0).isNull)
    }

    // MARK: - Subscripts

    // Validates object and array subscript access, including chaining.
    @Test
    func subscripts() async throws {
        let value: JSONValue = .object([
            "a": .object([
                "b": .array([.string("x"), .int(1)]),
            ]),
            "missing": .null,
        ])

        #expect(value["a"]?["b"]?[0] == .string("x"))
        #expect(value["a"]?["b"]?[1] == .int(1))
        #expect(value["a"]?["b"]?[2] == nil)
        #expect(value["missing"] == .null)
        #expect(value["a"]?["nonexistent"] == nil)
        #expect(value["nonexistent"] == nil)
        #expect(value["missing"]?["nested"] == nil)

        #expect(value[0] == nil)
        #expect(JSONValue.array([.int(1)])[0] == .int(1))
    }

    // MARK: - Coercion

    // Validates coercion of strings into numbers and booleans.
    @Test
    func coercedValues() async throws {
        #expect(JSONValue.string("3").coercedIntValue == 3)
        #expect(JSONValue.string("3.0").coercedIntValue == 3)
        #expect(JSONValue.string("3.5").coercedIntValue == nil)
        #expect(JSONValue.string("text").coercedIntValue == nil)
        #expect(JSONValue.int(3).coercedIntValue == 3)
        #expect(JSONValue.number(3.0).coercedIntValue == 3)
        #expect(JSONValue.number(3.5).coercedIntValue == nil)
        #expect(JSONValue.bool(true).coercedIntValue == nil)

        #expect(JSONValue.string("3.5").coercedDoubleValue == 3.5)
        #expect(JSONValue.string("text").coercedDoubleValue == nil)
        #expect(JSONValue.number(3.5).coercedDoubleValue == 3.5)
        #expect(JSONValue.int(3).coercedDoubleValue == 3.0)

        #expect(JSONValue.string("true").coercedBoolValue == true)
        #expect(JSONValue.string("TRUE").coercedBoolValue == true)
        #expect(JSONValue.string("1").coercedBoolValue == true)
        #expect(JSONValue.string("false").coercedBoolValue == false)
        #expect(JSONValue.string("0").coercedBoolValue == false)
        #expect(JSONValue.string("yes").coercedBoolValue == nil)
        #expect(JSONValue.bool(true).coercedBoolValue == true)
        #expect(JSONValue.int(1).coercedBoolValue == nil)

        #expect(JSONValue.string("text").coercedStringValue == "text")
        #expect(JSONValue.int(3).coercedStringValue == nil)
    }

    // MARK: - Literals

    // Validates the ExpressibleBy*Literal conformances.
    @Test
    func literals() async throws {
        let string: JSONValue = "hello"
        #expect(string == .string("hello"))

        let int: JSONValue = 3
        #expect(int == .int(3))

        let float: JSONValue = 3.5
        #expect(float == .number(3.5))

        let integralFloat: JSONValue = 3.0
        #expect(integralFloat == .int(3))

        let bool: JSONValue = true
        #expect(bool == .bool(true))

        let array: JSONValue = [1, "two", 3.5, true]
        #expect(array == .array([.int(1), .string("two"), .number(3.5), .bool(true)]))

        let object: JSONValue = ["a": 1, "b": "two"]
        #expect(object == .object(["a": .int(1), "b": .string("two")]))

        let nested: JSONValue = ["a": [1, 2.5, true]]
        #expect(nested["a"]?[1] == .number(2.5))
    }

    // MARK: - asSendable

    // Validates the reverse conversion back into property-style values.
    @Test
    func asSendableRoundTrip() async throws {
        let array: [Sendable] = [1, 2, 3]
        let original: [String: Sendable] = [
            "string": "text",
            "int": 42,
            "fractional": 2.5,
            "bool": true,
            "null": NSNull(),
            "array": array,
            "object": ["inner": 3.5],
        ]

        let jsonValue = try #require(JSONValue(value: original))
        let converted = try #require(jsonValue.asSendable as? [String: Sendable])

        #expect(converted["string"] as? String == "text")
        #expect(converted["int"] as? Int == 42)
        #expect(converted["fractional"] as? Double == 2.5)
        #expect(converted["bool"] as? Bool == true)
        #expect(converted["null"] is NSNull)
        #expect((converted["array"] as? [Sendable])?.compactMap({ $0 as? Int }) == [1, 2, 3])
        #expect((converted["object"] as? [String: Sendable])?["inner"] as? Double == 3.5)

        // The conversion is stable across a second round trip.
        #expect(JSONValue(value: converted) == jsonValue)
    }

    // MARK: - Parsing

    // Validates parsing from JSON data and strings.
    @Test
    func parsing() async throws {
        let value = try #require(JSONValue(jsonString: #"{"a": [1, 3.0, "two"], "b": null}"#))

        #expect(value["a"]?[0] == .int(1))
        #expect(value["a"]?[1] == .int(3))
        #expect(value["a"]?[2] == .string("two"))
        #expect(value["b"] == .null)
        #expect(JSONValue(jsonString: "invalid") == nil)

        let data = try #require(#"{"a": 3.5}"#.data(using: .utf8))
        #expect(JSONValue(jsonData: data)?["a"] == .number(3.5))
        #expect(JSONValue(jsonData: Data([0x01])) == nil)
    }

    // MARK: - Decoding

    // Validates decoding a property-style dictionary into a domain type,
    // including the 3.0 → Int normalization.
    @Test
    func decodeDictionary() async throws {
        struct Payload: Codable, Equatable {
            let name: String
            let priority: Int
        }

        let dictionary: [String: Sendable] = ["name": "test", "priority": 3.0]
        let payload = try JSONValue.decode(dictionary, as: Payload.self, decoder: JSONDecoder())

        #expect(payload == Payload(name: "test", priority: 3))
    }

    // MARK: - Codable

    // Validates encoding and decoding round trips.
    @Test
    func codableRoundTrip() async throws {
        let values: [JSONValue] = [
            .string("text"),
            .int(3),
            .number(3.5),
            .bool(true),
            .null,
            .array([.int(1), .string("two")]),
            .object(["inner": .int(1)]),
        ]

        let data = try JSONEncoder().encode(values)
        let decoded = try JSONDecoder().decode([JSONValue].self, from: data)

        #expect(decoded == values)
    }

    // Validates that fractional JSON numbers decode to .int when integral.
    @Test
    func codableNormalizesNumbers() async throws {
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data("3".utf8)) == .int(3))
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data("3.0".utf8)) == .int(3))
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data("3.5".utf8)) == .number(3.5))
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data("true".utf8)) == .bool(true))
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data("false".utf8)) == .bool(false))
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data("null".utf8)) == .null)
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data("\"text\"".utf8)) == .string("text"))
    }

    // Validates that invalid input throws a DecodingError.
    @Test
    func codableInvalid() async throws {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(JSONValue.self, from: Data("{\"x\":".utf8))
        }
    }

    // MARK: - Equatable & Hashable

    // Validates cross-case equality between .int and .number.
    @Test
    func equalityNumberNormalization() async throws {
        #expect(JSONValue.int(3) == .number(3.0))
        #expect(JSONValue.number(3.0) == .int(3))
        #expect(JSONValue.int(3) != .number(3.5))
        #expect(JSONValue.int(3) != .string("3"))
        #expect(JSONValue.int(3) != .bool(true))
        #expect(JSONValue.null != JSONValue.bool(false))

        // Nested inside containers.
        #expect(JSONValue.array([.int(3)]) == .array([.number(3.0)]))
        #expect(JSONValue.object(["a": .int(3)]) == .object(["a": .number(3.0)]))

        // Exact comparisons within the same case.
        #expect(JSONValue.number(0.1 + 0.2) != JSONValue.number(0.3))
        #expect(JSONValue.number(0.30000000000000004) != JSONValue.number(0.3))
    }

    // Validates that equal values deduplicate in sets, including .int/.number
    // equivalence.
    @Test
    func hashable() async throws {
        let set: Set<JSONValue> = [.int(3), .int(3), .number(3.0), .number(3.5), .string("3"), .bool(true)]

        #expect(set.count == 4)
    }

    // MARK: - Description

    // Validates the JSON string representations.
    @Test
    func descriptions() async throws {
        #expect(JSONValue.string("text").description == "\"text\"")
        #expect(JSONValue.int(3).description == "3")
        #expect(JSONValue.number(3.5).description == "3.5")
        #expect(JSONValue.bool(true).description == "true")
        #expect(JSONValue.null.description == "null")
        #expect(JSONValue.number(.nan).description == "<invalid>")
        #expect(JSONValue.number(.infinity).description == "<invalid>")

        let object = JSONValue.object(["b": .int(2), "a": .int(1)])
        #expect(object.description == #"{"a":1,"b":2}"#)
        #expect(object.asJsonString(prettyPrinted: true) != nil)

        #expect(JSONValue.object(["b": .int(2), "a": .int(1)]).debugDescription == #"{"a":1,"b":2}"#)
    }

}
