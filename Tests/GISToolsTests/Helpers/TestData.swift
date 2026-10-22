import Foundation
@testable import GISTools

struct TestData {

    static func featureCollection(package: String, name: String) throws -> FeatureCollection {
        try FeatureCollection(jsonData: dataFromFile(package: package, name: name))!
    }

    static func feature(package: String, name: String) throws -> Feature {
        try Feature(jsonData: dataFromFile(package: package, name: name))!
    }

    static func geometryCollection(package: String, name: String) throws -> GeometryCollection {
        try GeometryCollection(jsonData: dataFromFile(package: package, name: name))!
    }

    static func point(package: String, name: String) throws -> Point {
        try Point(jsonData: dataFromFile(package: package, name: name))!
    }

    static func multiPoint(package: String, name: String) throws -> MultiPoint {
        try MultiPoint(jsonData: dataFromFile(package: package, name: name))!
    }

    static func lineString(package: String, name: String) throws -> LineString {
        try LineString(jsonData: dataFromFile(package: package, name: name))!
    }

    static func multiLineString(package: String, name: String) throws -> MultiLineString {
        try MultiLineString(jsonData: dataFromFile(package: package, name: name))!
    }

    static func polygon(package: String, name: String) throws -> Polygon {
        try Polygon(jsonData: dataFromFile(package: package, name: name))!
    }

    static func multiPolygon(package: String, name: String) throws -> MultiPolygon {
        try MultiPolygon(jsonData: dataFromFile(package: package, name: name))!
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
        let data = try dataFromFile(package: package, name: name)
        guard let string = String(data: data, encoding: .utf8) else {
            throw TestDataError.invalidUTF8
        }
        return string
    }

    static func dataFromFile(package: String, name: String) throws -> Data {
        let base = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestData")
            .appendingPathComponent(package)
            .appendingPathComponent(name)

        let gzipped = base
            .appendingPathExtension("geojson")
            .appendingPathExtension("gz")
        let plain = base.appendingPathExtension("geojson")
        let path = FileManager.default.fileExists(atPath: gzipped.path)
            ? gzipped
            : plain

        let compressed = try Data(contentsOf: path)
        guard let data = Gzip.decompressIfNeeded(compressed) else {
            throw TestDataError.invalidGzip
        }
        return data
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
    case invalidUTF8
    case invalidGzip
}
