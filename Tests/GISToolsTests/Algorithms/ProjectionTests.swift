@testable import GISTools
import XCTest

final class ProjectionTests: XCTestCase {

    func testConvertTo3857() {
        // A simple case
        let coordinate1 = Coordinate3D(latitude: 41.0, longitude: -71.0)
        let result1 = coordinate1.projected(to: .epsg3857)
        XCTAssertEqual(result1.longitude, -7_903_683.846322424, accuracy: 0.000001)
        XCTAssertEqual(result1.latitude, 5_012_341.663847514, accuracy: 0.000001)

        let coordinate1b = Coordinate3D(latitude: 35.522895, longitude: -97.552175)
        let result1b = coordinate1b.projected(to: .epsg3857)
        XCTAssertEqual(result1b.longitude, -10_859_458.446776, accuracy: 0.000001)
        XCTAssertEqual(result1b.latitude, 4_235_169.496066, accuracy: 0.000001)

        // A coordinate that passed the 180th meridian
        let coordinate2 = Coordinate3D(latitude: -23.563987128451217, longitude: -246.796875)
        let result2 = coordinate2.projected(to: .epsg3857)
        XCTAssertEqual(result2.longitude, -27_473_302.454371188, accuracy: 0.000001)
        XCTAssertEqual(result2.latitude, -2_700_367.3352587065, accuracy: 0.000001)

        // A coordinate that passed the 180th meridian
        let coordinate3 = Coordinate3D(latitude: -23.563987128451217, longitude: -246.796875)
        let result3 = coordinate3.normalized().projected(to: .epsg3857)
        XCTAssertEqual(result3.longitude, 12_601_714.231207296, accuracy: 0.000001)
        XCTAssertEqual(result3.latitude, -2_700_367.3352587065, accuracy: 0.000001)

        // Another coordinate that passed the 180th meridian
        let coordinate4 = Coordinate3D(latitude: 11.350796722383672, longitude: 286.5234375)
        let result4 = coordinate4.projected(to: .epsg3857)
        XCTAssertEqual(result4.longitude, 31_895_643.162838347, accuracy: 0.000001)
        XCTAssertEqual(result4.latitude, 1_271_912.1506653326, accuracy: 0.000001)

        // Another coordinate that passed the 180th meridian
        let coordinate5 = Coordinate3D(latitude: 11.350796722383672, longitude: 286.5234375)
        let result5 = coordinate5.normalized().projected(to: .epsg3857)
        XCTAssertEqual(result5.longitude, -8_179_373.522740141, accuracy: 0.000001)
        XCTAssertEqual(result5.latitude, 1_271_912.1506653326, accuracy: 0.000001)
    }

    func testConvertTo4326() {
        // A simple case
        let coordinate1 = Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514)
        let result1 = coordinate1.projected(to: .epsg4326)
        XCTAssertEqual(result1.latitude, 41.0, accuracy: 0.000001)
        XCTAssertEqual(result1.longitude, -71.0, accuracy: 0.000001)

        let coordinate1b = Coordinate3D(x: -10_859_458.446776, y: 4_235_169.496066)
        let result1b = coordinate1b.projected(to: .epsg4326)
        XCTAssertEqual(result1b.latitude, 35.522895, accuracy: 0.000001)
        XCTAssertEqual(result1b.longitude, -97.552175, accuracy: 0.000001)

        // A coordinate that passed the 180th meridian
        let coordinate2 = Coordinate3D(x: 12_601_714.231207296, y: -2_700_367.3352587065)
        let result2 = coordinate2.projected(to: .epsg4326)
        XCTAssertEqual(result2.latitude, -23.563987128451217, accuracy: 0.000001)
        XCTAssertEqual(result2.longitude, 113.203125, accuracy: 0.000001)

        // Another coordinate that passed the 180th meridian
        let coordinate3 = Coordinate3D(x: -8_179_373.522740139, y: 1_271_912.1506653326)
        let result3 = coordinate3.projected(to: .epsg4326)
        XCTAssertEqual(result3.latitude, 11.350796722383672, accuracy: 0.000001)
        XCTAssertEqual(result3.longitude, -73.476562, accuracy: 0.000001)
    }

}
