#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class FlattenTests: XCTestCase {

    func testFeatureCollection() {
        let original = TestData.featureCollection(package: "Flatten", name: "FeatureCollection")
        let flattened = original.flattened()!
        let expected = TestData.featureCollection(package: "Flatten", name: "FeatureCollectionResult")

        XCTAssertEqual(flattened, expected)
    }

    func testGeometryCollection() {
        let original = TestData.geometryCollection(package: "Flatten", name: "GeometryCollection")
        let flattened = original.flattened()!
        let expected = TestData.featureCollection(package: "Flatten", name: "GeometryCollectionResult")

        XCTAssertEqual(flattened, expected)
    }

    func testGeometryObject() {
        let original = TestData.multiPolygon(package: "Flatten", name: "GeometryObject")
        let flattened = original.flattened()!
        let expected = TestData.featureCollection(package: "Flatten", name: "GeometryObjectResult")

        XCTAssertEqual(flattened, expected)
    }

    func testMultiLineString() {
        let original = TestData.feature(package: "Flatten", name: "MultiLineString")
        let flattened = original.flattened()!
        let expected = TestData.featureCollection(package: "Flatten", name: "MultiLineStringResult")

        XCTAssertEqual(flattened, expected)
    }

    func testMultiPoint() {
        let original = TestData.feature(package: "Flatten", name: "MultiPoint")
        let flattened = original.flattened()!
        let expected = TestData.featureCollection(package: "Flatten", name: "MultiPointResult")

        XCTAssertEqual(flattened, expected)
    }

    func testPolygon() {
        let original = TestData.feature(package: "Flatten", name: "Polygon")
        let flattened = original.flattened()!
        let expected = TestData.featureCollection(package: "Flatten", name: "PolygonResult")

        XCTAssertEqual(flattened, expected)
    }

    static var allTests = [
        ("testFeatureCollection", testFeatureCollection),
        ("testGeometryCollection", testGeometryCollection),
        ("testGeometryObject", testGeometryObject),
        ("testMultiLineString", testMultiLineString),
        ("testMultiPoint", testMultiPoint),
        ("testPolygon", testPolygon),
    ]

}
