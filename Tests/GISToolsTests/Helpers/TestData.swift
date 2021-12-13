import GISTools
import struct GISTools.Polygon
import XCTest

class TestData {

    class func featureCollection(package: String, name: String) -> FeatureCollection {
        return FeatureCollection(jsonString: stringFromFile(package: package, name: name))!
    }

    class func feature(package: String, name: String) -> Feature {
        return Feature(jsonString: stringFromFile(package: package, name: name))!
    }

    class func geometryCollection(package: String, name: String) -> GeometryCollection {
        return GeometryCollection(jsonString: stringFromFile(package: package, name: name))!
    }

    class func point(package: String, name: String) -> Point {
        return Point(jsonString: stringFromFile(package: package, name: name))!
    }

    class func multiPoint(package: String, name: String) -> MultiPoint {
        return MultiPoint(jsonString: stringFromFile(package: package, name: name))!
    }

    class func lineString(package: String, name: String) -> LineString {
        return LineString(jsonString: stringFromFile(package: package, name: name))!
    }

    class func multiLineString(package: String, name: String) -> MultiLineString {
        return MultiLineString(jsonString: stringFromFile(package: package, name: name))!
    }

    class func polygon(package: String, name: String) -> Polygon {
        return Polygon(jsonString: stringFromFile(package: package, name: name))!
    }

    class func multiPolygon(package: String, name: String) -> MultiPolygon {
        return MultiPolygon(jsonString: stringFromFile(package: package, name: name))!
    }

    // MARK: -

    class func stringFromFile(package: String, name: String) -> String {
        let path = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestData")
            .appendingPathComponent(package)
            .appendingPathComponent(name)
            .appendingPathExtension("geojson")

        do {
            if !(try path.checkResourceIsReachable()) {
                XCTAssert(false, "Test data for \(package)/\(name) not found.")
                return ""
            }
            return try String(contentsOf: path, encoding: .utf8)
        }
        catch {
            XCTAssert(false, "Unable to decode fixture at \(path): \(error).")
            return ""
        }
    }

    class func dataFromFile(package: String, name: String) -> Data {
        let path = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestData")
            .appendingPathComponent(package)
            .appendingPathComponent(name)
        .appendingPathExtension("geojson")

        do {
            if !(try path.checkResourceIsReachable()) {
                XCTAssert(false, "Test data for \(package)/\(name) not found.")
                return Data()
            }
            return try Data(contentsOf: path)
        }
        catch {
            XCTAssert(false, "Unable to decode fixture at \(path): \(error).")
            return Data()
        }
    }

}
