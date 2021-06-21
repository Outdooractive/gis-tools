#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class LineSliceAlongTests: XCTestCase {

    func testSlice() {
        let lineString = TestData.lineString(package: "LineSliceAlong", name: "LineSliceAlong")
        XCTAssertNotNil(lineString)

        let start: Double = GISTool.convert(length: 500.0, from: .miles, to: .meters)!
        let end: Double = GISTool.convert(length: 750.0, from: .miles, to: .meters)!

        let startCoordinate: Coordinate3D = lineString.coordinateAlong(distance: start)
        let endCoordinate: Coordinate3D = lineString.coordinateAlong(distance: end)

        let sliced = lineString.sliceAlong(startDistance: start, stopDistance: end)
        XCTAssertNotNil(sliced)

        XCTAssertEqual(sliced!.coordinates[0], startCoordinate)
        XCTAssertEqual(sliced!.coordinates[sliced!.coordinates.count - 1], endCoordinate)
    }

    func testSliceOvershoot() {
        let lineString = TestData.lineString(package: "LineSliceAlong", name: "LineSliceAlong")
        XCTAssertNotNil(lineString)

        let start: Double = GISTool.convert(length: 500.0, from: .miles, to: .meters)!
        let end: Double = GISTool.convert(length: 1500.0, from: .miles, to: .meters)!

        let startCoordinate: Coordinate3D = lineString.coordinateAlong(distance: start)
        let endCoordinate: Coordinate3D = lineString.coordinateAlong(distance: end)

        let sliced = lineString.sliceAlong(startDistance: start, stopDistance: end)
        XCTAssertNotNil(sliced)

        XCTAssertEqual(sliced!.coordinates[0], startCoordinate)
        XCTAssertEqual(sliced!.coordinates[sliced!.coordinates.count - 1], endCoordinate)
    }

    static var allTests = [
        ("testSlice", testSlice),
        ("testSliceOvershoot", testSliceOvershoot),
    ]

}
