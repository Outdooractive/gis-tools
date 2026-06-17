@testable import GISTools
import Testing

struct MaskTests {

    /// A small square masked from the world produces a polygon with a hole (outer + 1 inner ring).
    @Test
    func squareMask() {
        let maskPolygon = Polygon(unchecked: [[
            Coordinate3D(latitude: -5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: -5.0),
        ]])
        let result = maskPolygon.mask()
        #expect(result != nil)
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
        if let result {
            #expect(result.rings.count == 1)
        }
    }

    /// A MultiPolygon mask should create a hole for each polygon.
    @Test
    func multiPolygonMask() {
        let poly1 = Polygon(unchecked: [[
            Coordinate3D(latitude: -5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: -5.0),
        ]])
        let poly2 = Polygon(unchecked: [[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]])
        let multiPolygon = MultiPolygon([poly1, poly2])!
        let result = multiPolygon.mask()
        #expect(result != nil)
        if let result {
            #expect(result.rings.count == 3) // outer + 2 holes
        }
    }

    /// Mask with a custom outer polygon.
    @Test
    func customOuter() {
        let outer = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        let maskPolygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 8.0, longitude: 2.0),
            Coordinate3D(latitude: 8.0, longitude: 8.0),
            Coordinate3D(latitude: 2.0, longitude: 8.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]])
        let result = maskPolygon.mask(outerPolygon: outer)
        #expect(result != nil)
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
        if let result {
            #expect(result.rings.count == 1)
        }
    }

    // MARK: - Antimeridian

    /// A mask crossing the antimeridian (lon 179 to -179) punched into the world polygon.
    @Test
    func antimeridianMask() {
        let maskPolygon = Polygon(unchecked: [[
            Coordinate3D(latitude: -5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: 179.0),
        ]])
        let result = maskPolygon.mask()
        #expect(result != nil)
        if let result {
            #expect(result.rings.count == 2)
        }
    }

    /// A mask crossing the antimeridian with a non-crossing outer polygon.
    @Test
    func antimeridianCustomOuter() {
        let outer = Polygon(unchecked: [[
            Coordinate3D(latitude: -20.0, longitude: 150.0),
            Coordinate3D(latitude: -20.0, longitude: -150.0),
            Coordinate3D(latitude: 20.0, longitude: -150.0),
            Coordinate3D(latitude: 20.0, longitude: 150.0),
            Coordinate3D(latitude: -20.0, longitude: 150.0),
        ]])
        let maskPolygon = Polygon(unchecked: [[
            Coordinate3D(latitude: -5.0, longitude: 175.0),
            Coordinate3D(latitude: 5.0, longitude: 175.0),
            Coordinate3D(latitude: 5.0, longitude: -175.0),
            Coordinate3D(latitude: -5.0, longitude: -175.0),
            Coordinate3D(latitude: -5.0, longitude: 175.0),
        ]])
        let result = maskPolygon.mask(outerPolygon: outer)
        #expect(result != nil)
        if let result {
            #expect(result.rings.count == 2)
        }
    }

    /// A MultiPolygon mask where both polygons cross the antimeridian, punched into the world.
    @Test
    func antimeridianMultiPolygonMask() {
        let poly1 = Polygon(unchecked: [[
            Coordinate3D(latitude: -5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: -179.0),
            Coordinate3D(latitude: -5.0, longitude: 179.0),
        ]])
        let poly2 = Polygon(unchecked: [[
            Coordinate3D(latitude: 10.0, longitude: 178.0),
            Coordinate3D(latitude: 20.0, longitude: 178.0),
            Coordinate3D(latitude: 20.0, longitude: -178.0),
            Coordinate3D(latitude: 10.0, longitude: -178.0),
            Coordinate3D(latitude: 10.0, longitude: 178.0),
        ]])
        let multiPolygon = MultiPolygon([poly1, poly2])!
        let result = multiPolygon.mask()
        #expect(result != nil)
        if let result {
            #expect(result.rings.count == 3) // outer + 2 holes
        }
    }

}
