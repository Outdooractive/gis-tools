import Foundation

/// All permitted GeoJSON types.
public enum GeoJsonType: String {
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
    GeoJsonConvertible,
    BoundingBoxRepresentable,
    ValidatableGeoJson,
    CustomDebugStringConvertible
{

    /// GeoJSON object type
    var type: GeoJsonType { get }

    /// All coordinates in the object
    var allCoordinates: [Coordinate3D] { get }

    /// Any foreign members, i.e. keys in the JSON that are
    /// not part of the GeoJSON standard
    var foreignMembers: [String: Any] { get set }

    /// Try to initialize a GeoJSON object from any JSON
    init?(json: Any?, calculateBoundingBox: Bool)

    /// Type erased equality check
    func isEqualTo(_ other: GeoJson) -> Bool

}

extension GeoJson where Self: Equatable {

    /// Type erased equality check
    public func isEqualTo(_ other: GeoJson) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }

}

extension GeoJson {

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

    public func foreignMember<T>(for key: String) -> T? {
        return foreignMembers[key] as? T
    }

    public mutating func setForeignMember(_ value: Any?, for key: String) {
        var updatedProperties = foreignMembers
        updatedProperties[key] = value
        foreignMembers = updatedProperties
    }

    @discardableResult
    public mutating func removeForeignMember(for key: String) -> Any? {
        var updatedProperties = foreignMembers
        let previous = updatedProperties.removeValue(forKey: key)
        foreignMembers = updatedProperties
        return previous
    }

    public subscript<T>(foreignMember key: String) -> T? {
        get {
            return foreignMember(for: key)
        }
        set {
            setForeignMember(newValue, for: key)
        }
    }

}

// MARK: - BoundingBoxRepresentable

/// GeoJSON Objects that may have a bounding box.
public protocol BoundingBoxRepresentable {

    /// The object's bounding box
    var boundingBox: BoundingBox? { get set }

    /// Calculates and returns the object's bounding box
    func calculateBoundingBox() -> BoundingBox?

    /// Calculates the object's bounding box and updates the property
    @discardableResult
    mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool) -> BoundingBox?

    /// Check if the object is inside or crosses the other bounding box
    func intersects(_ otherBoundingBox: BoundingBox) -> Bool

}

extension BoundingBoxRepresentable {

    /// Calculates the object's bounding box and updates the property
    @discardableResult
    public mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool = true) -> BoundingBox? {
        if boundingBox != nil && ifNecessary { return nil }
        boundingBox = calculateBoundingBox()
        return boundingBox
    }

}

// MARK: - EmptyCreatable

/// GeoJSON objects that can be created empty, which might lead to
/// invalid objects.
public protocol EmptyCreatable {

    /// Create an empty and possibly invalid object
    init()

}

// MARK: - GeoJsonGeometry

/// GeoJSON geometry objects:
///     `Point`, `MultiPoint`, `LineString`,
///     `MultiLineString`, `Polygon`, `MultiPolygon`.
public protocol GeoJsonGeometry: GeoJson {}

// MARK: - Point, MultiPoint

/// Point geometry objects: `Point` and `MultiPoint`.
public protocol PointGeometry: GeoJsonGeometry {

    /// The object's coordinates converted to `Point`s
    var points: [Point] { get }

}

// MARK: - LineString, MultiLineString

/// Linestring geometry objects: `LineString` and `MultiLineString`.
public protocol LineStringGeometry: GeoJsonGeometry {

    /// The object's coordinates converted to `LineString`s
    var lineStrings: [LineString] { get }

    /// The first coordinate of the `LineString(s)`
    var firstCoordinate: Coordinate3D? { get }

    /// The last coordinate of the `LineString(s)`
    var lastCoordinate: Coordinate3D? { get }

}

// MARK: - Polygon, MultiPolygon

/// Polygon geometry objects: `Polygon` and `MultiPolygon`.
public protocol PolygonGeometry: GeoJsonGeometry {

    /// The object's coordinates converted to `Polygon`s
    var polygons: [Polygon] { get }

    /// Check if this `(Multi)Polygon` contains `coordinate`
    func contains(
        _ coordinate: Coordinate3D,
        ignoreBoundary: Bool)
        -> Bool

    /// Check if this `(Multi)Polygon` contains `point`
    func contains(
        _ point: Point,
        ignoreBoundary: Bool)
        -> Bool

}

// MARK: - Object creators

extension GeoJson {

    /// Try to create an object from a JSON object
    public static func tryCreate<V: GeoJsonReadable>(json: Any?) -> V? {
        if let json = json {
            return V(json: json)
        }
        return nil
    }

    /// Try to create an array of objects from a JSON object
    public static func tryCreate<V: GeoJsonReadable>(json: Any?) -> [V]? {
        if let array = json as? [Any] {
            return array.compactMap { V(json: $0) }
        }
        return nil
    }

    /// Try to create an array of arrays of objects from a JSON object
    static func tryCreate<V: GeoJsonReadable>(json: Any?) -> [[V]]? {
        if let array = json as? [Any] {
            return array.compactMap { tryCreate(json: $0) }
        }
        return nil
    }

    /// Try to create an array of arrays of arrays of objects from a JSON object
    static func tryCreate<V: GeoJsonReadable>(json: Any?) -> [[[V]]]? {
        if let array = json as? [Any] {
            return array.compactMap { tryCreate(json: $0) }
        }
        return nil
    }

    /// Try to create a GeoJSON object from a JSON object
    public static func tryCreate(json: Any?) -> GeoJson? {
        if let geoJson = json as? [String: Any],
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

    /// Try to create a GeoJSON geometry from a JSON object
    public static func tryCreateGeometry(json: Any?) -> GeoJsonGeometry? {
        if let geoJson = json as? [String: Any],
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

    /// Try to create an array of GeoJSON geometries from a JSON object
    public static func tryCreate(json: Any?) -> [GeoJsonGeometry]? {
        if let array = json as? [Any] {
            return array.compactMap { tryCreateGeometry(json: $0) }
        }
        return nil
    }

    /// Try to create a feature from a JSON object
    public static func tryCreateFeature(json: Any?) -> Feature? {
        if let geometry = tryCreateGeometry(json: json) {
            return Feature(geometry)
        }
        return Feature(json: json)
    }

}
