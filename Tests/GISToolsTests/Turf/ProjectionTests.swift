@testable import GISTools
import XCTest

final class ProjectionTests: XCTestCase {

    func testConvertTo3857() {
        // A simple case
        let coordinate1 = Coordinate3D(latitude: 41.0, longitude: -71.0)
        let result1 = coordinate1.projectedToEpsg3857

        XCTAssertEqual(result1.x, -7_903_683.846322424, accuracy: 0.000001)
        XCTAssertEqual(result1.y, 5_012_341.663847514, accuracy: 0.000001)

        // A coordinate that passed the 180th meridian
        let coordinate2 = Coordinate3D(latitude: -23.563987128451217, longitude: -246.796875)
        let result2 = coordinate2.projectedToEpsg3857

        XCTAssertEqual(result2.x, 12_601_714.231207296, accuracy: 0.000001)
        XCTAssertEqual(result2.y, -2_700_367.3352587065, accuracy: 0.000001)

        // Another coordinate that passed the 180th meridian
        let coordinate3 = Coordinate3D(latitude: 11.350796722383672, longitude: 286.5234375)
        let result3 = coordinate3.projectedToEpsg3857

        XCTAssertEqual(result3.x, -8_179_373.522740139, accuracy: 0.000001)
        XCTAssertEqual(result3.y, 1_271_912.1506653326, accuracy: 0.000001)
    }

    func testConvertTo4326() {
        // A simple case
        let coordinate1 = CoordinateXY(x: -7_903_683.846322424, y: 5_012_341.663847514)
        let result1 = coordinate1.projectedToEpsg4326

        XCTAssertEqual(result1.latitude, 41.0, accuracy: 0.000001)
        XCTAssertEqual(result1.longitude, -71.0, accuracy: 0.000001)

        // A coordinate that passed the 180th meridian
        let coordinate2 = CoordinateXY(x: 12_601_714.231207296, y: -2_700_367.3352587065)
        let result2 = coordinate2.projectedToEpsg4326

        XCTAssertEqual(result2.latitude, -23.563987128451217, accuracy: 0.000001)
        XCTAssertEqual(result2.longitude, 113.203125, accuracy: 0.000001)

        // Another coordinate that passed the 180th meridian
        let coordinate3 = CoordinateXY(x: -8_179_373.522740139, y: 1_271_912.1506653326)
        let result3 = coordinate3.projectedToEpsg4326

        XCTAssertEqual(result3.latitude, 11.350796722383672, accuracy: 0.000001)
        XCTAssertEqual(result3.longitude, -73.476562, accuracy: 0.000001)
    }

    static var allTests = [
        ("testConvertTo3857", testConvertTo3857),
        ("testConvertTo4326", testConvertTo4326),
    ]

}
