#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// (Partly) ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-valid

/// Objects that can be validated, i.e. check that they are non-empty.
public protocol ValidatableGeoJson {

    /// Check if the geometry is valid, i.e. it has enough coordinates to make sense.
    ///
    /// TODO: Would this be a null geometry?
    var isValid: Bool { get }

}

// MARK: - Geometries etc.

extension Feature: ValidatableGeoJson {

    /// Check if the Feature's geometry is valid, i.e. it has enough coordinates to make sense.
    public var isValid: Bool {
        geometry.isValid
    }

    /// Check if the GeoJson is a valid Feature.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .feature)
    }

}

extension FeatureCollection: ValidatableGeoJson {

    /// Check if the FeatureCollection's Feature is valid, i.e. it has enough coordinates to make sense.
    public var isValid: Bool {
        features.isEmpty || features.allSatisfy({ $0.isValid })
    }

    /// Check if the GeoJson is a valid FeatureCollection.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .featureCollection)
    }

}

extension GeometryCollection: ValidatableGeoJson {

    /// Check if the geometries are valid, i.e. they have enough coordinates to make sense.
    public var isValid: Bool {
        geometries.isEmpty || geometries.allSatisfy({ $0.isValid })
    }

    /// Check if the GeoJson is a valid GeometryCollection.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .geometryCollection)
    }

}

extension LineString: ValidatableGeoJson {

    /// Check if the LineString is valid, i.e. it has enough coordinates to make sense.
    public var isValid: Bool {
         coordinates.count >= 2
    }

    /// Check if the GeoJson has a valid LineString geometry.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .lineString)
    }

}

extension MultiLineString: ValidatableGeoJson {

    /// Check if the MultiLineString is valid, i.e. it has enough coordinates to make sense.
    public var isValid: Bool {
        !coordinates.isEmpty
            && coordinates[0].count >= 2
    }

    /// Check if the GeoJson has a valid MultiLineString geometry.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .multiLineString)
    }

}

extension Point: ValidatableGeoJson {

    /// Check if the Point is valid. Always `true`.
    public var isValid: Bool {
        true
    }

    /// Check if the GeoJson is a valid Point.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .point)
    }

}

extension MultiPoint: ValidatableGeoJson {

    /// Check if the MultiPoint is valid, i.e. it has enough coordinates to make sense.
    public var isValid: Bool {
        !coordinates.isEmpty
    }

    /// Check if the GeoJson has a valid MultiPoint geometry.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .multiPoint)
    }

}

extension Polygon: ValidatableGeoJson {

    /// Check if the Polygon is valid, i.e. it has enough coordinates to make sense.
    public var isValid: Bool {
        !coordinates.isEmpty
            && coordinates[0].count >= 3
    }

    /// Check if the GeoJson has a valid Polygon geometry.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .polygon)
    }

}

extension MultiPolygon: ValidatableGeoJson {

    /// Check if the MultiPolygon is valid, i.e. it has enough coordinates to make sense.
    public var isValid: Bool {
        !coordinates.isEmpty
            && !coordinates[0].isEmpty
            && coordinates[0][0].count >= 3
    }

    /// Check if the GeoJson has a valid MultiPolygon geometry.
    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .multiPolygon)
    }

}

// MARK: - GeoJSON

extension GeoJson {

    /// Check if the GeoJson dictionary has a valid structure for the given type.
    ///
    /// - Parameters:
    ///   - geoJson: A dictionary representing a GeoJSON object.
    ///   - expectedType: The expected ``GeoJsonType`` of the object (optional).
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
            guard let coordinates = geoJson["coordinates"] as? [Any],
                  !coordinates.isEmpty
            else { return false }
            return true

        case .lineString, .multiLineString, .multiPoint, .multiPolygon, .polygon:
            return geoJson["coordinates"] != nil

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
