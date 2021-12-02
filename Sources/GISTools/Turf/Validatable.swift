#if !os(Linux)
import CoreLocation
#endif
import Foundation

// (Partly) ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-valid

public protocol ValidatableGeoJson {

    /// Check if the geometry is valid, i.e. it has enough coordinates to make sense.
    ///
    /// TODO: Would this be a null geometry?
    var isValid: Bool { get }

}

// MARK: - Geometries etc.

extension Feature {

    public var isValid: Bool {
        geometry.isValid
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .feature)
    }

}

extension FeatureCollection {

    public var isValid: Bool {
        features.isEmpty || features.allSatisfy({ $0.isValid })
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .featureCollection)
    }

}

extension GeometryCollection {

    public var isValid: Bool {
        geometries.isEmpty || geometries.allSatisfy({ $0.isValid })
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .geometryCollection)
    }

}

extension LineString {

    public var isValid: Bool {
         coordinates.count >= 2
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .lineString)
    }

}

extension MultiLineString {

    public var isValid: Bool {
        !coordinates.isEmpty
            && coordinates[0].count >= 2
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .multiLineString)
    }

}

extension Point {

    public var isValid: Bool {
        true
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .point)
    }

}

extension MultiPoint {

    public var isValid: Bool {
        !coordinates.isEmpty
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .multiPoint)
    }

}

extension Polygon {

    public var isValid: Bool {
        !coordinates.isEmpty
        && coordinates[0].count >= 3
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .polygon)
    }

}

extension MultiPolygon {

    public var isValid: Bool {
        !coordinates.isEmpty
        && !coordinates[0].isEmpty
        && coordinates[0][0].count >= 3
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        checkIsValid(geoJson: geoJson, ofType: .multiPolygon)
    }

}

// MARK: - GeoJSON

extension GeoJson {

    // Sanity checks

    // TODO:
    public static func checkIsValid(
        geoJson: [String: Any],
        ofType expectedType: GeoJsonType? = nil)
        -> Bool
    {
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
