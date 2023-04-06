#if !os(Linux)
import CoreLocation
#endif
@testable import GISTools
import XCTest

// MARK: - LineChunkTests

final class LineChunkTests: XCTestCase {

    private let lineString = LineString([
        Coordinate3D(latitude: 40.250184183819854, longitude: -86.28524780273438),
        Coordinate3D(latitude: 40.17887331434696, longitude: -85.98587036132812),
        Coordinate3D(latitude: 40.08857859823707, longitude: -85.97213745117188),
        Coordinate3D(latitude: 40.15578608609647, longitude: -85.77987670898438),
    ])!

    func testLineChunkShort() {
        let segmentLength: CLLocationDistance = GISTool.convert(length: 5.0, from: .miles, to: .meters)!

        let chunks = lineString.chunked(segmentLength: segmentLength).lineStrings
        XCTAssertEqual(chunks.count, 7)

        let some = chunks[3]
        XCTAssertEqual(some.coordinates.count, 3)
        XCTAssertEqual(some.coordinates[0].latitude, 40.18557, accuracy: 0.000001)
        XCTAssertEqual(some.coordinates[0].longitude, -86.013822, accuracy: 0.000001)

        XCTAssertEqual(some.coordinates[1].latitude, 40.178873, accuracy: 0.000001)
        XCTAssertEqual(some.coordinates[1].longitude, -85.98587, accuracy: 0.000001)

        XCTAssertEqual(some.coordinates[2].latitude, 40.129223, accuracy: 0.000001)
        XCTAssertEqual(some.coordinates[2].longitude, -85.978314, accuracy: 0.000001)
    }

    func testLineChunkLong() {
        let segmentLength: CLLocationDistance = GISTool.convert(length: 50.0, from: .miles, to: .meters)!

        let chunks = lineString.chunked(segmentLength: segmentLength).lineStrings
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0], lineString)
    }

}
