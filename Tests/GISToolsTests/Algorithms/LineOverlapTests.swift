@testable import GISTools
import XCTest

final class LineOverlapTests: XCTestCase {

    func testSimple1() {
        let lineString1 = TestData.lineString(package: "LineOverlap", name: "LineOverlap1_1")
        let lineString2 = TestData.lineString(package: "LineOverlap", name: "LineOverlap1_2")

        let overlappingSegments = lineString1.overlappingSegments(with: lineString2)

        XCTAssertEqual(overlappingSegments.count, 2)

        XCTAssertEqual(overlappingSegments.map(\.overlap), [.equal, .equal])
        XCTAssertEqual(overlappingSegments[0].segment.second, overlappingSegments[1].segment.first)
        XCTAssertEqual(overlappingSegments[0].segment.first, Coordinate3D(latitude: -30.0, longitude: 125.0))
        XCTAssertEqual(overlappingSegments[1].segment.second, Coordinate3D(latitude: -35.0, longitude: 145.0))
    }

    func testSimple2() {
        let lineString1 = TestData.lineString(package: "LineOverlap", name: "LineOverlap2_1")
        let lineString2 = TestData.lineString(package: "LineOverlap", name: "LineOverlap2_2")

        let overlappingSegments = lineString1.overlappingSegments(with: lineString2)

        XCTAssertEqual(overlappingSegments.count, 2)

        XCTAssertEqual(overlappingSegments.map(\.overlap), [.equal, .equal])
        XCTAssertEqual(overlappingSegments[0].segment.second, overlappingSegments[1].segment.first)
        XCTAssertEqual(overlappingSegments[0].segment.first, Coordinate3D(latitude: -30.0, longitude: 125.0))
        XCTAssertEqual(overlappingSegments[1].segment.second, Coordinate3D(latitude: -35.0, longitude: 145.0))
    }

    func testSimple3() {
        let lineString1 = TestData.lineString(package: "LineOverlap", name: "LineOverlap3_1")
        let lineString2 = TestData.lineString(package: "LineOverlap", name: "LineOverlap3_2")

        let overlappingSegments = lineString1.overlappingSegments(with: lineString2)

        XCTAssertEqual(overlappingSegments.count, 2)

        XCTAssertEqual(overlappingSegments.map(\.overlap), [.equal, .equal])
        XCTAssertEqual(overlappingSegments[0].segment.second, overlappingSegments[1].segment.first)
        XCTAssertEqual(overlappingSegments[0].segment.first, Coordinate3D(latitude: -30.0, longitude: 125.0))
        XCTAssertEqual(overlappingSegments[1].segment.second, Coordinate3D(latitude: -35.0, longitude: 145.0))
    }

    func testPolygons() {
        let polygon1 = TestData.polygon(package: "LineOverlap", name: "Polygon1_1")
        let polygon2 = TestData.polygon(package: "LineOverlap", name: "Polygon1_2")
        let result = TestData.multiLineString(package: "LineOverlap", name: "Polygon1Result")

        let overlappingSegments = polygon1.overlappingSegments(with: polygon2)

        XCTAssertEqual(overlappingSegments.count, 6)
        XCTAssertEqual(Set(overlappingSegments.map(\.overlap)), [.equalReversed])

        let firstSegments = result.lineStrings[0].lineSegments
        let secondSegments = result.lineStrings[1].lineSegments

        XCTAssertEqual(Array(overlappingSegments[0 ..< 3].map(\.segment)), firstSegments)
        XCTAssertEqual(Array(overlappingSegments[3...].map(\.segment)), secondSegments)
    }

    func testNoOverlap() {
        let lineString1 = TestData.lineString(package: "LineOverlap", name: "NoOverlap1")
        let lineString2 = TestData.lineString(package: "LineOverlap", name: "NoOverlap2")

        let overlappingSegments = lineString1.overlappingSegments(with: lineString2)

        XCTAssertEqual(overlappingSegments.count, 0)
    }

    func testPartlyOverlapping1() {
        let polygon1 = TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping1_1")
        let polygon2 = TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping1_2")
        let result = TestData.multiLineString(package: "LineOverlap", name: "PartlyOverlapping1Result")

        let overlappingSegments = polygon1.overlappingSegments(with: polygon2)

        XCTAssertEqual(overlappingSegments.count, 4)
        XCTAssertEqual(Set(overlappingSegments.map(\.overlap)), [.otherOnThis])

        let firstSegments = result.lineStrings[0].lineSegments
        let secondSegments = result.lineStrings[1].lineSegments

        XCTAssertEqual(Array(overlappingSegments[0 ... 1].map(\.other)), firstSegments)
        XCTAssertEqual(Array(overlappingSegments[2...].map(\.other)), secondSegments)
    }

    func testPartlyOverlapping2() {
        let polygon1 = TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping2_1")
        let polygon2 = TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping2_2")
        let result = TestData.lineString(package: "LineOverlap", name: "PartlyOverlapping2Result")

        let overlappingSegments = polygon1.overlappingSegments(with: polygon2, tolerance: 5000.0)

        XCTAssertEqual(overlappingSegments.count, 1)
        XCTAssertEqual(Set(overlappingSegments.map(\.overlap)), [.otherOnThis])
        XCTAssertEqual(overlappingSegments.map(\.other), result.lineSegments)
    }

    func testPartlyOverlapping3() {
        let lineString1 = LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
        ])!
        let lineString2 = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
        ])!
        let result = LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
        ])!

        let overlappingSegments1 = lineString1.overlappingSegments(with: lineString2)
        let overlappingSegments2 = lineString2.overlappingSegments(with: lineString1)

        XCTAssertEqual(overlappingSegments1.count, 1)
        XCTAssertEqual(overlappingSegments2.count, 1)

        XCTAssertEqual(Set(overlappingSegments1.map(\.overlap)), [.thisOnOther])
        XCTAssertEqual(Set(overlappingSegments2.map(\.overlap)), [.otherOnThis])

        XCTAssertEqual(overlappingSegments1.map(\.segment), result.lineSegments)
        XCTAssertEqual(overlappingSegments2.map(\.other), result.lineSegments)
    }

    // MARK: - Overlap in self

    func testSelfNoOverlap() {
        let lineString = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
            Coordinate3D(latitude: 12.0, longitude: 12.0),
        ])!

        XCTAssertNil(lineString.overlappingSegments()?.lineStrings)
    }

    func testSelfOverlap1() throws {
        let lineString = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0), // overlap
            Coordinate3D(latitude: 2.0, longitude: 1.0), // "
            Coordinate3D(latitude: 3.0, longitude: 0.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 1.0), // overlap
            Coordinate3D(latitude: 6.0, longitude: 1.0), // "
            Coordinate3D(latitude: 7.0, longitude: 0.0),
            Coordinate3D(latitude: 8.0, longitude: 1.0), // overlap
            Coordinate3D(latitude: 0.0, longitude: 1.0), // "
        ])!

        let overlapping = try XCTUnwrap(lineString.overlappingSegments()?.lineStrings)
        XCTAssertEqual(overlapping.count, 3)
    }

    func testSelfOverlap2() throws {
        let lineString = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),  // overlap
            Coordinate3D(latitude: 8.0, longitude: -8.0), // "
            Coordinate3D(latitude: 7.0, longitude: -9.0),
            Coordinate3D(latitude: 6.0, longitude: -9.0),
            Coordinate3D(latitude: 6.0, longitude: -6.0), // overlap
            Coordinate3D(latitude: 5.0, longitude: -5.0), // "
            Coordinate3D(latitude: 5.0, longitude: -7.0),
            Coordinate3D(latitude: 4.0, longitude: -7.0),
            Coordinate3D(latitude: 4.0, longitude: -4.0), // overlap
            Coordinate3D(latitude: 3.0, longitude: -3.0), // "
            Coordinate3D(latitude: 3.0, longitude: -1.0),
            Coordinate3D(latitude: 1.0, longitude: -1.0), // overlap
            Coordinate3D(latitude: 0.0, longitude: 0.0),  // "
        ])!

        let overlapping = try XCTUnwrap(lineString.overlappingSegments()?.lineStrings)
        FeatureCollection(overlapping).dump()
        XCTAssertEqual(overlapping.count, 4)
    }

    func testSelfOverlap3() throws {
        let lineString = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 0.0),
            Coordinate3D(latitude: 3.0, longitude: -2.0),
            Coordinate3D(latitude: 2.0, longitude: -2.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])!

        let overlapping = try XCTUnwrap(lineString.overlappingSegments()?.lineStrings)
        XCTAssertEqual(overlapping.count, 3)
    }

    func testSelfOverlap3WithSegments() throws {
        let lineString = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 3.0, longitude: 0.0),
            Coordinate3D(latitude: 3.0, longitude: -2.0),
            Coordinate3D(latitude: 2.0, longitude: -2.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])!

        let overlapping = try XCTUnwrap(lineString.overlappingSegments()?.lineStrings)
        XCTAssertEqual(overlapping.count, 3)
    }

    func testLongRouteSelfOverlap() throws {
        let lineString = try XCTUnwrap(TestData.featureCollection(package: "LineOverlap", name: "LongRoute").features.first)

        let overlapping = try XCTUnwrap(lineString.overlappingSegments(tolerance: 10.0)?.lineStrings)
        print(overlapping.count)
        print(overlapping.reduce(0.0, { $0 + $1.length }))
        print(lineString.length)

    }

}
