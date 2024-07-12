import Foundation

// MARK: GeoJsonCodable

// TODO: Check if this can be improved

extension GeoJson {

    /// Try to initialize a GeoJSON object from a Decoder.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: GeoJsonCodingKey.self)
        let json = container.decodeGeoJsonDictionary()

        guard let newObject = Self(json: json) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid JSON object"))
        }

        self = newObject
    }

    /// Write the GeoJSON object to an Encoder.
    ///
    /// - important: Always projected to EPSG:4326, unless the receiver has no SRID.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: GeoJsonCodingKey.self)

        try container.encode(geoJson: asJson)
    }

}

extension BoundingBox: Codable {

    /// Try to initialize a BoundingBox from a Decoder.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let json = container.decodeGeoJsonArray()

        guard let newObject = Self(json: json) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid JSON object"))
        }

        self = newObject
    }

    /// Write the BoundingBox to an Encoder.
    ///
    /// - important: Always projected to EPSG:4326, unless the receiver has no SRID.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        for element in asJson {
            try container.encode(element)
        }
    }

}

extension Coordinate3D: Codable {

    /// Try to initialize a Coordinate3D from a Decoder.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let json = container.decodeGeoJsonArray()

        guard let newObject = Self(json: json) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid JSON object"))
        }

        self = newObject
    }

    /// Write the Coordinate3D to an Encoder.
    ///
    /// - important: Always projected to EPSG:4326, unless the receiver has no SRID.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        for element in asJson {
            try container.encode(element)
        }
    }

}

// MARK: - SwiftData compatibility (see the README)

#if canImport(SwiftData)

/// A `ValueTransformer` for SwiftData compatibility
/// (see the README for more information/examples).
@objc(GeoJsonTransformer)
public final class GeoJsonTransformer: ValueTransformer {

    public static let name = NSValueTransformerName(rawValue: "GeoJsonTransformer")

    public static func register() {
        ValueTransformer.setValueTransformer(GeoJsonTransformer(), forName: name)
    }

    public override class func transformedValueClass() -> AnyClass {
        // returns __SwiftValue
        type(of: Point(Coordinate3D.zero) as AnyObject)
    }

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

// MARK: - Private

private struct GeoJsonCodingKey: CodingKey {

    var stringValue: String
    var intValue: Int? { nil }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }

}

extension KeyedEncodingContainer where Key == GeoJsonCodingKey {

    fileprivate mutating func encode(geoJson dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            guard let codingKey = GeoJsonCodingKey(stringValue: key) else { continue }

            switch value {
            // Note: Numeric before Bool so that numbers don't get recognized as Bools
            case let encoded as Double:
                try encode(encoded, forKey: codingKey)

            case let encoded as Float:
                try encode(encoded, forKey: codingKey)

            case let encoded as Int:
                try encode(encoded, forKey: codingKey)

            case let encoded as Bool:
                try encode(encoded, forKey: codingKey)

            case let encoded as String:
                try encode(encoded, forKey: codingKey)

            case let encoded as [String: Any]:
                var nestedContainer = nestedContainer(keyedBy: GeoJsonCodingKey.self, forKey: codingKey)
                try nestedContainer.encode(geoJson: encoded)

            case let encoded as [[String: Any]]:
                var nestedContainer = nestedUnkeyedContainer(forKey: codingKey)
                for element in encoded {
                    var container = nestedContainer.nestedContainer(keyedBy: GeoJsonCodingKey.self)
                    try container.encode(geoJson: element)
                }

            case let encoded as [Any]:
                var nestedContainer = nestedUnkeyedContainer(forKey: codingKey)
                for element in encoded {
                    if let encoded = element as? Encodable {
                        try nestedContainer.encode(encoded)
                    }
                }

            default:
                print("Missing conversion for (\(key), \(type(of: value)))")
            }
        }
    }

}

extension KeyedDecodingContainer where Key == GeoJsonCodingKey {

    fileprivate func decodeGeoJsonDictionary() -> [String: Any] {
        var result: [String: Any] = [:]

        for key in allKeys {
            // Order is important
            if let decoded = try? decode(String.self, forKey: key) {
                result[key.stringValue] = decoded
            }
            else if let decoded = try? decode(Bool.self, forKey: key) {
                result[key.stringValue] = decoded
            }
            else if let decoded = try? decode(Double.self, forKey: key) {
                result[key.stringValue] = decoded
            }
            else if let decoded = try? decode(Int.self, forKey: key) {
                result[key.stringValue] = decoded
            }
            else if let decoded = try? decode(Float.self, forKey: key) {
                result[key.stringValue] = decoded
            }
            else if var decoded = try? nestedUnkeyedContainer(forKey: key) {
                result[key.stringValue] = decoded.decodeGeoJsonArray()
            }
            else if let decoded = try? nestedContainer(keyedBy: GeoJsonCodingKey.self, forKey: key) {
                result[key.stringValue] = decoded.decodeGeoJsonDictionary()
            }
            else {
                print("Missing conversion for \(key.stringValue)")
            }
        }

        return result
    }

}

extension UnkeyedDecodingContainer {

    fileprivate mutating func decodeGeoJsonArray() -> [Any?] {
        var result: [Any?] = []

        while !isAtEnd {
            // Again, order is important
            if let decoded = try? decode(String.self) {
                result.append(decoded)
            }
            else if let decoded = try? decode(Bool.self) {
                result.append(decoded)
            }
            else if let decoded = try? decode(Double.self) {
                result.append(decoded)
            }
            else if let decoded = try? decode(Int.self) {
                result.append(decoded)
            }
            else if let decoded = try? decode(Float.self) {
                result.append(decoded)
            }
            else if let isNil = try? decodeNil(), isNil {
                result.append(nil)
            }
            else if var decoded = try? nestedUnkeyedContainer() {
                result.append(decoded.decodeGeoJsonArray())
            }
            else if let decoded = try? nestedContainer(keyedBy: GeoJsonCodingKey.self) {
                result.append(decoded.decodeGeoJsonDictionary())
            }
            else {
                print("Missing conversion while decoding an array")
            }
        }

        return result
    }

}
