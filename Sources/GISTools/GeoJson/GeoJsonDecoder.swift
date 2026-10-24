import Foundation

// MARK: - Typed GeoJSON decoder

/// Fast, typed decoding of GeoJSON from `Data`.
///
/// `init?(json:)` and `GeoJsonParser` accept an already-parsed tree and
/// repeatedly coerce it. This decoder feeds `JSONDecoder` straight into
/// `Coordinate3D` and the geometry types, using ``JSONValue`` only for
/// properties and foreign members.
enum GeoJsonDecoder {

    static func decode(jsonData: Data) -> GeoJson? {
        // Validate through the same parser used by every other loading path,
        // so the typed decoder cannot accept structurally invalid GeoJSON
        // (wrong coordinate counts, unclosed rings, invalid ids, ...).
        guard let jsonData = Gzip.decompressIfNeeded(jsonData),
              let result = try? GeoJsonParser.parse(jsonData: jsonData)
        else { return nil }

        // Match the parser's lenient contract: malformed members are reported
        // as issues and dropped, but the remaining valid object is returned.
        // Structural validation has already run in the parser.
        return result.object
    }

    static func decode(from decoder: Decoder) throws -> GeoJson {
        let object = try DecodedGeoJson(from: decoder).asGeoJson

        // The `Decodable` entry point has no raw document to parse; round-trip
        // the typed result through the parser so both paths agree.
        guard let data = object.asJsonData(prettyPrinted: false),
              let result = try? GeoJsonParser.parse(jsonData: data),
              let validated = result.object
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Structurally invalid GeoJSON"))
        }

        return validated
    }

    static func decode<T: GeoJson>(jsonData: Data, as type: T.Type) -> T? {
        guard let object = decode(jsonData: jsonData) else { return nil }

        if let typed = object as? T {
            return typed
        }

        // FeatureCollection normalizes any GeoJSON object, matching its
        // `init?(json:)` behaviour.
        if let collection = FeatureCollection(object), let typed = collection as? T {
            return typed
        }

        return nil
    }

}

// MARK: - Keys

private enum GeoJsonKey: String, CodingKey {
    case type
    case coordinates
    case geometries
    case geometry
    case properties
    case features
    case id
    case bbox
}

private struct DynamicCodingKey: CodingKey {

    let stringValue: String
    var intValue: Int? { nil }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }

}

/// Decodes an element but converts a failure into `nil`, matching the
/// parser's lenient treatment of malformed members.
private struct FailableDecodable<Value: Decodable>: Decodable {

    let value: Value?

    init(from decoder: Decoder) {
        value = try? Value(from: decoder)
    }

}

// MARK: - Foreign members

private enum GeoJsonForeignMembers {

    static func decode(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        excluding keys: Set<String>
    ) -> [String: Sendable] {
        var result: [String: Sendable] = [:]

        for key in container.allKeys where !keys.contains(key.stringValue) {
            if let value = try? container.decode(JSONValue.self, forKey: key) {
                result[key.stringValue] = value.asSendable
            }
        }

        return result
    }

    static func decode(
        from decoder: Decoder,
        excluding keys: Set<String>
    ) throws -> [String: Sendable] {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        return decode(from: container, excluding: keys)
    }

}

// MARK: - Coordinates

/// A position array decoded directly into a `Coordinate3D`.
private struct DecodedCoordinate: Decodable {

    let coordinate: Coordinate3D

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let longitude = try container.decode(Double.self)
        let latitude = try container.decode(Double.self)
        let altitude = try container.decodeIfPresent(Double.self)
        let m = try container.decodeIfPresent(Double.self)

        coordinate = Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            m: m)
    }

}

/// A coordinate array decoded into `[Coordinate3D]` without an intermediate
/// position representation.
private struct DecodedCoordinateArray: Decodable {

    let coordinates: [Coordinate3D]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Coordinate3D] = []
        if let count = container.count {
            result.reserveCapacity(count)
        }

        while !container.isAtEnd {
            let position = try container.decode(DecodedCoordinate.self)
            result.append(position.coordinate)
        }

        coordinates = result
    }

}

// MARK: - Bounding box

private struct DecodedBoundingBox: Decodable {

    let values: [Double]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Double] = []
        if let count = container.count {
            result.reserveCapacity(count)
        }

        while !container.isAtEnd {
            result.append(try container.decode(Double.self))
        }

        guard result.count == 4 || result.count == 6 else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "bbox must contain four or six numbers"))
        }

        values = result
    }

}

// MARK: - Geometry

private struct DecodedGeometry: Decodable {

    let geometry: GeoJsonGeometry
    let boundingBox: BoundingBox?
    let foreignMembers: [String: Sendable]

    init(from decoder: Decoder) throws {
        let keys = try decoder.container(keyedBy: GeoJsonKey.self)
        let type = try keys.decode(String.self, forKey: .type)
        let boundingBox = try keys.decodeIfPresent(DecodedBoundingBox.self, forKey: .bbox)
            .flatMap { BoundingBox(json: $0.values) }

        let geometry: GeoJsonGeometry
        let knownKeys: Set<String>

        switch type {
        case GeoJsonType.point.rawValue:
            let position = try keys.decode(DecodedCoordinate.self, forKey: .coordinates)
            geometry = Point(position.coordinate)
            knownKeys = ["type", "coordinates", "bbox"]

        case GeoJsonType.multiPoint.rawValue:
            let positions = try keys.decode(DecodedCoordinateArray.self, forKey: .coordinates)
            geometry = MultiPoint(unchecked: positions.coordinates)
            knownKeys = ["type", "coordinates", "bbox"]

        case GeoJsonType.lineString.rawValue:
            let positions = try keys.decode(DecodedCoordinateArray.self, forKey: .coordinates)
            geometry = LineString(unchecked: positions.coordinates)
            knownKeys = ["type", "coordinates", "bbox"]

        case GeoJsonType.multiLineString.rawValue:
            let lines = try keys.decode([DecodedCoordinateArray].self, forKey: .coordinates)
            geometry = MultiLineString(unchecked: lines.map(\.coordinates))
            knownKeys = ["type", "coordinates", "bbox"]

        case GeoJsonType.polygon.rawValue:
            let rings = try keys.decode([DecodedCoordinateArray].self, forKey: .coordinates)
            geometry = Polygon(unchecked: rings.map(\.coordinates))
            knownKeys = ["type", "coordinates", "bbox"]

        case GeoJsonType.multiPolygon.rawValue:
            let polygons = try keys.decode([[DecodedCoordinateArray]].self, forKey: .coordinates)
            geometry = MultiPolygon(unchecked: polygons.map { $0.map(\.coordinates) })
            knownKeys = ["type", "coordinates", "bbox"]

        case GeoJsonType.geometryCollection.rawValue:
            let geometries = try keys.decode(
                [FailableDecodable<DecodedGeometry>].self,
                forKey: .geometries)
            geometry = GeometryCollection(geometries.compactMap(\.value).map(\.geometry))
            knownKeys = ["type", "geometries", "bbox"]

        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unsupported GeoJSON geometry type \(type)"))
        }

        let foreignMembers = try GeoJsonForeignMembers.decode(
            from: decoder,
            excluding: knownKeys)

        var result = geometry
        result.boundingBox = boundingBox
        result.foreignMembers = foreignMembers

        self.geometry = result
        self.boundingBox = boundingBox
        self.foreignMembers = foreignMembers
    }

}

// MARK: - Feature

private struct DecodedFeature: Decodable {

    let feature: Feature

    init(from decoder: Decoder) throws {
        let keys = try decoder.container(keyedBy: GeoJsonKey.self)

        guard keys.contains(.geometry) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Feature is missing the geometry member"))
        }

        let geometry = try keys.decodeIfPresent(DecodedGeometry.self, forKey: .geometry)
        let properties = try keys.decodeIfPresent([String: JSONValue].self, forKey: .properties)
        let id = try keys.decodeIfPresent(JSONValue.self, forKey: .id)
        let boundingBox = try keys.decodeIfPresent(DecodedBoundingBox.self, forKey: .bbox)
            .flatMap { BoundingBox(json: $0.values) }

        let foreignMembers = try GeoJsonForeignMembers.decode(
            from: decoder,
            excluding: ["type", "geometry", "properties", "id", "bbox"])

        let sendableProperties = properties?.mapValues { $0.asSendable } ?? [:]
        let identifier = Feature.Identifier(value: id?.asSendable)

        let feature: Feature
        if let geometry {
            feature = Feature(
                geometry.geometry,
                id: identifier,
                properties: sendableProperties,
                calculateBoundingBox: boundingBox != nil)
        }
        else {
            feature = Feature(
                id: identifier,
                properties: sendableProperties,
                foreignMembers: foreignMembers)
        }

        var result = feature
        result.boundingBox = boundingBox
        result.foreignMembers.merge(foreignMembers) { current, _ in current }
        self.feature = result
    }

}

// MARK: - FeatureCollection

private struct DecodedFeatureCollection: Decodable {

    let collection: FeatureCollection

    init(from decoder: Decoder) throws {
        let keys = try decoder.container(keyedBy: GeoJsonKey.self)
        let features = try keys.decode(
            [FailableDecodable<DecodedFeature>].self,
            forKey: .features)
        let boundingBox = try keys.decodeIfPresent(DecodedBoundingBox.self, forKey: .bbox)
            .flatMap { BoundingBox(json: $0.values) }
        let foreignMembers = try GeoJsonForeignMembers.decode(
            from: decoder,
            excluding: ["type", "features", "bbox"])

        var collection = FeatureCollection(features.compactMap(\.value).map(\.feature))
        collection.boundingBox = boundingBox
        collection.foreignMembers = foreignMembers
        self.collection = collection
    }

}

// MARK: - Type-erased entry

private enum DecodedGeoJson: Decodable {

    case geometry(DecodedGeometry)
    case feature(DecodedFeature)
    case featureCollection(DecodedFeatureCollection)

    init(from decoder: Decoder) throws {
        let keys = try decoder.container(keyedBy: GeoJsonKey.self)
        let type = try keys.decode(String.self, forKey: .type)

        switch type {
        case GeoJsonType.feature.rawValue:
            self = .feature(try DecodedFeature(from: decoder))

        case GeoJsonType.featureCollection.rawValue:
            self = .featureCollection(try DecodedFeatureCollection(from: decoder))

        default:
            self = .geometry(try DecodedGeometry(from: decoder))
        }
    }

    var asGeoJson: GeoJson {
        switch self {
        case let .geometry(geometry): geometry.geometry
        case let .feature(feature): feature.feature
        case let .featureCollection(collection): collection.collection
        }
    }

}
