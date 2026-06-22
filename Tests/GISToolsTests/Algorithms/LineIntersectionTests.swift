@testable import GISTools
import Testing

struct LineIntersectionTests {

    // Tests intersection of two simple 2-vertex line strings at a single point.
    @Test
    func lineIntersection2Vertex() async throws {
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

        let intersections: [Point] = feature1.intersections(with: feature2)
        let results: [Point] = [Point(Coordinate3D(latitude: -14.835723, longitude: 125.583754))]

        #expect(intersections.count == 1)
        #expect(abs(intersections[0].coordinate.latitude - results[0].coordinate.latitude) < 0.00001)
        #expect(abs(intersections[0].coordinate.longitude - results[0].coordinate.longitude) < 0.00001)
    }

    // Tests intersection of two line strings that cross at two points.
    @Test
    func lineIntersectionDouble() async throws {
        let lineString1 = try TestData.lineString(package: "LineIntersection", name: "LineIntersectionDouble1")
        let lineString2 = try TestData.lineString(package: "LineIntersection", name: "LineIntersectionDouble2")

        let intersections: [Point] = lineString1.intersections(with: lineString2)
        let results: [Point] = [
            Point(Coordinate3D(latitude: -11.630938, longitude: 132.808697)),
            Point(Coordinate3D(latitude: -19.58857, longitude: 119.832884)),
        ]

        #expect(intersections.count == 2)

        outerloop: for resultIndex in 0 ..< results.count {
            for intersectionIndex in 0 ..< intersections.count {
                if abs(intersections[intersectionIndex].coordinate.latitude - results[resultIndex].coordinate.latitude) < 0.00001,
                   abs(intersections[intersectionIndex].coordinate.longitude - results[resultIndex].coordinate.longitude) < 0.00001
                {
                    continue outerloop
                }
            }
            Issue.record("Intersection missing: \(results[resultIndex])")
        }
    }

    // Tests intersection detection between two polygons with holes.
    @Test
    func lineIntersectionPolygonsWithHoles() async throws {
        let polygon1 = try TestData.polygon(package: "LineIntersection", name: "LineIntersectionPolygonsWithHoles1")
        let polygon2 = try TestData.polygon(package: "LineIntersection", name: "LineIntersectionPolygonsWithHoles2")

        let intersections: [Point] = polygon1.intersections(with: polygon2)
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

        #expect(intersections.count == 18)

        outerloop: for resultIndex in 0 ..< results.count {
            for intersectionIndex in 0 ..< intersections.count {
                if abs(intersections[intersectionIndex].coordinate.latitude - results[resultIndex].coordinate.latitude) < 0.00001,
                   abs(intersections[intersectionIndex].coordinate.longitude - results[resultIndex].coordinate.longitude) < 0.00001
                {
                    continue outerloop
                }
            }
            Issue.record("Intersection missing: \(results[resultIndex])")
        }
    }

    // Tests intersection detection between two multi-line strings.
    @Test
    func lineIntersectionMultiLineStrings() async throws {
        let multiLineString1 = try TestData.multiLineString(package: "LineIntersection", name: "LineIntersectionMultiLineStrings1")
        let multiLineString2 = try TestData.multiLineString(package: "LineIntersection", name: "LineIntersectionMultiLineStrings2")

        let intersections: [Point] = multiLineString1.intersections(with: multiLineString2)
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

        #expect(intersections.count == 10)

        outerloop: for resultIndex in 0 ..< results.count {
            for intersectionIndex in 0 ..< intersections.count {
                if abs(intersections[intersectionIndex].coordinate.latitude - results[resultIndex].coordinate.latitude) < 0.00001,
                   abs(intersections[intersectionIndex].coordinate.longitude - results[resultIndex].coordinate.longitude) < 0.00001
                {
                    continue outerloop
                }
            }
            Issue.record("Intersection missing: \(results[resultIndex])")
        }
    }

    // Tests intersection detection for line strings sharing coordinate points.
    @Test
    func lineIntersectionSameCoordinates() async throws {
        let lineString1 = try TestData.lineString(package: "LineIntersection", name: "LineIntersectionSameCoordinates1")
        let lineString2 = try TestData.lineString(package: "LineIntersection", name: "LineIntersectionSameCoordinates2")

        let intersections: [Point] = lineString1.intersections(with: lineString2)
        let results: [Point] = [
            Point(Coordinate3D(latitude: -20, longitude: 120)),
            Point(Coordinate3D(latitude: -20, longitude: 130)),
        ]

        #expect(intersections.count == 2)

        outerloop: for resultIndex in 0 ..< results.count {
            for intersectionIndex in 0 ..< intersections.count {
                if abs(intersections[intersectionIndex].coordinate.latitude - results[resultIndex].coordinate.latitude) < 0.00001,
                   abs(intersections[intersectionIndex].coordinate.longitude - results[resultIndex].coordinate.longitude) < 0.00001
                {
                    continue outerloop
                }
            }
            Issue.record("Intersection missing: \(results[resultIndex])")
        }
    }

    // Tests the boolean intersects method on line segments for crossing, parallel, and offset cases.
    @Test
    func booleanIntersection() async throws {
        let segment1 = LineSegment(first: Coordinate3D(latitude: 1.0, longitude: 1.0),
                                   second: Coordinate3D(latitude: 1.0, longitude: 10.0))
        let segment2 = LineSegment(first: Coordinate3D(latitude: 2.0, longitude: 1.0),
                                   second: Coordinate3D(latitude: 2.0, longitude: 10.0))
        #expect(segment1.intersects(segment2) == false)

        let segment3 = LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 10.0),
                                   second: Coordinate3D(latitude: 10.0, longitude: 0.0))
        let segment4 = LineSegment(first: Coordinate3D(latitude: 0.0, longitude: 0.0),
                                   second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(segment3.intersects(segment4))

        let segment5 = LineSegment(first: Coordinate3D(latitude: -5.0, longitude: -5.0),
                                   second: Coordinate3D(latitude: 0.0, longitude: 0.0))
        let segment6 = LineSegment(first: Coordinate3D(latitude: 1.0, longitude: 1.0),
                                   second: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(segment5.intersects(segment6) == false)
    }

    // MARK: - Edge case tests for intersection()

    // Tests that two crossing line segments return the correct intersection point.
    @Test
    func intersectionCrossing() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        let s2 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 10),
                             second: Coordinate3D(latitude: 10, longitude: 0))
        let result = try #require(s1.intersection(s2))
        #expect(abs(result.latitude - 5) < 1e-10)
        #expect(abs(result.longitude - 5) < 1e-10)
    }

    // Tests that two line segments meeting at an endpoint return that endpoint as the intersection.
    @Test
    func intersectionMeetingAtEndpoint() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 5, longitude: 5))
        let s2 = LineSegment(first: Coordinate3D(latitude: 5, longitude: 5),
                             second: Coordinate3D(latitude: 10, longitude: 0))
        let result = try #require(s1.intersection(s2))
        #expect(abs(result.latitude - 5) < 1e-10)
        #expect(abs(result.longitude - 5) < 1e-10)
    }

    // Tests that near-miss segments touching at endpoints are detected as intersecting with an epsilon tolerance.
    @Test
    func intersectionTouchingAtEndpointWithEpsilon() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        let s2 = LineSegment(first: Coordinate3D(latitude: 10.000000001, longitude: 10.000000001),
                             second: Coordinate3D(latitude: 20, longitude: 0))
        #expect(s1.intersection(s2) == nil)
        #expect(s1.intersection(s2, epsilon: 1e-6) != nil)
    }

    // Tests that non-crossing, non-overlapping line segments return no intersection.
    @Test
    func intersectionNoCrossing() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 5, longitude: 5))
        let s2 = LineSegment(first: Coordinate3D(latitude: 6, longitude: 6),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        #expect(s1.intersection(s2) == nil)
    }

    // Tests that parallel, non-overlapping line segments return no intersection.
    @Test
    func intersectionParallelNoOverlap() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 0))
        let s2 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 5),
                             second: Coordinate3D(latitude: 10, longitude: 5))
        #expect(s1.intersection(s2) == nil)
    }

    // Tests that fully overlapping collinear segments return no single point intersection.
    @Test
    func intersectionCollinearOverlapFull() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        let s2 = LineSegment(first: Coordinate3D(latitude: 2, longitude: 2),
                             second: Coordinate3D(latitude: 8, longitude: 8))
        #expect(s1.intersection(s2) == nil)
    }

    // Tests that partially overlapping collinear segments return no single point intersection.
    @Test
    func intersectionCollinearOverlapPartial() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        let s2 = LineSegment(first: Coordinate3D(latitude: 5, longitude: 5),
                             second: Coordinate3D(latitude: 15, longitude: 15))
        #expect(s1.intersection(s2) == nil)
    }

    // Tests that collinear segments touching at endpoints return no single point intersection.
    @Test
    func intersectionCollinearTouchingAtEndpoint() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        let s2 = LineSegment(first: Coordinate3D(latitude: 10, longitude: 10),
                             second: Coordinate3D(latitude: 20, longitude: 20))
        #expect(s1.intersection(s2) == nil)
    }

    // Tests that collinear non-overlapping segments return no intersection.
    @Test
    func intersectionCollinearNoOverlap() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 5, longitude: 5))
        let s2 = LineSegment(first: Coordinate3D(latitude: 6, longitude: 6),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        #expect(s1.intersection(s2) == nil)
    }

    // Tests that identical collinear segments return no single point intersection.
    @Test
    func intersectionCollinearSameEndpoint() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        let s2 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        #expect(s1.intersection(s2) == nil)
    }

    // Tests intersection of a horizontal and a vertical line segment.
    @Test
    func intersectionVerticalSegments() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 5),
                             second: Coordinate3D(latitude: 10, longitude: 5))
        let s2 = LineSegment(first: Coordinate3D(latitude: 2, longitude: 3),
                             second: Coordinate3D(latitude: 2, longitude: 7))
        let result = try #require(s1.intersection(s2))
        #expect(abs(result.latitude - 2) < 1e-10)
        #expect(abs(result.longitude - 5) < 1e-10)
    }

    // MARK: - Edge case tests for intersects()

    // Tests that the boolean intersects method returns false for non-crossing, non-overlapping segments.
    @Test
    func intersectsNoCrossing() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 5, longitude: 5))
        let s2 = LineSegment(first: Coordinate3D(latitude: 6, longitude: 6),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        #expect(s1.intersects(s2) == false)
    }

    // Tests that the boolean intersects method returns true for segments touching at endpoints.
    @Test
    func intersectsEndpointTouching() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 5, longitude: 5))
        let s2 = LineSegment(first: Coordinate3D(latitude: 5, longitude: 5),
                             second: Coordinate3D(latitude: 10, longitude: 0))
        #expect(s1.intersects(s2))
    }

    // MARK: - EPSG:3857

    @Test
    func lineIntersection3857() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 1_000_000.0),
            Coordinate3D(x: 1_000_000.0, y: 0.0),
        ]))
        let feature1 = Feature(line1)
        let feature2 = Feature(line2)
        let intersections: [Point] = feature1.intersections(with: feature2)
        #expect(intersections.count == 1)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: -5.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: 174.0),
            Coordinate3D(latitude: 5.0, longitude: 179.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: 174.0),
            Coordinate3D(latitude: -5.0, longitude: 179.0),
        ]))
        let feature1 = Feature(line1)
        let feature2 = Feature(line2)
        let intersections: [Point] = feature1.intersections(with: feature2)
        #expect(!intersections.isEmpty)
    }

    // Validates that `intersection(_:gridSize:)` on LineSegment matches manual pre-snapping.
    @Test
    func intersectionWithGridSize() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0.0001, longitude: 0.0001),
                              second: Coordinate3D(latitude: 10.0001, longitude: 10.0001))
        let s2 = LineSegment(first: Coordinate3D(latitude: 0.0001, longitude: 10.0001),
                              second: Coordinate3D(latitude: 10.0001, longitude: 0.0001))
        let gridSize = 0.001

        let withParam = try #require(s1.intersection(s2, gridSize: gridSize))
        let snap: (Coordinate3D) -> Coordinate3D = {
            Point($0).snappedToGrid(tolerance: gridSize).coordinate
        }
        let snapped1 = LineSegment(first: snap(s1.first), second: snap(s1.second))
        let snapped2 = LineSegment(first: snap(s2.first), second: snap(s2.second))
        let manual = try #require(snapped1.intersection(snapped2))
        #expect(abs(withParam.latitude - manual.latitude) < 1e-10)
        #expect(abs(withParam.longitude - manual.longitude) < 1e-10)
    }

    // Tests that the boolean intersects method returns true for overlapping collinear segments.
    @Test
    func intersectsCollinearOverlap() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        let s2 = LineSegment(first: Coordinate3D(latitude: 3, longitude: 3),
                             second: Coordinate3D(latitude: 7, longitude: 7))
        #expect(s1.intersects(s2))
    }

    // Tests that the boolean intersects method returns false for collinear non-overlapping segments.
    @Test
    func intersectsCollinearNoOverlap() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 5, longitude: 5))
        let s2 = LineSegment(first: Coordinate3D(latitude: 6, longitude: 6),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        #expect(s1.intersects(s2) == false)
    }

    // Tests that near-miss segments are detected as intersecting only when an epsilon tolerance is provided.
    @Test
    func intersectsNearMissWithEpsilon() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 0))
        let s2 = LineSegment(first: Coordinate3D(latitude: 10.0000001, longitude: 0),
                             second: Coordinate3D(latitude: 20, longitude: 0))
        #expect(s1.intersects(s2) == false)
        #expect(s1.intersects(s2, epsilon: 1e-6))
    }

    // Tests that segments nearly meeting at endpoints are detected as intersecting only with an epsilon tolerance.
    @Test
    func intersectsMeetingAtEndpointWithEpsilon() async throws {
        let s1 = LineSegment(first: Coordinate3D(latitude: 0, longitude: 0),
                             second: Coordinate3D(latitude: 10, longitude: 10))
        let s2 = LineSegment(first: Coordinate3D(latitude: 10.000000001, longitude: 10.000000001),
                             second: Coordinate3D(latitude: 20, longitude: 0))
        #expect(s1.intersects(s2) == false)
        #expect(s1.intersects(s2, epsilon: 1e-6))
    }

}
