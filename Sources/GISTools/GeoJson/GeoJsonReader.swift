import Foundation

/// A generic helper for creating GeoJSON objects from various datasources.
public enum GeoJsonReader {

    /// Try to initialize a GeoJSON object from any Swift object.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public static func geoJsonFrom(json: Any?) -> GeoJson? {
        // Need a concrete type...
        FeatureCollection.tryCreate(json: json)
    }

    /// Try to initialize a GeoJSON object from a file.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public static func geoJsonFrom(contentsOf url: URL) -> GeoJson? {
        geoJsonFrom(json: try? Data(contentsOf: url))
    }

    /// Try to initialize a GeoJSON object from a data object.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public static func geoJsonFrom(jsonData: Data) -> GeoJson? {
        geoJsonFrom(json: try? JSONSerialization.jsonObject(with: jsonData))
    }

    /// Try to initialize a GeoJSON object from a string.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public static func geoJsonFrom(jsonString: String) -> GeoJson? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data)
        else { return nil }
        return geoJsonFrom(json: json)
    }

}
