@testable import GISTools
import XCTest

final class TruncateTests: XCTestCase {

    func testPoint() {
        let point = Point(
            Coordinate3D(latitude: 123.456789, longitude: 123.456789, altitude: 123.456789),
            calculateBoundingBox: true)

        let truncated = point.truncated(precision: 2, removeAltitude: true)
        XCTAssertEqual(truncated.coordinate.latitude, 123.46)
        XCTAssertEqual(truncated.coordinate.longitude, 123.46)
        XCTAssertNil(truncated.coordinate.altitude)
        XCTAssertNotNil(truncated.boundingBox)
    }

    func testMultiPoint() {
        let multiPoint = MultiPoint(
            [
                Coordinate3D(latitude: 123.456789, longitude: 123.456789, altitude: 123.456789),
                Coordinate3D(latitude: 9.1234567, longitude: 9.1234567),
            ],
            calculateBoundingBox: true)!

        let truncated = multiPoint.truncated(precision: 2, removeAltitude: true)
        XCTAssertEqual(truncated.coordinates[0].latitude, 123.46)
        XCTAssertEqual(truncated.coordinates[0].longitude, 123.46)
        XCTAssertNil(truncated.coordinates[0].altitude)
        XCTAssertEqual(truncated.coordinates[1].latitude, 9.12)
        XCTAssertEqual(truncated.coordinates[1].longitude, 9.12)
        XCTAssertNil(truncated.coordinates[1].altitude)
        XCTAssertNotNil(truncated.boundingBox)
    }

    func testLineString() {
        let lineString = LineString(
            [
                Coordinate3D(latitude: 123.456789, longitude: 123.456789, altitude: 123.456789),
                Coordinate3D(latitude: 9.1234567, longitude: 9.1234567),
            ],
            calculateBoundingBox: true)!

        let truncated = lineString.truncated(precision: 2, removeAltitude: true)
        XCTAssertEqual(truncated.coordinates[0].latitude, 123.46)
        XCTAssertEqual(truncated.coordinates[0].longitude, 123.46)
        XCTAssertNil(truncated.coordinates[0].altitude)
        XCTAssertEqual(truncated.coordinates[1].latitude, 9.12)
        XCTAssertEqual(truncated.coordinates[1].longitude, 9.12)
        XCTAssertNil(truncated.coordinates[1].altitude)
        XCTAssertNotNil(truncated.boundingBox)
    }

    func testMultiLineString() {
        let multiLineString = MultiLineString(
            [
                [
                    Coordinate3D(latitude: 123.456789, longitude: 123.456789, altitude: 123.456789),
                    Coordinate3D(latitude: 1.0, longitude: 101.0, altitude: 100.0),
                ],
                [
                    Coordinate3D(latitude: 9.1234567, longitude: 9.1234567),
                    Coordinate3D(latitude: 3.0, longitude: 103.0),
                ],
            ],
            calculateBoundingBox: true)!

        let truncated = multiLineString.truncated(precision: 2, removeAltitude: true)
        XCTAssertEqual(truncated.coordinates[0][0].latitude, 123.46)
        XCTAssertEqual(truncated.coordinates[0][0].longitude, 123.46)
        XCTAssertNil(truncated.coordinates[0][0].altitude)
        XCTAssertEqual(truncated.coordinates[0][1].latitude, 1.0)
        XCTAssertEqual(truncated.coordinates[0][1].longitude, 101.0)
        XCTAssertNil(truncated.coordinates[0][1].altitude)
        XCTAssertEqual(truncated.coordinates[1][0].latitude, 9.12)
        XCTAssertEqual(truncated.coordinates[1][0].longitude, 9.12)
        XCTAssertNil(truncated.coordinates[1][0].altitude)
        XCTAssertNotNil(truncated.boundingBox)
    }

    func testPolygon() {
        // TODO:
    }

    func testMultiPolygon() {
        // TODO:
    }

    func testGeometryCollection() {
        // TODO:
    }

    func testFeature() {
        // TODO:
    }

    func testFeatureCollection() {
        // TODO:
    }

    static var allTests = [
        ("testPoint", testPoint),
        ("testMultiPoint", testMultiPoint),
        ("testLineString", testLineString),
        ("testMultiLineString", testMultiLineString),
        ("testPolygon", testPolygon),
        ("testMultiPolygon", testMultiPolygon),
        ("testGeometryCollection", testGeometryCollection),
        ("testFeature", testFeature),
        ("testFeatureCollection", testFeatureCollection),
    ]

}
