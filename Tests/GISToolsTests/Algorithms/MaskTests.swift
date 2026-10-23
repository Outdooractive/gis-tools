@testable import GISTools
import Testing

struct MaskTests {

    // MARK: - Reference tests

    private static let maskFixtures = [
        "SmallSquare",
        "TwoSquares",
        "LShapeMask",
    ]

    @Test(arguments: maskFixtures)
    private func turfMaskFixture(_ name: String) async throws {
        let json = try TestData.stringFromFile(package: "Mask", name: name)
        let expected = try TestData.multiPolygon(package: "Mask", name: name + "Result")

        let geoJson: PolygonGeometry
        if let poly = Polygon(jsonString: json) {
            geoJson = poly
        }
        else if let mp = MultiPolygon(jsonString: json) {
            geoJson = mp
        }
        else {
            Issue.record("Could not load mask input for \(name)")
            return
        }

        guard let result = geoJson.mask() else {
            Issue.record("Expected non-nil mask for \(name)")
            return
        }

        #expect(result.isStructurallyValid, "\(name): mask result is invalid")
        let resultArea = result.polygons.reduce(0) { $0 + $1.area }
        let expectedArea = expected.polygons.reduce(0) { $0 + $1.area }
        if expectedArea > 0 {
            let ratio = resultArea / expectedArea
            #expect(ratio > 0.99 && ratio < 1.01,
                    "\(name): area ratio \(ratio) outside [0.99, 1.01]")
        }
    }

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
            #expect(result.polygons.count == 1)
            #expect(result.polygons[0].rings.count == 2)
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
            #expect(result.polygons.count == 1)
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
            #expect(result.polygons.count == 1)
            #expect(result.polygons[0].rings.count == 3) // outer + 2 holes
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
            #expect(result.polygons.count == 1)
            #expect(result.polygons[0].rings.count == 2)
            #expect(result.polygons.first?.outerRing?.coordinates.count == 5)
        }
    }

    /// An empty polygon (no area) as mask returns the outer polygon unchanged.
    @Test
    func emptyMask() {
        let result = Polygon.world.mask()
        #expect(result != nil)
        #expect(result?.projection == .epsg4326)
        if let result {
            #expect(result.polygons.count == 1)
        }
    }

    // MARK: - Projections

    // Tests masking in EPSG:3857 projection.
    @Test
    func mask3857() throws {
        let maskPolygon = try #require(Polygon([[
            Coordinate3D(x: -50_000.0, y: -50_000.0, projection: .epsg3857),
            Coordinate3D(x: 50_000.0, y: -50_000.0, projection: .epsg3857),
            Coordinate3D(x: 50_000.0, y: 50_000.0, projection: .epsg3857),
            Coordinate3D(x: -50_000.0, y: 50_000.0, projection: .epsg3857),
            Coordinate3D(x: -50_000.0, y: -50_000.0, projection: .epsg3857),
        ]]))
        let result = maskPolygon.mask()
        #expect(result != nil)
        #expect(result?.projection == maskPolygon.projection)
        #expect(result?.polygons.first?.outerRing?.coordinates.count == 5)
        #expect(result?.polygons.count == 1)
            #expect(result?.polygons.first?.rings.count == 2)
    }

    // Tests masking in noSRID projection.
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
        #expect(result?.polygons.count == 1)
            #expect(result?.polygons.first?.rings.count == 2)
    }

    // Tests masking in EPSG:4978 projection.
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
            #expect(result.polygons.count == 1)
            #expect(result.polygons[0].rings.count == 2)
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
            #expect(result.polygons.count == 1)
            #expect(result.polygons[0].rings.count == 2)
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
            #expect(result.polygons.count == 1)
            #expect(result.polygons[0].rings.count == 3) // outer + 2 holes
        }
    }


    // MARK: - Audit regressions

    @Test
    func maskWithHoleProducesUnmaskedIsland() throws {
        func coordinate(_ x: Double, _ y: Double) -> Coordinate3D {
            Coordinate3D(x: x, y: y, projection: .noSRID)
        }
        let outer = try #require(Polygon([[
            coordinate(0.0, 0.0), coordinate(20.0, 0.0),
            coordinate(20.0, 20.0), coordinate(0.0, 20.0),
            coordinate(0.0, 0.0),
        ]]))
        let mask = try #require(Polygon([
            [
                coordinate(5.0, 5.0), coordinate(15.0, 5.0),
                coordinate(15.0, 15.0), coordinate(5.0, 15.0),
                coordinate(5.0, 5.0),
            ],
            [
                coordinate(8.0, 8.0), coordinate(12.0, 8.0),
                coordinate(12.0, 12.0), coordinate(8.0, 12.0),
                coordinate(8.0, 8.0),
            ],
        ]))

        let result = try #require(mask.mask(outerPolygon: outer))
        #expect(result.polygons.count == 2)
        // Base mask hole 10x10, plus the unmasked 4x4 island.
        #expect(abs(result.area - (400.0 - 100.0 + 16.0)) < 0.000001)
        #expect(result.polygons.allSatisfy { $0.isValid })
    }

    @Test
    func maskPartiallyCrossingOuterIsClipped() throws {
        func coordinate(_ x: Double, _ y: Double) -> Coordinate3D {
            Coordinate3D(x: x, y: y, projection: .noSRID)
        }
        let outer = try #require(Polygon([[
            coordinate(0.0, 0.0), coordinate(10.0, 0.0),
            coordinate(10.0, 10.0), coordinate(0.0, 10.0),
            coordinate(0.0, 0.0),
        ]]))
        let mask = try #require(Polygon([[
            coordinate(8.0, 0.0), coordinate(15.0, 0.0),
            coordinate(15.0, 10.0), coordinate(8.0, 10.0),
            coordinate(8.0, 0.0),
        ]]))

        let result = try #require(mask.mask(outerPolygon: outer))
        #expect(abs(result.area - 80.0) < 0.000001)
        #expect(result.polygons.allSatisfy { $0.isValid })
    }


}
