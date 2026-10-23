#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// (Partly) ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-valid

/// Objects that can be checked for structural and topological validity.
public protocol ValidatableGeoJson {

    /// Check if the geometry has enough coordinates to make structural sense.
    ///
    /// This is a structural check only. For OGC/PostGIS topology validity,
    /// use ``isValid``.
    ///
    /// - Note: RFC 7946 §3.2 allows a Feature with `"geometry": null`. Such an
    ///   unlocated feature is considered structurally valid; its other members
    ///   are still validated.
    var isStructurallyValid: Bool { get }

    /// Check if the geometry is topologically valid according to OGC rules.
    var isValid: Bool { get }

    /// A human-readable reason why ``isValid`` is `false`, or `nil` when valid.
    var isValidReason: String? { get }

    /// Whether the geometry is simple (no self-intersections).
    var isSimple: Bool { get }

    /// Returns `self` when ``isValid`` is `true`, otherwise `nil`.
    var validated: Self? { get }

}

extension ValidatableGeoJson {

    public var validated: Self? {
        isValid ? self : nil
    }

}

// MARK: - Geometries etc.

extension Feature: ValidatableGeoJson {

    /// Check if the Feature's geometry is structurally valid.
    ///
    /// An unlocated feature (`geometry == nil`) is structurally valid.
    public var isStructurallyValid: Bool {
        geometry?.isStructurallyValid ?? true
    }

    /// Check if the GeoJson is a valid Feature.
    ///
    /// - Returns: `true` if the GeoJson is valid.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .feature)
    }

}

extension FeatureCollection: ValidatableGeoJson {

    /// Check if every Feature is structurally valid.
    public var isStructurallyValid: Bool {
        features.isEmpty || features.allSatisfy({ $0.isStructurallyValid })
    }

    /// Check if the GeoJson is a valid FeatureCollection.
    ///
    /// - Returns: `true` if the GeoJson is valid.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .featureCollection)
    }

}

extension GeometryCollection: ValidatableGeoJson {

    /// Check if every geometry is structurally valid.
    public var isStructurallyValid: Bool {
        geometries.isEmpty || geometries.allSatisfy({ $0.isStructurallyValid })
    }

    /// Check if the GeoJson is a valid GeometryCollection.
    ///
    /// - Returns: `true` if the GeoJson is valid.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .geometryCollection)
    }

}

extension LineString: ValidatableGeoJson {

    /// Check if the LineString has enough coordinates to make structural sense.
    public var isStructurallyValid: Bool {
        coordinates.count >= 2
    }

    /// Check if the GeoJson has a valid LineString geometry.
    ///
    /// - Returns: `true` if the GeoJson is valid.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .lineString)
    }

}

extension MultiLineString: ValidatableGeoJson {

    /// Check if the MultiLineString has enough coordinates to make structural sense.
    public var isStructurallyValid: Bool {
        !coordinates.isEmpty
            && coordinates.allSatisfy { $0.count >= 2 }
    }

    /// Check if the GeoJson has a valid MultiLineString geometry.
    ///
    /// - Returns: `true` if the GeoJson is valid.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .multiLineString)
    }

}

extension Point: ValidatableGeoJson {

    /// Check if the Point is structurally valid. Always `true`.
    public var isStructurallyValid: Bool {
        true
    }

    /// Check if the GeoJson is a valid Point.
    ///
    /// - Returns: `true` if the GeoJson is valid.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .point)
    }

}

extension MultiPoint: ValidatableGeoJson {

    /// Check if the MultiPoint has enough coordinates to make structural sense.
    public var isStructurallyValid: Bool {
        !coordinates.isEmpty
    }

    /// Check if the GeoJson has a valid MultiPoint geometry.
    ///
    /// - Returns: `true` if the GeoJson is valid.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .multiPoint)
    }

}

extension Polygon: ValidatableGeoJson {

    /// Check if the Polygon has enough coordinates to make structural sense.
    public var isStructurallyValid: Bool {
        !coordinates.isEmpty
            && coordinates.allSatisfy { $0.count >= 3 }
    }

    /// Check if the GeoJson has a valid Polygon geometry.
    ///
    /// - Returns: `true` if the GeoJson is valid.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .polygon)
    }

}

extension MultiPolygon: ValidatableGeoJson {

    /// Check if the MultiPolygon has enough coordinates to make structural sense.
    public var isStructurallyValid: Bool {
        !coordinates.isEmpty
            && coordinates.allSatisfy { polygon in
                !polygon.isEmpty && polygon.allSatisfy { $0.count >= 3 }
            }
    }

    /// Check if the GeoJson has a valid MultiPolygon geometry.
    ///
    /// - Returns: `true` if the GeoJson is valid.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .multiPolygon)
    }

}

// MARK: - GeoJSON

extension GeoJson {

    /// Check if the GeoJson dictionary has a valid structure for the given type.
    ///
    /// - Parameters:
    /// - Parameter geoJson: A dictionary representing a GeoJSON object.
    /// - Parameter expectedType: The expected ``GeoJsonType`` of the object (optional).
    /// - Returns: `true` if the dictionary has the required keys for the given type.
    public static func checkIsValid(
        geoJson: [String: Any],
        ofType expectedType: GeoJsonType? = nil
    ) -> Bool {
        guard !geoJson.isEmpty,
              let geometryType = geoJson["type"] as? String,
              let type = GeoJsonType(rawValue: geometryType)
        else { return false }

        if let expectedType = expectedType,
           expectedType != type
        {
            return false
        }

        switch type {
        case .point:
            guard let coordinates = JsonCoercion.array(geoJson["coordinates"]) else {
                return false
            }

            return coordinates.count >= 2

        case .lineString:
            guard let coordinates = JsonCoercion.array(geoJson["coordinates"]) else {
                return false
            }

            return coordinates.count >= 2

        case .multiPoint:
            guard let coordinates = JsonCoercion.array(geoJson["coordinates"]) else {
                return false
            }

            return coordinates.isNotEmpty

        case .multiLineString:
            guard let lines = JsonCoercion.array(geoJson["coordinates"]) else {
                return false
            }

            return lines.isNotEmpty && lines.allSatisfy { line in
                guard let positions = JsonCoercion.array(line) else { return false }

                return positions.count >= 2
            }

        case .polygon:
            guard let rings = JsonCoercion.array(geoJson["coordinates"]),
                  let outer = rings.first,
                  let positions = JsonCoercion.array(outer)
            else { return false }

            return positions.count >= 3

        case .multiPolygon:
            guard let polygons = JsonCoercion.array(geoJson["coordinates"]) else {
                return false
            }

            return polygons.isNotEmpty && polygons.allSatisfy { polygon in
                guard let rings = JsonCoercion.array(polygon),
                      let outer = rings.first,
                      let positions = JsonCoercion.array(outer)
                else { return false }

                return positions.count >= 3
            }

        case .geometryCollection:
            return geoJson["geometries"] != nil

        case .feature:
            return geoJson["geometry"] != nil

        case .featureCollection:
            return geoJson["features"] != nil

        case .invalid:
            return false
        }
    }

}
