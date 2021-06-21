#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class BooleanOverlapTests: XCTestCase {

    func testFalse() {
        let lineString1 = TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse1_1")
        let lineString2 = TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse1_2")

        let lineString3 = TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse2_1")
        let lineString4 = TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse2_2")

        let lineString5 = TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse3_1")
        let lineString6 = TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse3_2")

        let multiPoint1 = TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse4_1")
        let multiPoint2 = TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse4_2")

        let multiPoint3 = TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse6_1")
        let multiPoint4 = TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse6_2")

//        let polygon1 = TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse5_1")
//        let polygon2 = TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse5_2")

        let polygon3 = TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse7_1")
        let polygon4 = TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse7_2")

        XCTAssertFalse(lineString1.isOverlapping(with: lineString2))
        XCTAssertFalse(lineString3.isOverlapping(with: lineString4))
        XCTAssertFalse(lineString5.isOverlapping(with: lineString6))
        XCTAssertFalse(multiPoint1.isOverlapping(with: multiPoint2))
        XCTAssertFalse(multiPoint3.isOverlapping(with: multiPoint4))

        // TODO: This test will fail because the coordinates are shifted. The Polygon equality check has to
        // be updated first (see the TODO there)
//        XCTAssertFalse(polygon1.isOverlapping(with: polygon2))
        XCTAssertFalse(polygon3.isOverlapping(with: polygon4))
    }

    func testTrue() {
        let lineString1 = TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue1_1")
        let lineString2 = TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue1_2")

        let lineString3 = TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue2_1")
        let lineString4 = TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue2_2")

        let lineString5 = TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue5_1")
        let lineString6 = TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue5_2")

        let multiPoint1 = TestData.multiPoint(package: "BooleanOverlap", name: "OverlapTrue3_1")
        let multiPoint2 = TestData.multiPoint(package: "BooleanOverlap", name: "OverlapTrue3_2")

        let polygon1 = TestData.polygon(package: "BooleanOverlap", name: "OverlapTrue4_1")
        let polygon2 = TestData.polygon(package: "BooleanOverlap", name: "OverlapTrue4_2")

        XCTAssertTrue(lineString1.isOverlapping(with: lineString2))
        XCTAssertTrue(lineString3.isOverlapping(with: lineString4))
        XCTAssertTrue(lineString5.isOverlapping(with: lineString6))
        XCTAssertTrue(multiPoint1.isOverlapping(with: multiPoint2))
        XCTAssertTrue(polygon1.isOverlapping(with: polygon2))

    }

    static var allTests = [
        ("testFalse", testFalse),
        ("testTrue", testTrue),
    ]

}
