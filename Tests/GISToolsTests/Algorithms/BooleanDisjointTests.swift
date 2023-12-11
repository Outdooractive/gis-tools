@testable import GISTools
import XCTest

final class BooleanDisjointTests: XCTestCase {

    func testTrue() {
        let point1 = TestData.point(package: "BooleanDisjoint", name: "Point1")
        let point2 = TestData.point(package: "BooleanDisjoint", name: "Point2")
        let multiPoint1 = TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint1")
        let multiPoint2 = TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint2")
        let multiPoint3 = TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint3")
        let lineString1 = TestData.lineString(package: "BooleanDisjoint", name: "LineString1")
        let lineString2 = TestData.lineString(package: "BooleanDisjoint", name: "LineString2")
        let polygon1 = TestData.polygon(package: "BooleanDisjoint", name: "Polygon1")
        let polygon2 = TestData.polygon(package: "BooleanDisjoint", name: "Polygon2")
        let multiPolygon1 = TestData.multiPolygon(package: "BooleanDisjoint", name: "MultiPolygon1")

        XCTAssertTrue(point1.isDisjoint(with: point2))
        XCTAssertTrue(point1.isDisjoint(with: multiPoint2))
        XCTAssertTrue(point1.isDisjoint(with: lineString2))
        XCTAssertTrue(point2.isDisjoint(with: point1))
        XCTAssertTrue(point2.isDisjoint(with: polygon1))
        XCTAssertTrue(point2.isDisjoint(with: multiPolygon1))

        XCTAssertTrue(multiPoint1.isDisjoint(with: multiPoint2))
        XCTAssertTrue(multiPoint2.isDisjoint(with: point1))
        XCTAssertTrue(multiPoint2.isDisjoint(with: multiPoint1))
        XCTAssertTrue(multiPoint3.isDisjoint(with: polygon1))

        XCTAssertTrue(lineString1.isDisjoint(with: lineString2))
        XCTAssertTrue(lineString1.isDisjoint(with: polygon1))
        XCTAssertTrue(lineString2.isDisjoint(with: point1))
        XCTAssertTrue(lineString2.isDisjoint(with: multiPoint1))
        XCTAssertTrue(lineString2.isDisjoint(with: lineString1))

        XCTAssertTrue(polygon1.isDisjoint(with: point2))
        XCTAssertTrue(polygon1.isDisjoint(with: multiPoint3))
        XCTAssertTrue(polygon1.isDisjoint(with: lineString1))
        XCTAssertTrue(polygon1.isDisjoint(with: polygon2))
        XCTAssertTrue(polygon2.isDisjoint(with: multiPolygon1))
        XCTAssertTrue(polygon2.isDisjoint(with: polygon1))

        XCTAssertTrue(multiPolygon1.isDisjoint(with: polygon2))
        XCTAssertTrue(multiPolygon1.isDisjoint(with: point2))
    }

    func testFalse() {
        let point3 = TestData.point(package: "BooleanDisjoint", name: "Point3")
        let point4 = TestData.point(package: "BooleanDisjoint", name: "Point4")
        let multiPoint2 = TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint2")
        let multiPoint4 = TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint4")
        let multiPoint5 = TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint5")
        let lineString2 = TestData.lineString(package: "BooleanDisjoint", name: "LineString2")
        let lineString3 = TestData.lineString(package: "BooleanDisjoint", name: "LineString3")
        let lineString4 = TestData.lineString(package: "BooleanDisjoint", name: "LineString4")
        let polygon1 = TestData.polygon(package: "BooleanDisjoint", name: "Polygon1")
        let polygon3 = TestData.polygon(package: "BooleanDisjoint", name: "Polygon3")
        let multiPolygon1 = TestData.multiPolygon(package: "BooleanDisjoint", name: "MultiPolygon1")

        XCTAssertFalse(point3.isDisjoint(with: lineString2))
        XCTAssertFalse(point4.isDisjoint(with: lineString2))

        XCTAssertFalse(multiPoint2.isDisjoint(with: multiPoint4))
        XCTAssertFalse(multiPoint4.isDisjoint(with: lineString2))
        XCTAssertFalse(multiPoint5.isDisjoint(with: polygon1))

        XCTAssertFalse(lineString2.isDisjoint(with: point3))
        XCTAssertFalse(lineString2.isDisjoint(with: point4))
        XCTAssertFalse(lineString2.isDisjoint(with: lineString3))
        XCTAssertFalse(lineString2.isDisjoint(with: multiPoint4))
        XCTAssertFalse(lineString3.isDisjoint(with: lineString2))
        XCTAssertFalse(lineString3.isDisjoint(with: polygon1))
        XCTAssertFalse(lineString4.isDisjoint(with: polygon1))

        XCTAssertFalse(polygon1.isDisjoint(with: multiPoint5))
        XCTAssertFalse(polygon1.isDisjoint(with: lineString3))
        XCTAssertFalse(polygon1.isDisjoint(with: lineString4))
        XCTAssertFalse(polygon3.isDisjoint(with: multiPolygon1))

        XCTAssertFalse(multiPolygon1.isDisjoint(with: polygon3))
    }

}
