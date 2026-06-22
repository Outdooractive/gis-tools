@testable import GISTools
import Testing

struct BooleanOverlapTests {

    // Validates that `isOverlapping` returns false for non-overlapping geometries.
    @Test
    func isFalse() async throws {
        let lineString1 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse1_1")
        let lineString2 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse1_2")

        let lineString3 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse2_1")
        let lineString4 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse2_2")

        let lineString5 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse3_1")
        let lineString6 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse3_2")

        let multiPoint1 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse4_1")
        let multiPoint2 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse4_2")

        let multiPoint3 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse6_1")
        let multiPoint4 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse6_2")

//        let polygon1 = TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse5_1")
//        let polygon2 = TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse5_2")

        let polygon3 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse7_1")
        let polygon4 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse7_2")

        #expect(lineString1.isOverlapping(with: lineString2) == false)
        #expect(lineString3.isOverlapping(with: lineString4) == false)
        #expect(lineString5.isOverlapping(with: lineString6) == false)
        #expect(multiPoint1.isOverlapping(with: multiPoint2) == false)
        #expect(multiPoint3.isOverlapping(with: multiPoint4) == false)

        // TODO: This test will fail because the coordinates are shifted. The Polygon equality check has to
        // be updated first (see the TODO there)
//        #expect(polygon1.isOverlapping(with: polygon2) == false)
        #expect(polygon3.isOverlapping(with: polygon4) == false)
    }

    // Validates that `isOverlapping` returns true for overlapping geometries.
    @Test
    func isTrue() async throws {
        let lineString1 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue1_1")
        let lineString2 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue1_2")

        let lineString3 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue2_1")
        let lineString4 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue2_2")

        let lineString5 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue5_1")
        let lineString6 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue5_2")

        let multiPoint1 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapTrue3_1")
        let multiPoint2 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapTrue3_2")

        let polygon1 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapTrue4_1")
        let polygon2 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapTrue4_2")

        #expect(lineString1.isOverlapping(with: lineString2))
        #expect(lineString3.isOverlapping(with: lineString4))
        #expect(lineString5.isOverlapping(with: lineString6))
        #expect(multiPoint1.isOverlapping(with: multiPoint2))
        #expect(polygon1.isOverlapping(with: polygon2))
    }

    // MARK: - gridSize

    // Validates that `isOverlapping(with:gridSize:)` matches manual pre-snapping.
    @Test
    func overlapWithGridSize() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 2.0001, longitude: 2.0001),
            Coordinate3D(latitude: 4.0001, longitude: 4.0001),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 6.0001, longitude: 6.0001),
        ]))
        let gridSize = 0.001

        let withParam = line1.isOverlapping(with: line2, gridSize: gridSize)
        let snapped1 = line1.snappedToGrid(tolerance: gridSize)
        let snapped2 = line2.snappedToGrid(tolerance: gridSize)
        let manual = snapped1.isOverlapping(with: snapped2)
        #expect(withParam == manual)
    }

    // MARK: - Projection tests

    @Test
    func polygonOverlapsPolygon3857() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        let point = Point(Coordinate3D(x: 500.0, y: 500.0))
        #expect(polygon.contains(point))
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: -170.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 175.0),
            Coordinate3D(latitude: 5.0, longitude: -175.0),
        ]))
        #expect(line1.isOverlapping(with: line2))
    }

}
