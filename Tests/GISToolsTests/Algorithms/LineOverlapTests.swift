@testable import GISTools
import Testing

struct LineOverlapTests {

    // Tests overlapping segments detection between two line strings (case 1).
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

    // Tests overlapping segments detection between two line strings (case 2).
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

    // Tests overlapping segments detection between two line strings (case 3).
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

    // Tests overlapping segments detection between two polygons.
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

    // Tests that non-overlapping line strings return no overlapping segments.
    @Test
    func noOverlap() async throws {
        let lineString1 = try TestData.lineString(package: "LineOverlap", name: "NoOverlap1")
        let lineString2 = try TestData.lineString(package: "LineOverlap", name: "NoOverlap2")

        let overlappingSegments = lineString1.overlappingSegments(with: lineString2)
        #expect(overlappingSegments.count == 0)
    }

    // Tests partial overlap detection between two polygons (case 1).
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

    // Tests partial overlap detection between two polygons with a tolerance value (case 2).
    @Test
    func partlyOverlapping2() async throws {
        let polygon1 = try TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping2_1")
        let polygon2 = try TestData.polygon(package: "LineOverlap", name: "PartlyOverlapping2_2")
        let result = try TestData.lineString(package: "LineOverlap", name: "PartlyOverlapping2Result")

        let overlappingSegments = polygon1.overlappingSegments(with: polygon2, tolerance: 5000.0)
        #expect(overlappingSegments.count == 1)
        #expect(overlappingSegments == result.lineSegments)
    }

    // Tests that overlapping segments detection is symmetric regardless of argument order.
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

    // MARK: - gridSize

    // Validates that `overlappingSegments(with:tolerance:gridSize:)` matches manual pre-snapping.
    @Test
    func overlappingSegmentsWithGridSize() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 2.0001, longitude: 2.0001),
            Coordinate3D(latitude: 4.0001, longitude: 4.0001),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 6.0001, longitude: 6.0001),
        ]))
        let gridSize = 0.001

        let withParam = line1.overlappingSegments(with: line2, gridSize: gridSize)
        let snapped1 = line1.snappedToGrid(tolerance: gridSize)
        let snapped2 = line2.snappedToGrid(tolerance: gridSize)
        let manual = snapped1.overlappingSegments(with: snapped2)
        #expect(withParam == manual)
    }

    // MARK: - EPSG:3857

    @Test
    func lineOverlap3857() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 200.0, y: 200.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(x: 50.0, y: 50.0),
            Coordinate3D(x: 150.0, y: 150.0),
        ]))
        let overlappingSegments = line1.overlappingSegments(with: line2)
        #expect(overlappingSegments.count == 1)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: 174.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: 174.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let overlappingSegments = line1.overlappingSegments(with: line2)
        #expect(!overlappingSegments.isEmpty)
    }

}
