#if !os(Linux)
import CoreLocation
#endif
@testable import GISTools
import XCTest

final class FrechetDistanceTests: XCTestCase {

    func testFrechetDistance4326() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let lineArc1 = try XCTUnwrap(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        let lineArc2 = try XCTUnwrap(point.lineArc(radius: 6000.0, bearing1: 20.0, bearing2: 60.0))

        let distanceHaversine = lineArc1.frechetDistance(from: lineArc2, distanceFunction: .haversine)
        let distanceRhumbLine = lineArc1.frechetDistance(from: lineArc2, distanceFunction: .rhumbLine)

        XCTAssertEqual(distanceHaversine, 1000.0, accuracy: 0.0001)
        XCTAssertEqual(distanceRhumbLine, 1000.0, accuracy: 0.0001)
    }

    func testFrechetDistance3857() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0)).projected(to: .epsg3857)
        let lineArc1 = try XCTUnwrap(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        let lineArc2 = try XCTUnwrap(point.lineArc(radius: 6000.0, bearing1: 20.0, bearing2: 60.0))

        let distanceEucliden = lineArc1.frechetDistance(from: lineArc2, distanceFunction: .euclidean)
        XCTAssertEqual(distanceEucliden, 1000.0, accuracy: 2.0)
    }

}
