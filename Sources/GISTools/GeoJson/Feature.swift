import Foundation

/// A GeoJSON `Feature`.
public struct Feature:
    GeoJson,
    Identifiable
{

    /// A GeoJSON identifier that can either be a string or number.
    ///
    /// Any parsed integer value `Int64.min ⪬ i ⪬ Int64.max`  will be cast to `Int`
    /// (or `Int64` on 32-bit platforms), values above `Int64.max` will be cast to `UInt`
    /// (or `UInt64` on 32-bit platforms).
    public enum Identifier: Equatable, Hashable, CustomStringConvertible, Sendable {

#if _pointerBitWidth(_32)
        public typealias IntId = Int64
        public typealias UIntId = UInt64
#else
        public typealias IntId = Int
        public typealias UIntId = UInt
#endif

        case string(String)
        case int(IntId)
        case uint(UIntId)
        case double(Double)

        /// Note: This will prefer `Int` over `UInt` if possible.
        public init?(value: Any?) {
            guard let value else { return nil }

            switch value {
            case let binaryInt as (any BinaryInteger):
                if let int = IntId(exactly: binaryInt) {
                    self = .int(int)
                }
                else if let uint = UIntId(exactly: binaryInt) {
                    self = .uint(uint)
                }
                else {
                    return nil
                }

            case let int as IntId:
                self = .int(int)

            case let uint as UIntId:
                self = .uint(uint)

            case let string as String:
                self = .string(string)

            case let double as Double:
                self = .double(double)

            default:
                return nil
            }
        }

        public var asJson: Sendable {
            switch self {
            case .double(let double): double
            case .int(let int): int
            case .uint(let uint): uint
            case .string(let string): string
            }
        }

        public var description: String {
            switch self {
            case .double(let double): String(double)
            case .int(let int): String(int)
            case .uint(let uint): String(uint)
            case .string(let string): string
            }
        }
    }

    public var type: GeoJsonType {
        .feature
    }

    public var projection: Projection {
        geometry.projection
    }

    /// An arbitrary identifier.
    public var id: Identifier?

    /// The `Feature`s geometry object.
    public private(set) var geometry: GeoJsonGeometry

    public var allCoordinates: [Coordinate3D] {
        geometry.allCoordinates
    }

    /// Only 'Feature' objects may have properties.
    public var properties: [String: Sendable]

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Sendable] = [:]

    /// Create a ``Feature`` from any ``GeoJsonGeometry`` object.
    public init(
        _ geometry: GeoJsonGeometry,
        id: Identifier? = nil,
        properties: [String: Sendable] = [:],
        calculateBoundingBox: Bool = false)
    {
        self.geometry = geometry
        self.id = id
        self.properties = properties

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Sendable],
              Feature.isValid(geoJson: geoJson),
              let geometry: GeoJsonGeometry = Feature.tryCreateGeometry(json: geoJson["geometry"])
        else { return nil }

        self.geometry = geometry
        self.id = Identifier(value: geoJson["id"])
        self.properties = (geoJson["properties"] as? [String: Sendable]) ?? [:]
        self.boundingBox = Feature.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox {
            self.updateBoundingBox()
        }

        if geoJson.count > 3 {
            var foreignMembers = geoJson
            foreignMembers.removeValue(forKey: "type")
            foreignMembers.removeValue(forKey: "geometry")
            foreignMembers.removeValue(forKey: "properties")
            foreignMembers.removeValue(forKey: "bbox")
            self.foreignMembers = foreignMembers
        }
    }

    public var asJson: [String: Sendable] {
        var result: [String: Sendable] = [
            "type": GeoJsonType.feature.rawValue,
            "properties": properties,
            "geometry": geometry.asJson
        ]
        if let id {
            result["id"] = id.asJson
        }
        if let boundingBox = boundingBox {
            result["bbox"] = boundingBox.asJson
        }
        result.merge(foreignMembers) { (current, new) in
            return current
        }
        return result
    }

}

extension Feature {

    @discardableResult
    public mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool = true) -> BoundingBox? {
        geometry.updateBoundingBox(onlyIfNecessary: ifNecessary)

        if boundingBox != nil && ifNecessary { return boundingBox }

        boundingBox = calculateBoundingBox()
        return boundingBox
    }

    public func calculateBoundingBox() -> BoundingBox? {
        geometry.boundingBox ?? geometry.calculateBoundingBox()
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox ?? calculateBoundingBox(),
            !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }

        return geometry.intersects(otherBoundingBox)
    }

}

extension Feature: Equatable {

    public static func ==(
        lhs: Feature,
        rhs: Feature)
        -> Bool
    {
        return lhs.projection == rhs.projection
            && lhs.geometry.isEqualTo(rhs.geometry)
            && lhs.id == rhs.id
            && lhs.properties.keys == rhs.properties.keys
        // TODO
//            && lhs.properties == rhs.properties
    }

}

// MARK: - Projection

extension Feature {

    public func projected(to newProjection: Projection) -> Feature {
        guard newProjection != projection else { return self }

        var feature = Feature(
            geometry.projected(to: newProjection),
            id: id,
            properties: properties,
            calculateBoundingBox: (boundingBox != nil))
        feature.foreignMembers = foreignMembers
        return feature
    }

}

// MARK: - Properties

extension Feature {

    /// Returns a property by key.
    public func property<T: Sendable>(for key: String) -> T? {
        properties[key] as? T
    }

    /// Set a property key/value pair.
    ///
    /// - important: `value` must be a valid JSON object or serialization will fail.
    public mutating func setProperty(_ value: Sendable?, for key: String) {
        var updatedProperties = properties
        updatedProperties[key] = value
        properties = updatedProperties
    }

    /// Remove a property from the Feature.
    @discardableResult
    public mutating func removeProperty(for key: String) -> Sendable? {
        var updatedProperties = properties
        let previous = updatedProperties.removeValue(forKey: key)
        properties = updatedProperties
        return previous
    }

    /// Returns a property by key.
    public subscript<T: Sendable>(key: String) -> T? {
        get {
            return property(for: key)
        }
        set {
            setProperty(newValue, for: key)
        }
    }

}
