@testable import GISTools
import XCTest

final class BoundingBoxClipTests: XCTestCase {

    func testLineStringSingleLine() {
        let lineString = TestData.lineString(package: "BoundingBoxClip", name: "SingleLine")
        let boundingBox = BoundingBox(southWest: Coordinate3D(latitude: 39.095962936305476, longitude: -77.72552490234374), northEast: Coordinate3D(latitude: 39.59722324495565, longitude: -77.0361328125))
        let expected = MultiLineString([TestData.lineString(package: "BoundingBoxClip", name: "SingleLineResult")])

        let clipped = lineString.clipped(to: boundingBox)

        XCTAssertEqual(clipped, expected)
    }

    func testLineString() {
        let lineString = TestData.lineString(package: "BoundingBoxClip", name: "LineString")
        let boundingBox = BoundingBox(southWest: Coordinate3D(latitude: 36.29741818650811, longitude: -81.551513671875), northEast: Coordinate3D(latitude: 39.58875727696545, longitude: -76.475830078125))
        let expected = TestData.multiLineString(package: "BoundingBoxClip", name: "LineStringResult")

        let clipped = lineString.clipped(to: boundingBox)

        XCTAssertEqual(clipped, expected)
    }

    func testMultiLineString() {
        let lineString = TestData.multiLineString(package: "BoundingBoxClip", name: "MultiLineString")
        let boundingBox = BoundingBox(southWest: Coordinate3D(latitude: 38.49229419236133, longitude: -78.3929443359375), northEast: Coordinate3D(latitude: 39.56758783088905, longitude: -76.9097900390625))
        let expected = TestData.multiLineString(package: "BoundingBoxClip", name: "MultiLineStringResult")

        let clipped = lineString.clipped(to: boundingBox)

        XCTAssertEqual(clipped, expected)
    }

    func testMultiPolygon() {
        let multiPolygon = TestData.multiPolygon(package: "BoundingBoxClip", name: "MultiPolygon")
        let boundingBox = BoundingBox(southWest: Coordinate3D(latitude: 36.2354121683998, longitude: -80.1123046875), northEast: Coordinate3D(latitude: 41.22824901518529, longitude: -76.959228515625))
        let expected = TestData.multiPolygon(package: "BoundingBoxClip", name: "MultiPolygonResult")

        let clipped = multiPolygon.clipped(to: boundingBox)

        XCTAssertEqual(clipped, expected)
    }

    func testPolygonCrossingHole() {
        let polygon = TestData.polygon(package: "BoundingBoxClip", name: "PolygonCrossingHole")
        let boundingBox = BoundingBox(southWest: Coordinate3D(latitude: 36.34167804918315, longitude: -79.12353515625), northEast: Coordinate3D(latitude: 39.027718840211605, longitude: -76.739501953125))
        let expected = TestData.polygon(package: "BoundingBoxClip", name: "PolygonCrossingHoleResult")

        let clipped = polygon.clipped(to: boundingBox)

        XCTAssertEqual(clipped, expected)
    }

    func testPolygonHoles() {
        let polygon = TestData.polygon(package: "BoundingBoxClip", name: "PolygonHoles")
        let boundingBox = BoundingBox(southWest: Coordinate3D(latitude: 36.38591277287651, longitude: -79.60693359375), northEast: Coordinate3D(latitude: 39.07890809706475, longitude: -76.717529296875))
        let expected = TestData.polygon(package: "BoundingBoxClip", name: "PolygonHolesResult")

        let clipped = polygon.clipped(to: boundingBox)

        XCTAssertEqual(clipped, expected)
    }

    func testPolygonPointIntersection() {
        let polygon = TestData.polygon(package: "BoundingBoxClip", name: "PolygonPointIntersection")
        let boundingBox = BoundingBox(southWest: Coordinate3D(latitude: -31.98, longitude: 115.875), northEast: Coordinate3D(latitude: -31.975, longitude: 115.880))

        let clipped = polygon.clipped(to: boundingBox)

        XCTAssertNil(clipped) // invalid
    }

}
