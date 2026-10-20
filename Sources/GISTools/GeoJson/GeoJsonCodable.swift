import Foundation

// MARK: GeoJsonCodable

extension GeoJson {

    /// Try to initialize a GeoJSON object from a Decoder.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    /// - Parameters:
    ///    - decoder: The decoder to read data from
    public init(from decoder: Decoder) throws {
        let object = try GeoJsonDecoder.decode(from: decoder)

        if let typed = object as? Self {
            self = typed
            return
        }

        // FeatureCollection normalizes any GeoJSON object.
        if let collection = FeatureCollection(object), let typed = collection as? Self {
            self = typed
            return
        }

        throw DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Invalid JSON object"))
    }

}

// MARK: -

extension GeoJson {

    /// Write the GeoJSON object to an Encoder.
    ///
    /// - important: Always projected to EPSG:4326, unless the receiver has no SRID.
    /// - Parameters:
    ///    - encoder: The encoder to write data to
    public func encode(to encoder: Encoder) throws {
        try GeoJsonEncoder.encode(asJson, to: encoder)
    }

}

extension BoundingBox: Codable {

    /// Try to initialize a BoundingBox from a Decoder.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    /// - Parameters:
    ///    - decoder: The decoder to read data from
    public init(from decoder: Decoder) throws {
        let value = try JSONValue(from: decoder)

        guard let newObject = Self(json: value.asSendable) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid JSON object"))
        }

        self = newObject
    }

    /// Write the BoundingBox to an Encoder.
    ///
    /// - important: Always projected to EPSG:4326, unless the receiver has no SRID.
    /// - Parameters:
    ///    - encoder: The encoder to write data to
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        for element in asJson {
            try container.encode(JSONValue.number(element))
        }
    }

}

extension Coordinate3D: Codable {

    /// Try to initialize a Coordinate3D from a Decoder.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    /// - Parameters:
    ///    - decoder: The decoder to read data from
    public init(from decoder: Decoder) throws {
        let value = try JSONValue(from: decoder)

        guard let newObject = Self(json: value.asSendable) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid JSON object"))
        }

        self = newObject
    }

    /// Write the Coordinate3D to an Encoder.
    ///
    /// - important: Always projected to EPSG:4326, unless the receiver has no SRID.
    /// - Parameters:
    ///    - encoder: The encoder to write data to
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        for element in asJson {
            if let element {
                try container.encode(JSONValue.number(element))
            }
            else {
                try container.encodeNil()
            }
        }
    }

}

// MARK: - SwiftData compatibility (see the README)

#if canImport(SwiftData)

/// A `ValueTransformer` for SwiftData compatibility
/// (see the README for more information/examples).
@objc(GeoJsonTransformer)
public final class GeoJsonTransformer: ValueTransformer {

    /// The name used to register this transformer.
    public static let name = NSValueTransformerName(rawValue: "GeoJsonTransformer")

    /// Register the transformer with the `ValueTransformer` system.
    public static func register() {
        ValueTransformer.setValueTransformer(GeoJsonTransformer(), forName: name)
    }

    /// Returns the class of the transformed value.
    public override class func transformedValueClass() -> AnyClass {
        // returns __SwiftValue
        type(of: Point(Coordinate3D.zero) as AnyObject)
    }

    /// Returns whether the transformer supports reverse transformation.
    public override class func allowsReverseTransformation() -> Bool {
        true
    }

    /// Encode GeoJSON to Data
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let geoJson = value as? GeoJson else { return nil }

        return geoJson.asJsonData()
    }

    /// Decode Data to GeoJSON
    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }

        return GeoJsonReader.geoJsonFrom(jsonData: data)
    }

}
#endif


// MARK: - Direct encoding

/// Encodes the `[String: Sendable]` representation directly into an encoder.
///
/// This avoids the `asJson -> JSONValue -> JSONEncoder` round trip, which
/// dominates GeoJSON encoding for large coordinate arrays.
struct EncodableGeoJson: Encodable {

    let json: [String: Sendable]

    func encode(to encoder: Encoder) throws {
        try GeoJsonEncoder.encode(json, to: encoder)
    }

}

private enum GeoJsonEncoder {

    struct Key: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            nil
        }
    }

    static func encode(_ dictionary: [String: Sendable], to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)

        for (key, value) in dictionary {
            guard let codingKey = Key(stringValue: key) else { continue }
            try encode(value, into: &container, forKey: codingKey)
        }
    }

    private static func encode(
        _ value: Sendable,
        into container: inout KeyedEncodingContainer<Key>,
        forKey key: Key
    ) throws {
        if let dictionary = value as? [String: Sendable] {
            var nested = container.nestedContainer(keyedBy: Key.self, forKey: key)
            for (nestedKey, nestedValue) in dictionary {
                guard let codingKey = Key(stringValue: nestedKey) else { continue }
                try encode(nestedValue, into: &nested, forKey: codingKey)
            }
            return
        }

        let valueType = type(of: value)
        if valueType == [Double?].self || valueType == [Double].self,
           let doubles = value as? [Double?] {
            var nested = container.nestedUnkeyedContainer(forKey: key)
            try encode(doubles, into: &nested)
            return
        }

        if let array = value as? [Sendable] {
            var nested = container.nestedUnkeyedContainer(forKey: key)
            try encode(array, into: &nested)
            return
        }

        if isNil(value) {
            try container.encodeNil(forKey: key)
            return
        }

        if let json = JSONValue(value: value) {
            try container.encode(json, forKey: key)
            return
        }

        throw EncodingError.invalidValue(value, EncodingError.Context(
            codingPath: container.codingPath + [key],
            debugDescription: "GeoJSON contains values that are not JSON-compatible",
            underlyingError: nil))
    }

    private static func encode(
        _ array: [Sendable],
        into container: inout UnkeyedEncodingContainer
    ) throws {
        for value in array {
            // Only fast-path native coordinate arrays. NSNumber arrays (for
            // example parsed JSON numbers) must keep their original type.
            let valueType = type(of: value)
            if valueType == [Double?].self || valueType == [Double].self,
               let doubles = value as? [Double?] {
                var nested = container.nestedUnkeyedContainer()
                try encode(doubles, into: &nested)
                continue
            }

            if let dictionary = value as? [String: Sendable] {
                var nested = container.nestedContainer(keyedBy: Key.self)
                for (key, nestedValue) in dictionary {
                    guard let codingKey = Key(stringValue: key) else { continue }
                    try encode(nestedValue, into: &nested, forKey: codingKey)
                }
                continue
            }

            if let nestedArray = value as? [Sendable] {
                var nested = container.nestedUnkeyedContainer()
                try encode(nestedArray, into: &nested)
                continue
            }

            if isNil(value) {
                try container.encodeNil()
                continue
            }

            if let json = JSONValue(value: value) {
                try container.encode(json)
                continue
            }

            throw EncodingError.invalidValue(value, EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "GeoJSON contains values that are not JSON-compatible",
                underlyingError: nil))
        }
    }

    private static func encode(
        _ doubles: [Double?],
        into container: inout UnkeyedEncodingContainer
    ) throws {
        for double in doubles {
            if let double {
                try container.encode(double)
            } else {
                try container.encodeNil()
            }
        }
    }

    private static func isNil(_ value: Sendable) -> Bool {
        if value is NSNull {
            return true
        }

        let mirror = Mirror(reflecting: value)
        return mirror.displayStyle == .optional && mirror.children.isEmpty
    }

}
