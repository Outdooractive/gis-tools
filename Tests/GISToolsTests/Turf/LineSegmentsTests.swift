@testable import GISTools
import XCTest

// MARK: LineSegmentsTests

final class LineSegmentsTests: XCTestCase {

    func testLineSegments() throws {
        let coordinates = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let lineSegments = [
            LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 0.0), second: Coordinate3D(latitude: 10.0, longitude: 0.0)),
            LineSegment(first: Coordinate3D(latitude: 10.0, longitude: 0.0), second: Coordinate3D(latitude: 10.0, longitude: 10.0)),
            LineSegment(first: Coordinate3D(latitude: 10.0, longitude: 10.0), second: Coordinate3D(latitude: 0.0, longitude: 10.0)),
            LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 10.0), second: Coordinate3D(latitude: 0.0, longitude: 0.0)),
        ]
        let lineString = try XCTUnwrap(LineString(coordinates))

        XCTAssertEqual(lineString.lineSegments, lineSegments)
    }

}
