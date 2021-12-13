@testable import GISTools
import XCTest

final class BooleanParallelTests: XCTestCase {

    func testTrue() {
        let lineString1 = TestData.lineString(package: "BooleanParallel", name: "LineStringTrue1_1")
        let lineString2 = TestData.lineString(package: "BooleanParallel", name: "LineStringTrue1_2")

        let lineString3 = TestData.lineString(package: "BooleanParallel", name: "LineStringTrue2_1")
        let lineString4 = TestData.lineString(package: "BooleanParallel", name: "LineStringTrue2_1")

        let lineString5 = TestData.lineString(package: "BooleanParallel", name: "LineStringTrue3_1")
        let lineString6 = TestData.lineString(package: "BooleanParallel", name: "LineStringTrue3_1")

        let lineString7 = TestData.lineString(package: "BooleanParallel", name: "LineStringTrue4_1")
        let lineString8 = TestData.lineString(package: "BooleanParallel", name: "LineStringTrue4_1")

        XCTAssertTrue(lineString1.isParallel(to: lineString2))
        XCTAssertTrue(lineString3.isParallel(to: lineString4))
        XCTAssertTrue(lineString5.isParallel(to: lineString6))
        XCTAssertTrue(lineString7.isParallel(to: lineString8))
    }

    func testFalse() {
        let lineString1 = TestData.lineString(package: "BooleanParallel", name: "LineStringFalse1_1")
        let lineString2 = TestData.lineString(package: "BooleanParallel", name: "LineStringFalse1_2")

        let lineString3 = TestData.lineString(package: "BooleanParallel", name: "LineStringFalse2_1")
        let lineString4 = TestData.lineString(package: "BooleanParallel", name: "LineStringFalse2_2")

        XCTAssertFalse(lineString1.isParallel(to: lineString2))
        XCTAssertFalse(lineString3.isParallel(to: lineString4))
    }

    static var allTests = [
        ("testFalse", testFalse),
        ("testTrue", testTrue),
    ]

}
