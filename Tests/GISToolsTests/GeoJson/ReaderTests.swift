@testable import GISTools
import XCTest

final class ReaderTests: XCTestCase {

    private let pointJson = """
    {
        "type": "Point",
        "coordinates": [100.0, 0.0],
        "other": "something else"
    }
    """

    func testLoadJson() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let someGeoJson = try XCTUnwrap(GeoJsonReader.geoJsonFrom(json: point.asJson))

        XCTAssertEqual(someGeoJson.type, .point)
        XCTAssertEqual(someGeoJson.projection, .epsg4326)

        let castedPoint = try XCTUnwrap(someGeoJson as? Point)

        XCTAssertEqual(castedPoint.asJsonString(prettyPrinted: true), point.asJsonString(prettyPrinted: true))
    }

    func testLoadString() throws {
        let someGeoJson = try XCTUnwrap(GeoJsonReader.geoJsonFrom(jsonString: pointJson))

        XCTAssertEqual(someGeoJson.type, .point)
        XCTAssertEqual(someGeoJson.projection, .epsg4326)

        let point = try XCTUnwrap(Point(jsonString: pointJson))
        let castedPoint = try XCTUnwrap(someGeoJson as? Point)

        XCTAssertEqual(castedPoint.asJsonString(prettyPrinted: true), point.asJsonString(prettyPrinted: true))
    }

}
