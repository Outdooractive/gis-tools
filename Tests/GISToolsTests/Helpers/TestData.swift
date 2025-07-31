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

}
