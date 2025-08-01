@testable import GISTools
import Testing

struct LineOverlapTests {

    @Test
    func simple1() async throws {
        let lineString1 = try TestData.lineString(package: "LineOverlap", name: "LineOverlap1_1")
        let lineString2 = try TestData.lineString(package: "LineOverlap", name: "LineOverlap1_2")

        let overlappingSegments = lineString1.overlappingSegments(with: lineString2)
        #expect(overlappingSegments.count == 2)
        #expect(overlappingSegments[0].second == overlappingSegments[1].first)
        #expect(overlappingSegments[0].first == Coordinate3D(latitude: -30.0, longitude: 125.0))
        #expect(overlappingSegments[1].second == Coordinate3D(latitude: -35.0, longitude: 145.0))
    }

    @Test
    func simple2() async throws {
        let lineString1 = try TestData.lineString(package: "LineOverlap", name: "LineOverlap2_1")
        let lineString2 = try TestData.lineString(package: "LineOverlap", name: "LineOverlap2_2")

        let overlappingSegments = lineString1.overlappingSegments(with: lineString2)
        #expect(overlappingSegments.count == 2)
        #expect(overlappingSegments[0].second == overlappingSegments[1].first)
        #expect(overlappingSegments[0].first == Coordinate3D(latitude: -30.0, longitude: 125.0))
        #expect(overlappingSegments[1].second == Coordinate3D(latitude: -35.0, longitude: 145.0))
    }

    @Test
    func simple3() async throws {
        let lineString1 = try TestData.lineString(package: "LineOverlap", name: "LineOverlap3_1")
        let lineString2 = try TestData.lineString(package: "LineOverlap", name: "LineOverlap3_2")

        let overlappingSegments = lineString1.overlappingSegments(with: lineString2)
        #expect(overlappingSegments.count == 2)
        #expect(overlappingSegments[0].second == overlappingSegments[1].first)
        #expect(overlappingSegments[0].first == Coordinate3D(latitude: -30.0, longitude: 125.0))
        #expect(overlappingSegments[1].second == Coordinate3D(latitude: -35.0, longitude: 145.0))
    }

    @Test
    func polygons() async throws {
        let polygon1 = try TestData.polygon(package: "LineOverlap", name: "Polygon1_1")
        let polygon2 = try TestData.polygon(package: "LineOverlap", name: "Polygon1_2")
        let result = try TestData.multiLineString(package: "LineOverlap", name: "Polygon1Result")

        let overlappingSegments = polygon1.overlappingSegments(with: polygon2)
        #expect(overlappingSegments.count == 6)

        let firstSegments = result.lineStrings[0].lineSegments
        let secondSegments = result.lineStrings[1].lineSegments
        #expect(Array(overlappingSegments[0 ..< 3]) == firstSegments)
        #expect(Array(overlappingSegments[3...]) == secondSegments)
    }

    @Test
    func noOverlap() async throws {
        let lineString1 = try TestData.lineString(package: "LineOverlap", name: "NoOverlap1")
        let lineString2 = try TestData.lineString(package: "LineOverlap", name: "NoOverlap2")

        let overlappingSegments = lineString1.overlappingSegments(with: lineString2)
        #expect(overlappingSegments.count == 0)
    }

    @Test
    func partlyOverlapping1() async throws {
        let polygon1 = try TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping1_1")
        let polygon2 = try TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping1_2")
        let result = try TestData.multiLineString(package: "LineOverlap", name: "PartlyOverlapping1Result")

        let overlappingSegments = polygon1.overlappingSegments(with: polygon2)
        #expect(overlappingSegments.count == 4)

        let firstSegments = result.lineStrings[0].lineSegments
        let secondSegments = result.lineStrings[1].lineSegments
        #expect(Array(overlappingSegments[0 ... 1]) == firstSegments)
        #expect(Array(overlappingSegments[2...]) == secondSegments)
    }

    @Test
    func partlyOverlapping2() async throws {
        let polygon1 = try TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping2_1")
        let polygon2 = try TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping2_2")
        let result = try TestData.lineString(package: "LineOverlap", name: "PartlyOverlapping2Result")

        let overlappingSegments = polygon1.overlappingSegments(with: polygon2, tolerance: 5000.0)
        #expect(overlappingSegments.count == 1)
        #expect(overlappingSegments == result.lineSegments)
    }

    @Test
    func partlyOverlapping3() async throws {
        let lineString1 = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
        ]))
        let lineString2 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
        ]))
        let result = try #require(LineString([
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
        ]))

        let overlappingSegments1 = lineString1.overlappingSegments(with: lineString2)
        let overlappingSegments2 = lineString2.overlappingSegments(with: lineString1)

        #expect(overlappingSegments1.count == 1)
        #expect(overlappingSegments2.count == 1)

        #expect(overlappingSegments1 == result.lineSegments)
        #expect(overlappingSegments2 == result.lineSegments)
    }

}
