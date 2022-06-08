import Foundation

/// A GeoJSON `Feature`.
public struct Feature: GeoJson {

    public var type: GeoJsonType {
        return .feature
    }

    /// An arbitrary identifier.
    public var id: String?

    /// The `Feature`s geometry object.
    public let geometry: GeoJsonGeometry

    public var allCoordinates: [Coordinate3D] {
        geometry.allCoordinates
    }

    /// Only 'Feature' objects may have properties.
    public var properties: [String: Any]

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    /// Create a ``Feature`` from any ``GeoJsonGeometry`` object.
    public init(
        _ geometry: GeoJsonGeometry,
        properties: [String: Any] = [:],
        calculateBoundingBox: Bool = false)
    {
        self.geometry = geometry
        self.properties = properties

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Any],
              Feature.isValid(geoJson: geoJson),
              let geometry: GeoJsonGeometry = Feature.tryCreateGeometry(json: geoJson["geometry"])
        else { return nil }

        self.geometry = geometry
        self.properties = (geoJson["properties"] as? [String: Any]) ?? [:]
        self.boundingBox = Feature.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox, self.boundingBox == nil {
            self.boundingBox = self.calculateBoundingBox()
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

    public var asJson: [String: Any] {
        var result: [String: Any] = [
            "type": GeoJsonType.feature.rawValue,
            "properties": properties,
            "geometry": geometry.asJson
        ]
        if let id = id {
            result["id"] = id
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

    public func calculateBoundingBox() -> BoundingBox? {
        return geometry.boundingBox ?? geometry.calculateBoundingBox()
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox, !boundingBox.intersects(otherBoundingBox) {
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
        return lhs.geometry.isEqualTo(rhs.geometry)
            && lhs.id == rhs.id
            && lhs.properties.keys == rhs.properties.keys
        // TODO
//            && lhs.properties == rhs.properties
    }

}

// MARK: - Properties

extension Feature {

    /// Returns a property by key.
    public func property<T>(for key: String) -> T? {
        return properties[key] as? T
    }

    /// Set a property key/value pair.
    public mutating func setProperty(_ value: Any?, for key: String) {
        var updatedProperties = properties
        updatedProperties[key] = value
        properties = updatedProperties
    }

    /// Remove a property from the Feature.
    @discardableResult
    public mutating func removeProperty(for key: String) -> Any? {
        var updatedProperties = properties
        let previous = updatedProperties.removeValue(forKey: key)
        properties = updatedProperties
        return previous
    }

    /// Returns a property by key.
    public subscript<T>(key: String) -> T? {
        get {
            return property(for: key)
        }
        set {
            setProperty(newValue, for: key)
        }
    }

}
