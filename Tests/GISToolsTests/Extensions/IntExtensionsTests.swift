@testable import GISTools
import XCTest

final class IntExtensionsTests: XCTestCase {

    func testConversions() {
        // 1 unit
        XCTAssertEqual(1.meters, GISTool.convert(length: 1.0, from: .meters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.kilometers, GISTool.convert(length: 1.0, from: .kilometers, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.centimeters, GISTool.convert(length: 1.0, from: .centimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.millimeters, GISTool.convert(length: 1.0, from: .millimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.inches, GISTool.convert(length: 1.0, from: .inches, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.feet, GISTool.convert(length: 1.0, from: .feet, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.yards, GISTool.convert(length: 1.0, from: .yards, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.miles, GISTool.convert(length: 1.0, from: .miles, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.nauticalMiles, GISTool.convert(length: 1.0, from: .nauticalmiles, to: .meters)!, accuracy: 0.001)

        // 314 units
        XCTAssertEqual(314.meters, GISTool.convert(length: 314.0, from: .meters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(314.kilometers, GISTool.convert(length: 314.0, from: .kilometers, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(314.centimeters, GISTool.convert(length: 314.0, from: .centimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(314.millimeters, GISTool.convert(length: 314.0, from: .millimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(314.inches, GISTool.convert(length: 314.0, from: .inches, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(314.feet, GISTool.convert(length: 314.0, from: .feet, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(314.yards, GISTool.convert(length: 314.0, from: .yards, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(314.miles, GISTool.convert(length: 314.0, from: .miles, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(314.nauticalMiles, GISTool.convert(length: 314.0, from: .nauticalmiles, to: .meters)!, accuracy: 0.001)

        // -1 unit
        XCTAssertEqual(-1.meters, -GISTool.convert(length: 1.0, from: .meters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.kilometers, -GISTool.convert(length: 1.0, from: .kilometers, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.centimeters, -GISTool.convert(length: 1.0, from: .centimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.millimeters, -GISTool.convert(length: 1.0, from: .millimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.inches, -GISTool.convert(length: 1.0, from: .inches, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.feet, -GISTool.convert(length: 1.0, from: .feet, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.yards, -GISTool.convert(length: 1.0, from: .yards, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.miles, -GISTool.convert(length: 1.0, from: .miles, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.nauticalMiles, -GISTool.convert(length: 1.0, from: .nauticalmiles, to: .meters)!, accuracy: 0.001)
    }

}
