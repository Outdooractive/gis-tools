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
        guard let value = JSONValue(value: asJson) else {
            throw EncodingError.invalidValue(asJson, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "GeoJSON contains values that are not JSON-compatible",
                underlyingError: nil))
        }

        try value.encode(to: encoder)
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
