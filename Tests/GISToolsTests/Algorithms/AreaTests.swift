@testable import GISTools
import Testing

struct AreaTests {

    // Tests polygon area calculation for a simple polygon without holes.
    @Test
    func areaWithNoHoles() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 0.0)
        ]]))
        #expect(abs(polygon.area - 10000.0) < 0.1)
    }

    // Tests polygon area calculation for a polygon with a single hole.
    @Test
    func areaWithSingleHole() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 0.0)
        ], [
            Coordinate3D(x: 25.0, y: 25.0),
            Coordinate3D(x: 75.0, y: 25.0),
            Coordinate3D(x: 75.0, y: 75.0),
            Coordinate3D(x: 25.0, y: 75.0),
            Coordinate3D(x: 25.0, y: 25.0)
        ]]))
        #expect(abs(polygon.area - 7500.0) < 0.1)
    }

    // Tests polygon area with overlapping holes.
    @Test
    func areaWithOverlappingHoles() async throws {
        let outerRing = try #require(Ring([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 0.0),
            Coordinate3D(x: 100.0, y: 100.0),
            Coordinate3D(x: 0.0, y: 100.0),
        ]))
        let hole1 = try #require(Ring([
            Coordinate3D(x: 20.0, y: 20.0),
            Coordinate3D(x: 60.0, y: 20.0),
            Coordinate3D(x: 60.0, y: 60.0),
            Coordinate3D(x: 20.0, y: 60.0),
        ]))
        let hole2 = try #require(Ring([
            Coordinate3D(x: 40.0, y: 40.0),
            Coordinate3D(x: 80.0, y: 40.0),
            Coordinate3D(x: 80.0, y: 80.0),
            Coordinate3D(x: 40.0, y: 80.0),
        ]))
        let polygon = try #require(Polygon([outerRing, hole1, hole2]))
        #expect(abs(polygon.area - 7200.0) < 0.1)
    }

    // MARK: - Projections

    // Verifies area for a polygon in EPSG:3857.
    @Test
    func area3857() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon3857 = try #require(Polygon([coords4326.map { $0.projected(to: .epsg3857) }]))
        let area = polygon3857.area
        #expect(area > 1.0e12)
        #expect(area < 1.5e12)
    }

    // Verifies area for the same polygon in EPSG:4978.
    @Test
    func area4978() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon4978 = try #require(Polygon([coords4326.map { $0.projected(to: .epsg4978) }]))
        let area = polygon4978.area
        #expect(area > 1.0e12)
        #expect(area < 1.5e12)
    }

    // Verifies area for the same polygon in noSRID.
    @Test
    func areaNoSRID() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygonNoSRID = try #require(Polygon([coords4326.map {
            Coordinate3D(x: $0.longitude, y: $0.latitude, projection: .noSRID)
        }]))
        let area = polygonNoSRID.area
        #expect(area > 1.0e12)
        #expect(area < 1.5e12)
    }

    // Verifies area with holes in EPSG:3857.
    @Test
    func areaWithHole3857() throws {
        let coords4326Outer: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let coords4326Hole: [Coordinate3D] = [
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 8.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
            Coordinate3D(latitude: 8.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]
        let polygon = try #require(Polygon([
            coords4326Outer.map { $0.projected(to: .epsg3857) },
            coords4326Hole.map { $0.projected(to: .epsg3857) },
        ]))
        let area = polygon.area
        #expect(area > 5.0e11)
        #expect(area < 1.0e12)
    }

    // MARK: - Antimeridian

    // Validates area for a polygon near the antimeridian.
    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let area = polygon.area
        #expect(area > 0.0)
        #expect(area < 2_000_000_000_000.0)
    }

    // A 1°×1° square crossing the date line at the equator.
    @Test
    func antimeridianCrossing() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 179.5),
            Coordinate3D(latitude: 1.0, longitude: 179.5),
            Coordinate3D(latitude: 1.0, longitude: -179.5),
            Coordinate3D(latitude: 0.0, longitude: -179.5),
            Coordinate3D(latitude: 0.0, longitude: 179.5),
        ]))
        let polygon = try #require(Polygon([ring]))
        #expect(polygon.area > 1.0e10)
        #expect(polygon.area < 1.5e10)
    }

    // Outer ring crosses the date line, inner ring also crosses.
    @Test
    func antimeridianHoleBothCross() async throws {
        let outer = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 4.0, longitude: 179.0),
            Coordinate3D(latitude: 4.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
        ]))
        let inner = try #require(Ring([
            Coordinate3D(latitude: 1.0, longitude: 179.5),
            Coordinate3D(latitude: 3.0, longitude: 179.5),
            Coordinate3D(latitude: 3.0, longitude: -179.5),
            Coordinate3D(latitude: 1.0, longitude: -179.5),
            Coordinate3D(latitude: 1.0, longitude: 179.5),
        ]))
        let polygon = try #require(Polygon([outer, inner]))
        let outerArea = outer.area
        let innerArea = inner.area
        let netArea = polygon.area
        #expect(outerArea > 0)
        #expect(innerArea > 0)
        #expect(netArea > 0)
        #expect(netArea < outerArea)
        #expect(abs(netArea - (abs(outerArea) - abs(innerArea))) < 1.0e8)
    }

    // Outer ring crosses the date line, inner ring is east of it.
    @Test
    func antimeridianHoleEastSide() async throws {
        let outer = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 4.0, longitude: 179.0),
            Coordinate3D(latitude: 4.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
        ]))
        let inner = try #require(Ring([
            Coordinate3D(latitude: 1.0, longitude: 179.2),
            Coordinate3D(latitude: 3.0, longitude: 179.2),
            Coordinate3D(latitude: 3.0, longitude: 179.8),
            Coordinate3D(latitude: 1.0, longitude: 179.8),
            Coordinate3D(latitude: 1.0, longitude: 179.2),
        ]))
        let polygon = try #require(Polygon([outer, inner]))
        let outerArea = outer.area
        let innerArea = inner.area
        let netArea = polygon.area
        #expect(outerArea > 0)
        #expect(innerArea > 0)
        #expect(netArea > 0)
        #expect(netArea < outerArea)
        #expect(abs(netArea - (abs(outerArea) - abs(innerArea))) < 1.0e8)
    }

    // Outer ring crosses the date line, inner ring is west of it.
    @Test
    func antimeridianHoleWestSide() async throws {
        let outer = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 4.0, longitude: 179.0),
            Coordinate3D(latitude: 4.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
        ]))
        let inner = try #require(Ring([
            Coordinate3D(latitude: 1.0, longitude: -179.8),
            Coordinate3D(latitude: 3.0, longitude: -179.8),
            Coordinate3D(latitude: 3.0, longitude: -179.2),
            Coordinate3D(latitude: 1.0, longitude: -179.2),
            Coordinate3D(latitude: 1.0, longitude: -179.8),
        ]))
        let polygon = try #require(Polygon([outer, inner]))
        let outerArea = outer.area
        let innerArea = inner.area
        let netArea = polygon.area
        #expect(outerArea > 0)
        #expect(innerArea > 0)
        #expect(netArea > 0)
        #expect(netArea < outerArea)
        #expect(abs(netArea - (abs(outerArea) - abs(innerArea))) < 1.0e8)
    }

}
