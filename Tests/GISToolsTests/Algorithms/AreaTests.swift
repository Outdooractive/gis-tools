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

    // Two overlapping holes: their union area is less than the sum of individuals.
    // Tests polygon area calculation for a polygon with overlapping holes (hole union area is subtracted).
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

        // Union of holes = (20,20)-(60,60) ∪ (40,40)-(80,80)
        // Overlap region (40,40)-(60,60) has area 400
        // Union area = 1600 + 1600 - 400 = 2800
        // Expected area = 10000 - 2800 = 7200
        #expect(abs(polygon.area - 7200.0) < 0.1)
    }

    // MARK: - Antimeridian

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

    /// A 1°×1° square that crosses the date line at the equator.
    /// The area should match a normal 1°×1° square near the equator (~1.24e10 m²).
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

    /// Outer ring crosses the date line, inner ring ALSO crosses the date line.
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
        #expect(netArea < outerArea)  // hole subtracted
        #expect(abs(netArea - (abs(outerArea) - abs(innerArea))) < 1.0e8)
    }

    /// Outer ring crosses the date line, inner ring is entirely east of it.
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

    // MARK: - Projection tests

    // Verifies polygon area for the same physical polygon in EPSG:3857.
    @Test
    func area3857() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon3857 = Polygon(unchecked: [coords4326.map { $0.projected(to: .epsg3857) }])
        let area = polygon3857.area
        // 10°×10° near equator ≈ 1.24e12 m²
        #expect(area > 1.0e12)
        #expect(area < 1.5e12)
    }

    // Verifies polygon area for the same physical polygon in EPSG:4978.
    @Test
    func area4978() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygon4978 = Polygon(unchecked: [coords4326.map { $0.projected(to: .epsg4978) }])
        let area = polygon4978.area
        #expect(area > 1.0e12)
        #expect(area < 1.5e12)
    }

    // Verifies polygon area for the same physical polygon in noSRID.
    @Test
    func areaNoSRID() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let polygonNoSRID = Polygon(unchecked: [coords4326.map {
            Coordinate3D(x: $0.longitude, y: $0.latitude, projection: .noSRID)
        }])
        let area = polygonNoSRID.area
        #expect(area > 1.0e12)
        #expect(area < 1.5e12)
    }

    // Verifies polygon area with holes in EPSG:3857.
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
        let polygon = Polygon(unchecked: [
            coords4326Outer.map { $0.projected(to: .epsg3857) },
            coords4326Hole.map { $0.projected(to: .epsg3857) },
        ])
        let area = polygon.area
        // Outer 10°×10° minus hole 6°×6° ≈ 1.24e12 - 4.46e11 ≈ 7.94e11
        #expect(area > 5.0e11)
        #expect(area < 1.0e12)
    }

    /// Outer ring crosses the date line, inner ring is entirely west of it.
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
