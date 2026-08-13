import Foundation

/// A generic helper for creating GeoJSON objects from various datasources.
public enum GeoJsonReader {

    /// Try to initialize a GeoJSON object from any Swift object.
    ///
    /// - Parameters:
    ///    - json: A GeoJSON-compatible Swift object
    /// - Returns: A GeoJson object, or `nil` if parsing failed
    /// - important: The source is expected to be in EPSG:4326.
    public static func geoJsonFrom(json: Any?) -> GeoJson? {
        // Need a concrete type...
        FeatureCollection.tryCreate(json: json)
    }

    /// Try to initialize a GeoJSON object from a file.
    ///
    /// - Parameters:
    ///    - url: The URL of the file to read
    /// - Returns: A GeoJson object, or `nil` if parsing failed
    /// - important: The source is expected to be in EPSG:4326.
    public static func geoJsonFrom(contentsOf url: URL) -> GeoJson? {
        geoJsonFrom(json: try? Data(contentsOf: url))
    }

    /// Try to initialize a GeoJSON object from a data object.
    ///
    /// - Parameters:
    ///    - jsonData: The JSON data
    /// - Returns: A GeoJson object, or `nil` if parsing failed
    /// - important: The source is expected to be in EPSG:4326.
    public static func geoJsonFrom(jsonData: Data) -> GeoJson? {
        geoJsonFrom(json: try? JSONSerialization.jsonObject(with: jsonData))
    }

    /// Try to initialize a GeoJSON object from a string.
    ///
    /// - Parameters:
    ///    - jsonString: The JSON string
    /// - Returns: A GeoJson object, or `nil` if parsing failed
    /// - important: The source is expected to be in EPSG:4326.
    public static func geoJsonFrom(jsonString: String) -> GeoJson? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data)
        else { return nil }
        return geoJsonFrom(json: json)
    }

    // MARK: - Geometry auto-detection

    /// Try to initialize a geometry from a string, auto-detecting the format.
    ///
    /// The following formats are recognized, in order:
    /// 1. GeoJSON (a JSON object with a `type` field).
    /// 2. WKT, with or without an `SRID=…;` prefix.
    /// 3. Hex-encoded WKB, EWKB, or TWKB.
    ///
    /// - Parameters:
    ///    - string: The geometry string to parse.
    ///    - targetProjection: The projection to decode into (default `.epsg4326`).
    /// - Returns: A geometry, or `nil` if the string could not be parsed.
    public static func geometryFrom(
        string: String,
        targetProjection: Projection = .epsg4326
    ) -> GeoJsonGeometry? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // GeoJSON.
        if trimmed.hasPrefix("{") {
            return Feature.tryCreateGeometry(json: try? JSONSerialization.jsonObject(with: Data(trimmed.utf8)))
        }

        // WKT.
        if isWKT(trimmed) {
            let sourceProjection: Projection? = trimmed.hasPrefix("SRID=") ? nil : .epsg4326
            return try? WKTCoder.decode(wkt: trimmed, sourceProjection: sourceProjection, targetProjection: targetProjection)
        }

        // Hex-encoded WKB/EWKB/TWKB.
        if let data = Data(hex: trimmed) {
            return geometryFrom(data: data, targetProjection: targetProjection)
        }

        return nil
    }

    /// Try to initialize a geometry from data, auto-detecting the format.
    ///
    /// The following formats are recognized, in order:
    /// 1. GeoJSON (a JSON object with a `type` field).
    /// 2. WKB/EWKB.
    /// 3. TWKB.
    ///
    /// When a WKB or TWKB payload carries no embedded SRID, it is assumed to
    /// be in EPSG:4326.
    ///
    /// - Parameters:
    ///    - data: The geometry data to parse.
    ///    - targetProjection: The projection to decode into (default `.epsg4326`).
    /// - Returns: A geometry, or `nil` if the data could not be parsed.
    public static func geometryFrom(
        data: Data,
        targetProjection: Projection = .epsg4326
    ) -> GeoJsonGeometry? {
        guard !data.isEmpty else { return nil }

        // GeoJSON.
        if let json = try? JSONSerialization.jsonObject(with: data),
           let geometry = Feature.tryCreateGeometry(json: json)
        {
            return geometry
        }

        // WKB/EWKB.
        if let geometry = try? WKBCoder.decode(wkb: data, sourceProjection: nil, targetProjection: targetProjection) {
            return geometry
        }
        if let geometry = try? WKBCoder.decode(wkb: data, sourceProjection: .epsg4326, targetProjection: targetProjection) {
            return geometry
        }

        // TWKB.
        if let geometry = try? TWKBCoder.decode(twkb: data, sourceProjection: nil, targetProjection: targetProjection) {
            return geometry
        }
        if let geometry = try? TWKBCoder.decode(twkb: data, sourceProjection: .epsg4326, targetProjection: targetProjection) {
            return geometry
        }

        return nil
    }

    /// Whether a string looks like WKT.
    private static func isWKT(_ string: String) -> Bool {
        let upper = string.uppercased()
        let keywords = [
            "POINT", "LINESTRING", "POLYGON", "MULTIPOINT",
            "MULTILINESTRING", "MULTIPOLYGON", "GEOMETRYCOLLECTION",
            "TRIANGLE", "CIRCULARSTRING", "COMPOUNDCURVE", "CURVEPOLYGON",
            "MULTICURVE", "MULTISURFACE", "POLYHEDRALSURFACE", "TIN",
        ]
        return upper.hasPrefix("SRID=") || keywords.contains(where: { upper.hasPrefix($0) })
    }

}
