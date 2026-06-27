import Foundation
import GISTools
import struct GISTools.Polygon

struct TestData {

    static func featureCollection(package: String, name: String) throws -> FeatureCollection {
        try FeatureCollection(jsonString: stringFromFile(package: package, name: name))!
    }

    static func feature(package: String, name: String) throws -> Feature {
        try Feature(jsonString: stringFromFile(package: package, name: name))!
    }

    static func geometryCollection(package: String, name: String) throws -> GeometryCollection {
        try GeometryCollection(jsonString: stringFromFile(package: package, name: name))!
    }

    static func point(package: String, name: String) throws -> Point {
        try Point(jsonString: stringFromFile(package: package, name: name))!
    }

    static func multiPoint(package: String, name: String) throws -> MultiPoint {
        try MultiPoint(jsonString: stringFromFile(package: package, name: name))!
    }

    static func lineString(package: String, name: String) throws -> LineString {
        try LineString(jsonString: stringFromFile(package: package, name: name))!
    }

    static func multiLineString(package: String, name: String) throws -> MultiLineString {
        try MultiLineString(jsonString: stringFromFile(package: package, name: name))!
    }

    static func polygon(package: String, name: String) throws -> Polygon {
        try Polygon(jsonString: stringFromFile(package: package, name: name))!
    }

    static func multiPolygon(package: String, name: String) throws -> MultiPolygon {
        try MultiPolygon(jsonString: stringFromFile(package: package, name: name))!
    }

    static func boundingBox(package: String, name: String) throws -> BoundingBox {
        let data = try dataFromFile(package: package, name: name)
        let json = try JSONSerialization.jsonObject(with: data)
        guard let dict = json as? [String: [String: Double]],
              let sw = dict["southWest"], let ne = dict["northEast"],
              let swLat = sw["lat"], let swLon = sw["lon"],
              let neLat = ne["lat"], let neLon = ne["lon"]
        else { throw TestDataError.invalidBoundingBox }

        return BoundingBox(
            southWest: Coordinate3D(latitude: swLat, longitude: swLon),
            northEast: Coordinate3D(latitude: neLat, longitude: neLon))
    }

    // MARK: -

    static func stringFromFile(package: String, name: String) throws -> String {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestData")
            .appendingPathComponent(package)
            .appendingPathComponent(name)
            .appendingPathExtension("geojson")

        return try String(contentsOf: path, encoding: .utf8)
    }

    static func dataFromFile(package: String, name: String) throws -> Data {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestData")
            .appendingPathComponent(package)
            .appendingPathComponent(name)
            .appendingPathExtension("geojson")

        return try Data(contentsOf: path)
    }

    static func shapefileUrl(package: String, name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestData")
            .appendingPathComponent(package)
            .appendingPathComponent(name)
    }

}

enum TestDataError: Error {
    case invalidBoundingBox
}
