@testable import GISTools
import XCTest

final class LineIntersectionTests: XCTestCase {

    func testLineIntersection2Vertex() {
        let feature1 = Feature(
            LineString([
                Coordinate3D(latitude: -12.768946, longitude: 124.584961),
                Coordinate3D(latitude: -17.224758, longitude: 126.738281),
            ])!)
        let feature2 = Feature(
            LineString([
                Coordinate3D(latitude: -15.961329, longitude: 123.354492),
                Coordinate3D(latitude: -14.008696, longitude: 127.22168),
            ])!)

        let intersections: [Point] = feature1.intersections(other: feature2)
        let results: [Point] = [Point(Coordinate3D(latitude: -14.835723, longitude: 125.583754))]

        XCTAssertEqual(intersections.count, 1)
        XCTAssertEqual(intersections[0].coordinate.latitude, results[0].coordinate.latitude, accuracy: 0.00001)
        XCTAssertEqual(intersections[0].coordinate.longitude, results[0].coordinate.longitude, accuracy: 0.00001)
    }

    func testLineIntersectionDouble() {
        let lineString1 = TestData.lineString(package: "LineIntersection", name: "LineIntersectionDouble1")
        let lineString2 = TestData.lineString(package: "LineIntersection", name: "LineIntersectionDouble2")

        let intersections: [Point] = lineString1.intersections(other: lineString2)
        let results: [Point] = [
            Point(Coordinate3D(latitude: -11.630938, longitude: 132.808697)),
            Point(Coordinate3D(latitude: -19.58857, longitude: 119.832884)),
        ]

        XCTAssertEqual(intersections.count, 2)

        outerloop: for resultIndex in 0 ..< results.count {
            for intersectionIndex in 0 ..< intersections.count {
                if abs(intersections[intersectionIndex].coordinate.latitude - results[resultIndex].coordinate.latitude) < 0.00001,
                   abs(intersections[intersectionIndex].coordinate.longitude - results[resultIndex].coordinate.longitude) < 0.00001
                {
                    continue outerloop
                }
            }
            XCTFail("Intersection missing: \(results[resultIndex])")
        }
    }

    func testLineIntersectionPolygonsWithHoles() {
        let polygon1 = TestData.polygon(package: "LineIntersection", name: "LineIntersectionPolygonsWithHoles1")
        let polygon2 = TestData.polygon(package: "LineIntersection", name: "LineIntersectionPolygonsWithHoles2")

        let intersections: [Point] = polygon1.intersections(other: polygon2)
        let results: [Point] = [
            Point(Coordinate3D(latitude: -33.654475, longitude: 120.170188)),
            Point(Coordinate3D(latitude: -19.242649, longitude: 118.465639)),
            Point(Coordinate3D(latitude: -17.011768, longitude: 122.447193)),
            Point(Coordinate3D(latitude: -33.423855, longitude: 122.196098)),
            Point(Coordinate3D(latitude: -32.826977, longitude: 126.041148)),
            Point(Coordinate3D(latitude: -33.236589, longitude: 124.581243)),
            Point(Coordinate3D(latitude: -29.942512, longitude: 123.377165)),
            Point(Coordinate3D(latitude: -29.253959, longitude: 124.468085)),
            Point(Coordinate3D(latitude: -30.505027, longitude: 121.100749)),
            Point(Coordinate3D(latitude: -30.393864, longitude: 120.201928)),
            Point(Coordinate3D(latitude: -27.434744, longitude: 119.582432)),
            Point(Coordinate3D(latitude: -27.12517, longitude: 122.824274)),
            Point(Coordinate3D(latitude: -24.567108, longitude: 120.1132)),
            Point(Coordinate3D(latitude: -24.567108, longitude: 123.053712)),
            Point(Coordinate3D(latitude: -21.344425, longitude: 120.17229)),
            Point(Coordinate3D(latitude: -21.361437, longitude: 124.80125)),
            Point(Coordinate3D(latitude: -19.890723, longitude: 124.392377)),
            Point(Coordinate3D(latitude: -18.187607, longitude: 123.320136)),
        ]

        XCTAssertEqual(intersections.count, 18)

        outerloop: for resultIndex in 0 ..< results.count {
            for intersectionIndex in 0 ..< intersections.count {
                if abs(intersections[intersectionIndex].coordinate.latitude - results[resultIndex].coordinate.latitude) < 0.00001,
                   abs(intersections[intersectionIndex].coordinate.longitude - results[resultIndex].coordinate.longitude) < 0.00001
                {
                    continue outerloop
                }
            }
            XCTFail("Intersection missing: \(results[resultIndex])")
        }
    }

    func testLineIntersectionMultiLineStrings() {
        let multiLineString1 = TestData.multiLineString(package: "LineIntersection", name: "LineIntersectionMultiLineStrings1")
        let multiLineString2 = TestData.multiLineString(package: "LineIntersection", name: "LineIntersectionMultiLineStrings2")

        let intersections: [Point] = multiLineString1.intersections(other: multiLineString2)
        let results: [Point] = [
            Point(Coordinate3D(latitude: -14.675333, longitude: 136.479474)),
            Point(Coordinate3D(latitude: -14.506578, longitude: 136.389417)),
            Point(Coordinate3D(latitude: -11.630938, longitude: 132.808697)),
            Point(Coordinate3D(latitude: -11.91514, longitude: 135.006479)),
            Point(Coordinate3D(latitude: -19.58857, longitude: 119.832884)),
            Point(Coordinate3D(latitude: -20.917359, longitude: 117.006519)),
            Point(Coordinate3D(latitude: -25.732946, longitude: 118.554586)),
            Point(Coordinate3D(latitude: -23.805914, longitude: 121.656735)),
            Point(Coordinate3D(latitude: -18.734814, longitude: 132.658557)),
            Point(Coordinate3D(latitude: -18.403004, longitude: 135.197772)),
        ]

        XCTAssertEqual(intersections.count, 10)

        outerloop: for resultIndex in 0 ..< results.count {
            for intersectionIndex in 0 ..< intersections.count {
                if abs(intersections[intersectionIndex].coordinate.latitude - results[resultIndex].coordinate.latitude) < 0.00001,
                   abs(intersections[intersectionIndex].coordinate.longitude - results[resultIndex].coordinate.longitude) < 0.00001
                {
                    continue outerloop
                }
            }
            XCTFail("Intersection missing: \(results[resultIndex])")
        }
    }

    func testLineIntersectionSameCoordinates() {
        let lineString1 = TestData.lineString(package: "LineIntersection", name: "LineIntersectionSameCoordinates1")
        let lineString2 = TestData.lineString(package: "LineIntersection", name: "LineIntersectionSameCoordinates2")

        let intersections: [Point] = lineString1.intersections(other: lineString2)
        let results: [Point] = [
            Point(Coordinate3D(latitude: -20, longitude: 120)),
            Point(Coordinate3D(latitude: -20, longitude: 130)),
        ]

        XCTAssertEqual(intersections.count, 2)

        outerloop: for resultIndex in 0 ..< results.count {
            for intersectionIndex in 0 ..< intersections.count {
                if abs(intersections[intersectionIndex].coordinate.latitude - results[resultIndex].coordinate.latitude) < 0.00001,
                   abs(intersections[intersectionIndex].coordinate.longitude - results[resultIndex].coordinate.longitude) < 0.00001
                {
                    continue outerloop
                }
            }
            XCTFail("Intersection missing: \(results[resultIndex])")
        }
    }

    func testBooleanIntersection() {
        let segment1 = LineSegment(first: Coordinate3D(latitude: 1.0, longitude: 1.0),
                                   second: Coordinate3D(latitude: 1.0, longitude: 10.0))
        let segment2 = LineSegment(first: Coordinate3D(latitude: 2.0, longitude: 1.0),
                                   second: Coordinate3D(latitude: 2.0, longitude: 10.0))
        XCTAssertFalse(segment1.intersects(segment2))

        let segment3 = LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 10.0),
                                   second: Coordinate3D(latitude: 10.0, longitude: 0.0))
        let segment4 = LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 0.0),
                                   second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        XCTAssertTrue(segment3.intersects(segment4))

        let segment5 = LineSegment(first: Coordinate3D(latitude: -5.0, longitude: -5.0),
                                   second: Coordinate3D(latitude: 0.0, longitude: 0.0))
        let segment6 = LineSegment(first: Coordinate3D(latitude: 1.0, longitude: 1.0),
                                   second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        XCTAssertFalse(segment5.intersects(segment6))
    }

}
