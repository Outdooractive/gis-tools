@testable import GISTools
import XCTest

final class DoubleExtensionsTests: XCTestCase {

    func testRounding() {
        let number1 = 123.45678987654
        XCTAssertEqual(number1.rounded(precision: 0), 123.0)
        XCTAssertEqual(number1.rounded(precision: 1), 123.5)
        XCTAssertEqual(number1.rounded(precision: 2), 123.46)
        XCTAssertEqual(number1.rounded(precision: 3), 123.457)
        XCTAssertEqual(number1.rounded(precision: 4), 123.4568)
        XCTAssertEqual(number1.rounded(precision: 5), 123.45679)
        XCTAssertEqual(number1.rounded(precision: 6), 123.45679)

        let number2 = 9.87654321
        XCTAssertEqual(number2.rounded(precision: 0), 10.0)
        XCTAssertEqual(number2.rounded(precision: 1), 9.9)
        XCTAssertEqual(number2.rounded(precision: 2), 9.88)
        XCTAssertEqual(number2.rounded(precision: 3), 9.877)
        XCTAssertEqual(number2.rounded(precision: 4), 9.8765)
        XCTAssertEqual(number2.rounded(precision: 5), 9.87654)
        XCTAssertEqual(number2.rounded(precision: 6), 9.876543)
    }

    func testRoundingInvalidPrecision() {
        let number = 123.456
        XCTAssertEqual(number.rounded(precision: -5), number)
    }

    func testConversions() {
        // 1 unit
        XCTAssertEqual(1.0.meters, GISTool.convert(length: 1.0, from: .meters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.0.kilometers, GISTool.convert(length: 1.0, from: .kilometers, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.0.centimeters, GISTool.convert(length: 1.0, from: .centimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.0.millimeters, GISTool.convert(length: 1.0, from: .millimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.0.inches, GISTool.convert(length: 1.0, from: .inches, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.0.feet, GISTool.convert(length: 1.0, from: .feet, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.0.yards, GISTool.convert(length: 1.0, from: .yards, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.0.miles, GISTool.convert(length: 1.0, from: .miles, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(1.0.nauticalMiles, GISTool.convert(length: 1.0, from: .nauticalmiles, to: .meters)!, accuracy: 0.001)

        // pi units
        XCTAssertEqual(Double.pi.meters, GISTool.convert(length: Double.pi, from: .meters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(Double.pi.kilometers, GISTool.convert(length: Double.pi, from: .kilometers, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(Double.pi.centimeters, GISTool.convert(length: Double.pi, from: .centimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(Double.pi.millimeters, GISTool.convert(length: Double.pi, from: .millimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(Double.pi.inches, GISTool.convert(length: Double.pi, from: .inches, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(Double.pi.feet, GISTool.convert(length: Double.pi, from: .feet, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(Double.pi.yards, GISTool.convert(length: Double.pi, from: .yards, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(Double.pi.miles, GISTool.convert(length: Double.pi, from: .miles, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(Double.pi.nauticalMiles, GISTool.convert(length: Double.pi, from: .nauticalmiles, to: .meters)!, accuracy: 0.001)

        // -1 unit
        XCTAssertEqual(-1.0.meters, -GISTool.convert(length: 1.0, from: .meters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.0.kilometers, -GISTool.convert(length: 1.0, from: .kilometers, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.0.centimeters, -GISTool.convert(length: 1.0, from: .centimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.0.millimeters, -GISTool.convert(length: 1.0, from: .millimeters, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.0.inches, -GISTool.convert(length: 1.0, from: .inches, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.0.feet, -GISTool.convert(length: 1.0, from: .feet, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.0.yards, -GISTool.convert(length: 1.0, from: .yards, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.0.miles, -GISTool.convert(length: 1.0, from: .miles, to: .meters)!, accuracy: 0.001)
        XCTAssertEqual(-1.0.nauticalMiles, -GISTool.convert(length: 1.0, from: .nauticalmiles, to: .meters)!, accuracy: 0.001)
    }

}
