import Foundation

public enum GeoJsonType: String {
    case invalid
    case point              = "Point"
    case multiPoint         = "MultiPoint"
    case lineString         = "LineString"
    case multiLineString    = "MultiLineString"
    case polygon            = "Polygon"
    case multiPolygon       = "MultiPolygon"
    case geometryCollection = "GeometryCollection"
    case feature            = "Feature"
    case featureCollection  = "FeatureCollection"
}

// MARK: - GeoJSON objects

public protocol GeoJson: GeoJsonConvertible, BoundingBoxRepresentable, CustomDebugStringConvertible {

    /// GeoJSON object type
    var type: GeoJsonType { get }

    /// Any foreign members
    var foreignMembers: [String: Any] { get set }

    /// Initialize a GeoJSON object from any object that looks like valid JSON
    init?(json: Any?, calculateBoundingBox: Bool)

    /// Type erased equality check
    func isEqualTo(_ other: GeoJson) -> Bool

}

extension GeoJson where Self: Equatable {

    public func isEqualTo(_ other: GeoJson) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }

}

extension GeoJson {

    public var debugDescription: String {
        let json = self.asJson()

        if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
            let string = String(data: data, encoding: String.Encoding.utf8)
        {
            return string
        }

        return String(describing: json)
    }

}

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

public protocol BoundingBoxRepresentable {

    /// The object's bounding box
    var boundingBox: BoundingBox? { get set }

    /// Calculates and returns the object's bounding box
    func calculateBoundingBox() -> BoundingBox?

    /// Calculates the object's bounding box and updates the property
    @discardableResult
    mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool) -> BoundingBox?

    /// Check if the object is inside or crosses the given bounding box
    func intersects(_ otherBoundingBox: BoundingBox) -> Bool

}

extension BoundingBoxRepresentable {

    @discardableResult
    public mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool = true) -> BoundingBox? {
        if boundingBox != nil && ifNecessary { return nil }
        boundingBox = calculateBoundingBox()
        return boundingBox
    }

}

// MARK: - GeoJsonGeometry

// GeoJSON geometry objects: Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon
public protocol GeoJsonGeometry: GeoJson {

    /// Check if the geometry is valid, i.e. it has enough coordinates to make sense.
    ///
    /// TODO: Would this be a null geometry?
    var hasValidCoordinates: Bool { get }

}

// MARK: - Point, MultiPoint

public protocol PointGeometry: GeoJsonGeometry {

    var points: [Point] { get }

}

// MARK: - LineString, MultiLineString

public protocol LineStringGeometry: GeoJsonGeometry {

    var lineStrings: [LineString] { get }

    var firstCoordinate: Coordinate3D? { get }

    var lastCoordinate: Coordinate3D? { get }

}

// MARK: - Polygon, MultiPolygon

public protocol PolygonGeometry: GeoJsonGeometry {

    var polygons: [Polygon] { get }

    func contains(
        _ coordinate: Coordinate3D,
        ignoreBoundary: Bool)
        -> Bool

    func contains(
        _ point: Point,
        ignoreBoundary: Bool)
        -> Bool

}

// MARK: - Object creators

extension GeoJson {

    /// Try to create an object from a JSON object
    public static func tryCreate<V: GeoJsonConvertible>(json: Any?) -> V? {
        if let json = json {
            return V(json: json)
        }
        return nil
    }

    /// Try to create an array of objects from a JSON object
    public static func tryCreate<V: GeoJsonConvertible>(json: Any?) -> [V]? {
        if let array = json as? [Any] {
            return array.compactMap { V(json: $0) }
        }
        return nil
    }

    /// Try to create an array of arrays of objects from a JSON object
    static func tryCreate<V: GeoJsonConvertible>(json: Any?) -> [[V]]? {
        if let array = json as? [Any] {
            return array.compactMap { tryCreate(json: $0) }
        }
        return nil
    }

    /// Try to create an array of arrays of arrays of objects from a JSON object
    static func tryCreate<V: GeoJsonConvertible>(json: Any?) -> [[[V]]]? {
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
