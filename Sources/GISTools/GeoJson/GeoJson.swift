import Foundation

/// All permitted GeoJSON types.
public enum GeoJsonType: String, Sendable {
    /// Marks an invalid object
    case invalid
    /// A GeoJSON Point object
    case point              = "Point"
    /// A GeoJSON MultiPoint object
    case multiPoint         = "MultiPoint"
    /// A GeoJSON LineString object
    case lineString         = "LineString"
    /// A GeoJSON MultiLineString object
    case multiLineString    = "MultiLineString"
    /// A GeoJSON Polygon
    case polygon            = "Polygon"
    /// A GeoJSON MultiPolygon
    case multiPolygon       = "MultiPolygon"
    /// A GeoJSON GeometryCollection
    case geometryCollection = "GeometryCollection"
    /// A GeoJSON Feature
    case feature            = "Feature"
    /// A GeoJSON FeatureCollection
    case featureCollection  = "FeatureCollection"
}

// MARK: - GeoJSON objects

/// The base protocol that all GeoJSON objects conform to.
public protocol GeoJson:
    BoundingBoxRepresentable,
    GeoJsonConvertible,
    Projectable,
    ValidatableGeoJson,
    Codable,
    CustomDebugStringConvertible,
    Sendable
{

    /// GeoJSON object type.
    var type: GeoJsonType { get }

    /// All of the receiver's coordinates.
    var allCoordinates: [Coordinate3D] { get }

    /// Any foreign members, i.e. keys in the JSON that are
    /// not part of the GeoJSON standard.
    /// - important: `values` must be a valid JSON objects or serialization will fail.
    var foreignMembers: [String: Sendable] { get set }

    /// Try to initialize a GeoJSON object from any JSON and calculate a bounding box if necessary.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    init?(json: Any?, calculateBoundingBox: Bool)

    /// Type erased equality check.
    func isEqualTo(_ other: GeoJson) -> Bool

}

extension GeoJson where Self: Equatable {

    /// Type erased equality check.
    public func isEqualTo(_ other: GeoJson) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }

}

extension GeoJson {

    /// The receiver as a pretty printed JSON string representation.
    ///
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    public var debugDescription: String {
        let json = self.asJson

        if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
            let string = String(data: data, encoding: String.Encoding.utf8)
        {
            return string
        }

        return String(describing: json)
    }

}

// https://datatracker.ietf.org/doc/html/rfc7946
extension GeoJson {

    /// Any foreign member by key.
    public func foreignMember<T: Sendable>(for key: String) -> T? {
        foreignMembers[key] as? T
    }

    /// Set a foreign member key/value pair.
    ///
    /// - important: `value` must be a valid JSON object or serialization will fail.
    public mutating func setForeignMember(_ value: Sendable?, for key: String) {
        var updatedProperties = foreignMembers
        updatedProperties[key] = value
        foreignMembers = updatedProperties
    }

    /// Remove a foreign member from the receiver.
    @discardableResult
    public mutating func removeForeignMember(for key: String) -> Sendable? {
        var updatedProperties = foreignMembers
        let previous = updatedProperties.removeValue(forKey: key)
        foreignMembers = updatedProperties
        return previous
    }

    /// Any foreign member by subscript.
    public subscript<T: Sendable>(foreignMember key: String) -> T? {
        get {
            return foreignMember(for: key)
        }
        set {
            setForeignMember(newValue, for: key)
        }
    }

}

// MARK: - Typed foreign members

extension GeoJson {

    /// Decode the receiver's foreign members into a `Decodable` type.
    ///
    /// The values are converted to ``JSONValue`` (normalizing numbers along
    /// the way), encoded to JSON, and decoded with the given decoder — meaning
    /// `JSONDecoder` strategies (`dateDecodingStrategy`,
    /// `keyDecodingStrategy`, …) apply and real `DecodingError`s are thrown
    /// instead of failing silently.
    ///
    /// - Parameters:
    ///    - type: The type to decode into
    ///    - decoder: The decoder to use (default `JSONDecoder()`)
    /// - Returns: The decoded value
    /// - Throws: A `DecodingError` if the foreign members cannot be decoded
    ///           into the given type, or if a value is not JSON-compatible
    public func foreignMembers<T: Decodable>(
        as type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        try JSONValue.decode(foreignMembers, as: type, decoder: decoder)
    }

    /// Returns a foreign member as ``JSONValue``, e.g. for exhaustive pattern matching.
    ///
    /// - Parameter key: The foreign member key
    /// - Returns: The foreign member value, or `nil` if the key doesn't exist
    ///            or the value is not JSON-compatible
    public func jsonForeignMember(for key: String) -> JSONValue? {
        JSONValue(value: foreignMembers[key])
    }

    /// The receiver's foreign members as a `[String: JSONValue]` dictionary.
    ///
    /// Values are converted directly (no JSON round-trip), normalizing numbers
    /// along the way, so a member stored as `3.0` becomes `.int(3)`.
    ///
    /// - Returns: The foreign members as JSON values
    /// - Throws: A `DecodingError` if a foreign member value is not
    ///           JSON-compatible
    public func jsonForeignMembers() throws -> [String: JSONValue] {
        try JSONValue.jsonDictionary(from: foreignMembers)
    }

    /// Returns a foreign member coerced to `Int`.
    ///
    /// Numbers are converted when they can be represented exactly, so a
    /// member written as `3.0` returns `3`.
    ///
    /// - Parameter key: The foreign member key
    /// - Returns: The foreign member value, or `nil` if the key doesn't exist
    ///            or the value is not exactly representable as an integer
    public func intForeignMember(for key: String) -> Int? {
        JsonCoercion.int(foreignMembers[key])
    }

    /// Returns a foreign member coerced to `Double`.
    ///
    /// - Parameter key: The foreign member key
    /// - Returns: The foreign member value, or `nil` if the key doesn't exist
    ///            or the value is not a number
    public func doubleForeignMember(for key: String) -> Double? {
        JsonCoercion.double(foreignMembers[key])
    }

    /// Returns a foreign member coerced to `Bool`.
    ///
    /// - Parameter key: The foreign member key
    /// - Returns: The foreign member value, or `nil` if the key doesn't exist
    ///            or the value is not a boolean
    public func boolForeignMember(for key: String) -> Bool? {
        JsonCoercion.bool(foreignMembers[key])
    }

    /// Returns a foreign member coerced to `String`.
    ///
    /// - Parameter key: The foreign member key
    /// - Returns: The foreign member value, or `nil` if the key doesn't exist
    ///            or the value is not a string
    public func stringForeignMember(for key: String) -> String? {
        JsonCoercion.string(foreignMembers[key])
    }

}

// MARK: - EmptyCreatable

/// GeoJSON objects that can be created empty, which might lead to
/// invalid objects.
public protocol EmptyCreatable {

    /// Create an empty and possibly invalid object.
    init()

}

// MARK: - GeoJsonGeometry

/// GeoJSON geometry objects: `Point`, `MultiPoint`, `LineString`, `MultiLineString`,
/// `Polygon`, `MultiPolygon`, `GeometryCollection`.
public protocol GeoJsonGeometry: GeoJson {}

// MARK: - Point, MultiPoint

/// Point geometry objects: `Point` and `MultiPoint`.
public protocol PointGeometry: GeoJsonGeometry {

    /// The receiver's coordinates converted to `Point`s.
    var points: [Point] { get }

}

// MARK: - LineString, MultiLineString

/// Linestring geometry objects: `LineString` and `MultiLineString`.
public protocol LineStringGeometry: GeoJsonGeometry {

    /// The receiver's coordinates converted to `LineString`s.
    var lineStrings: [LineString] { get }

    /// The first coordinate of the `LineString(s)`.
    var firstCoordinate: Coordinate3D? { get }

    /// The last coordinate of the `LineString(s)`.
    var lastCoordinate: Coordinate3D? { get }

}

// MARK: - Polygon, MultiPolygon

/// Polygon geometry objects: `Polygon` and `MultiPolygon`.
public protocol PolygonGeometry: GeoJsonGeometry {

    /// The receiver's coordinates converted to `Polygon`s.
    var polygons: [Polygon] { get }

    /// Check if this `(Multi)Polygon` contains *Coordinate3D*.
    ///
    /// - Parameters:
    ///    - coordinate: The coordinate to test
    ///    - ignoringBoundary: If `true`, points on the boundary are not considered inside
    ///    - gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the coordinate lies within the polygon
    func contains(
        _ coordinate: Coordinate3D,
        ignoringBoundary: Bool,
        gridSize: Double?
    ) -> Bool

    /// Check if this `(Multi)Polygon` contains *Point*.
    ///
    /// - Parameters:
    ///    - point: The point to test
    ///    - ignoringBoundary: If `true`, points on the boundary are not considered inside
    ///    - gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the point lies within the polygon
    func contains(
        _ point: Point,
        ignoringBoundary: Bool,
        gridSize: Double?
    ) -> Bool

}

// MARK: - Object creators

extension GeoJson {

    /// Try to create an object from any JSON object.
    public static func tryCreate<V: GeoJsonReadable>(json: Any?) -> V? {
        if let json = json {
            return V(json: json)
        }
        return nil
    }

    /// Try to create an array of objects from any JSON object.
    public static func tryCreate<V: GeoJsonReadable>(json: Any?) -> [V]? {
        if let array = JsonCoercion.array(json) {
            return array.compactMap { V(json: $0) }
        }
        return nil
    }

    /// Try to create an array of arrays of objects from any JSON object.
    static func tryCreate<V: GeoJsonReadable>(json: Any?) -> [[V]]? {
        if let array = JsonCoercion.array(json) {
            return array.compactMap { tryCreate(json: $0) }
        }
        return nil
    }

    /// Try to create an array of arrays of arrays of objects from any JSON object.
    static func tryCreate<V: GeoJsonReadable>(json: Any?) -> [[[V]]]? {
        if let array = JsonCoercion.array(json) {
            return array.compactMap { tryCreate(json: $0) }
        }
        return nil
    }

    /// Try to create a GeoJSON object from any JSON object.
    public static func tryCreate(json: Any?) -> GeoJson? {
        if let geoJson = JsonCoercion.dictionary(json),
           let typeString = geoJson["type"] as? String,
           let type = GeoJsonType(rawValue: typeString),
           type != .invalid
        {
            switch type {
            case .point: return Point(json: geoJson)
            case .multiPoint: return MultiPoint(json: geoJson)
            case .lineString: return LineString(json: geoJson)
            case .multiLineString: return MultiLineString(json: geoJson)
            case .polygon: return Polygon(json: geoJson)
            case .multiPolygon: return MultiPolygon(json: geoJson)
            case .geometryCollection: return GeometryCollection(json: geoJson)
            case .feature: return Feature(json: geoJson)
            case .featureCollection: return FeatureCollection(geoJson: geoJson)
            default: return nil
            }
        }
        return nil
    }

    /// Try to create a GeoJSON geometry from any JSON object.
    public static func tryCreateGeometry(json: Any?) -> GeoJsonGeometry? {
        if let geoJson = JsonCoercion.dictionary(json),
           let typeString = geoJson["type"] as? String,
           let type = GeoJsonType(rawValue: typeString),
           type != .invalid
        {
            switch type {
            case .point: return Point(json: geoJson)
            case .multiPoint: return MultiPoint(json: geoJson)
            case .lineString: return LineString(json: geoJson)
            case .multiLineString: return MultiLineString(json: geoJson)
            case .polygon: return Polygon(json: geoJson)
            case .multiPolygon: return MultiPolygon(json: geoJson)
            case .geometryCollection: return GeometryCollection(json: geoJson)
            default: return nil
            }
        }
        return nil
    }

    /// Try to create an array of GeoJSON geometries from any JSON object.
    public static func tryCreate(json: Any?) -> [GeoJsonGeometry]? {
        if let array = JsonCoercion.array(json) {
            return array.compactMap { tryCreateGeometry(json: $0) }
        }
        return nil
    }

    /// Try to create a feature from any JSON object.
    public static func tryCreateFeature(json: Any?) -> Feature? {
        if let geometry = tryCreateGeometry(json: json) {
            return Feature(geometry)
        }
        return Feature(json: json)
    }

}
