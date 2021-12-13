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

    static var allTests = [
        ("testRounding", testRounding),
        ("testRoundingInvalidPrecision", testRoundingInvalidPrecision),
    ]

}
