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

//        let polygon1 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse5_1")
//        let polygon2 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse5_2")

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

    // MARK: - Grid size

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

    // MARK: - Projections

    @Test
    func isOverlappingEPSG3857() throws {
        // Two squares that partially overlap in EPSG:3857.
        let poly1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(x: 500.0, y: 500.0),
            Coordinate3D(x: 1_500.0, y: 500.0),
            Coordinate3D(x: 1_500.0, y: 1_500.0),
            Coordinate3D(x: 500.0, y: 1_500.0),
            Coordinate3D(x: 500.0, y: 500.0),
        ]]))
        #expect(poly1.isOverlapping(with: poly2))
        #expect(poly2.isOverlapping(with: poly1))
    }

    @Test
    func isOverlappingEPSG4978() throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000.0, y: 1_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 1_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(x: 500.0, y: 500.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_500.0, y: 500.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_500.0, y: 1_500.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 500.0, y: 1_500.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 500.0, y: 500.0, z: 0.0, projection: .epsg4978),
        ]]))
        #expect(poly1.isOverlapping(with: poly2))
    }

    @Test
    func isOverlappingNoSRID() throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID),
            Coordinate3D(x: 1_500.0, y: 500.0, projection: .noSRID),
            Coordinate3D(x: 1_500.0, y: 1_500.0, projection: .noSRID),
            Coordinate3D(x: 500.0, y: 1_500.0, projection: .noSRID),
            Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID),
        ]]))
        #expect(poly1.isOverlapping(with: poly2))
    }

    // MARK: - Point / MultiPoint projection tests

    @Test
    func isOverlappingPointEPSG3857() {
        let a = Point(Coordinate3D(x: 0.0, y: 0.0))
        let b = Point(Coordinate3D(x: 0.0, y: 0.0))
        // Identical points do not overlap per DE-9IM
        #expect(!a.isOverlapping(with: b))
    }

    @Test
    func isOverlappingPointEPSG4978() {
        let a = Point(Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978))
        let b = Point(Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978))
        #expect(!a.isOverlapping(with: b))
    }

    @Test
    func isOverlappingMultiPointEPSG3857() throws {
        let mp = try #require(MultiPoint([Coordinate3D(x: 0.0, y: 0.0), Coordinate3D(x: 10.0, y: 10.0)]))
        let other = try #require(MultiPoint([Coordinate3D(x: 10.0, y: 10.0), Coordinate3D(x: 20.0, y: 20.0)]))
        #expect(mp.isOverlapping(with: other))
    }

    @Test
    func isOverlappingMultiPointEPSG4978() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 10.0, y: 10.0, z: 0.0, projection: .epsg4978)]))
        let other = try #require(MultiPoint([
            Coordinate3D(x: 10.0, y: 10.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 20.0, y: 20.0, z: 0.0, projection: .epsg4978)]))
        #expect(mp.isOverlapping(with: other))
    }

    // MARK: - LineString projection tests

    @Test
    func isOverlappingLineStringEPSG3857() throws {
        let l1 = try #require(LineString([Coordinate3D(x: 0.0, y: 0.0), Coordinate3D(x: 20.0, y: 20.0)]))
        let l2 = try #require(LineString([Coordinate3D(x: 5.0, y: 5.0), Coordinate3D(x: 15.0, y: 15.0)]))
        #expect(l1.isOverlapping(with: l2))
    }

    @Test
    func isOverlappingLineStringEPSG4978() throws {
        let l1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 200.0, y: 200.0, z: 0.0, projection: .epsg4978)]))
        let l2 = try #require(LineString([
            Coordinate3D(x: 50.0, y: 50.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 150.0, y: 150.0, z: 0.0, projection: .epsg4978)]))
        #expect(l1.isOverlapping(with: l2))
    }

    @Test
    func isOverlappingLineStringNoSRID() throws {
        let l1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 20.0, y: 20.0, projection: .noSRID)]))
        let l2 = try #require(LineString([
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 15.0, y: 15.0, projection: .noSRID)]))
        #expect(l1.isOverlapping(with: l2))
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

    // MARK: - Empty / degenerate

    @Test
    func emptyGeometriesDoNotOverlap() async throws {
        let emptyPolygon = Polygon()
        let nonEmptyPolygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(emptyPolygon.isOverlapping(with: nonEmptyPolygon) == false)
        #expect(nonEmptyPolygon.isOverlapping(with: emptyPolygon) == false)
        #expect(emptyPolygon.isOverlapping(with: emptyPolygon) == false)
    }

}
