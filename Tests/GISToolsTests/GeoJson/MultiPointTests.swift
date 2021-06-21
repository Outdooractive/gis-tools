#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class MultiPointTests: XCTestCase {

    private let multiPointJson = """
        {
            "type": "MultiPoint",
            "coordinates": [
                [100.0, 0.0],
                [101.0, 1.0]
            ]
        }
        """

    func testLoadJson() {
        let multiPoint = MultiPoint(jsonString: multiPointJson)
        XCTAssertNotNil(multiPoint)
        XCTAssertEqual(multiPoint?.type, GeoJsonType.multiPoint)
        XCTAssertEqual(multiPoint?.coordinates, [Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)])
    }

    func testCreateJson() {
        let multiPoint = MultiPoint([Coordinate3D(latitude: 0.0, longitude: 100.0), Coordinate3D(latitude: 1.0, longitude: 101.0)])

        let string = multiPoint.asJsonString()!
        XCTAssert(string.contains("\"type\":\"MultiPoint\""))
        XCTAssert(string.contains("\"coordinates\":[[100,0],[101,1]]"))
    }

    static var allTests = [
        ("testLoadJson", testLoadJson),
        ("testCreateJson", testCreateJson),
    ]

}
