@testable import GISTools
import Testing

struct MaskTests {

    /// A small square masked from the world produces a polygon with a hole (outer + 1 inner ring).
    @Test
    func squareMask() throws {
        let maskPolygon = try #require(Polygon([[
            Coordinate3D(latitude: -5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: -5.0),
        ]]))
        let result = maskPolygon.mask()
        #expect(result != nil)
        #expect(result?.projection == maskPolygon.projection)
        if let result {
            #expect(result.rings.count == 2)
        }
    }

    /// Masking the world polygon itself returns it unchanged (no hole).
    @Test
    func maskEntireWorld() {
        let world = Polygon.world
        let result = world.mask()
        #expect(result != nil)
        #expect(result?.projection == world.projection)
        if let result {
            #expect(result.rings.count == 1)
        }
    }

    /// A MultiPolygon mask should create a hole for each polygon.
    @Test
    func multiPolygonMask() throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: -5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: -5.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon([poly1, poly2]))
        let result = multiPolygon.mask()
        #expect(result != nil)
        #expect(result?.projection == multiPolygon.projection)
        if let result {
            #expect(result.rings.count == 3) // outer + 2 holes
        }
    }

    /// Mask with a custom outer polygon.
    @Test
    func customOuter() throws {
        let outer = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let maskPolygon = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 8.0, longitude: 2.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
            Coordinate3D(latitude: 2.0, longitude: 8.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))
        let result = maskPolygon.mask(outerPolygon: outer)
        #expect(result != nil)
        #expect(result?.projection == maskPolygon.projection) // masks projection is the input's
        if let result {
            #expect(result.rings.count == 2)
            #expect(result.outerRing?.coordinates.count == 5)
        }
    }

    /// An empty polygon (no area) as mask returns the outer polygon unchanged.
    @Test
    func emptyMask() {
        let result = Polygon.world.mask()
        #expect(result != nil)
        #expect(result?.projection == .epsg4326)
        if let result {
            #expect(result.rings.count == 1)
        }
    }

    // MARK: - Projections

    @Test
    func mask3857() throws {
        let maskPolygon = try #require(Polygon([[
            Coordinate3D(x: -50_000.0, y: -50_000.0),
            Coordinate3D(x: 50_000.0, y: -50_000.0),
            Coordinate3D(x: 50_000.0, y: 50_000.0),
            Coordinate3D(x: -50_000.0, y: 50_000.0),
            Coordinate3D(x: -50_000.0, y: -50_000.0),
        ]]))
        let result = maskPolygon.mask()
        #expect(result != nil)
        #expect(result?.projection == maskPolygon.projection)
    }

    @Test
    func maskNoSRID() throws {
        let maskPolygon = try #require(Polygon([[
            Coordinate3D(x: -50_000.0, y: -50_000.0, projection: .noSRID),
            Coordinate3D(x: 50_000.0, y: -50_000.0, projection: .noSRID),
            Coordinate3D(x: 50_000.0, y: 50_000.0, projection: .noSRID),
            Coordinate3D(x: -50_000.0, y: 50_000.0, projection: .noSRID),
            Coordinate3D(x: -50_000.0, y: -50_000.0, projection: .noSRID),
        ]]))
        let result = maskPolygon.mask()
        #expect(result != nil)
        #expect(result?.projection == maskPolygon.projection)
    }

    @Test
    func mask4978() async throws {
        let mask4326 = try #require(Polygon([[
            Coordinate3D(latitude: -5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: -5.0),
        ]]))
        let maskPolygon = mask4326.projected(to: .epsg4978)
        let result = maskPolygon.mask()
        #expect(result != nil)
        #expect(result?.projection == maskPolygon.projection)
    }

    // MARK: - Antimeridian

    /// A mask crossing the antimeridian (lon 179 to -179) punched into the world polygon.
    @Test
    func antimeridianMask() throws {
        let maskPolygon = try #require(Polygon([[
            Coordinate3D(latitude: -5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: 179.0),
        ]]))
        let result = maskPolygon.mask()
        #expect(result != nil)
        #expect(result?.projection == .epsg4326)
        if let result {
            #expect(result.rings.count == 2)
        }
    }

    /// A mask crossing the antimeridian with a non-crossing outer polygon.
    @Test
    func antimeridianCustomOuter() throws {
        let outer = try #require(Polygon([[
            Coordinate3D(latitude: -20.0, longitude: 150.0),
            Coordinate3D(latitude: -20.0, longitude: -150.0),
            Coordinate3D(latitude: 20.0, longitude: -150.0),
            Coordinate3D(latitude: 20.0, longitude: 150.0),
            Coordinate3D(latitude: -20.0, longitude: 150.0),
        ]]))
        let maskPolygon = try #require(Polygon([[
            Coordinate3D(latitude: -5.0, longitude: 175.0),
            Coordinate3D(latitude: 5.0, longitude: 175.0),
            Coordinate3D(latitude: 5.0, longitude: -175.0),
            Coordinate3D(latitude: -5.0, longitude: -175.0),
            Coordinate3D(latitude: -5.0, longitude: 175.0),
        ]]))
        let result = maskPolygon.mask(outerPolygon: outer)
        #expect(result != nil)
        #expect(result?.projection == maskPolygon.projection)
        if let result {
            #expect(result.rings.count == 2)
        }
    }

    /// A MultiPolygon mask where both polygons cross the antimeridian, punched into the world.
    @Test
    func antimeridianMultiPolygonMask() throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: -5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: 179.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 178.0),
            Coordinate3D(latitude: 20.0, longitude: 178.0),
            Coordinate3D(latitude: 20.0, longitude: -178.0),
            Coordinate3D(latitude: 10.0, longitude: -178.0),
            Coordinate3D(latitude: 10.0, longitude: 178.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon([poly1, poly2]))
        let result = multiPolygon.mask()
        #expect(result != nil)
        #expect(result?.projection == multiPolygon.projection)
        if let result {
            #expect(result.rings.count == 3) // outer + 2 holes
        }
    }

}
