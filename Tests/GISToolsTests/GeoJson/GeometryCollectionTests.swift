#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class GeometryCollectionTests: XCTestCase {

    private let geometryCollectionJson = """
        {
            "type": "GeometryCollection",
            "geometries": [{
                "type": "Point",
                "coordinates": [100.0, 0.0]
            }, {
                "type": "LineString",
                "coordinates": [
                    [101.0, 0.0],
                    [102.0, 1.0]
                ]
            }],
            "other": "something else"
        }
        """

    func testLoadJson() throws {
        guard let geometryCollection = GeometryCollection(jsonString: geometryCollectionJson) else {
            throw "geometryCollection is nil"
        }
        XCTAssertNotNil(geometryCollection)
        XCTAssertEqual(geometryCollection.type, GeoJsonType.geometryCollection)
        XCTAssertEqual(geometryCollection.geometries.count, 2)
        XCTAssertEqual(geometryCollection.foreignMember(for: "other"), "something else")
        XCTAssertEqual(geometryCollection[foreignMember: "other"], "something else")
    }

    func testCreateJson() {
        // TODO
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
    ]

}
