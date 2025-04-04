#if !os(Linux)
import CoreLocation
#endif
@testable import GISTools
import XCTest

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

    func testEvenlyDivided() {
        let a = Coordinate3D.zero
        let b = a.destination(distance: 100.0, bearing: 90.0)
        let line = LineString(unchecked: [a, b])
        let dividedLine = line.evenlyDivided(segmentLength: 1.0)

        XCTAssertEqual(line.allCoordinates.count, 2)
        XCTAssertEqual(dividedLine.allCoordinates.count, 101)

        for (first, second, index) in dividedLine.allCoordinates.overlappingPairs() {
            guard let second else { break }
            XCTAssertEqual(index, 0)
            XCTAssertEqual(first.distance(from: second), 1.0, accuracy: 0.0001)
        }
    }

}
