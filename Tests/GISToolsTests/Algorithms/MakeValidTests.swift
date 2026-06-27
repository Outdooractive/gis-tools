@testable import GISTools
import Testing

struct MakeValidTests {

    // MARK: - Point

    // Tests madeValid on a simple Point geometry.
    @Test
    func point() {
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 2.0))
        let valid = point.madeValid()
        #expect(valid != nil)
        #expect(valid?.coordinate == point.coordinate)
    }

    // MARK: - MultiPoint

    // Tests madeValid on a MultiPoint geometry.
    @Test
    func multiPoint() throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 4.0),
        ]))
        let valid = multiPoint.madeValid()
        #expect(valid != nil)
        #expect(valid?.coordinates.count == 2)
    }

    // MARK: - LineString

    // Tests madeValid removes duplicate consecutive coordinates.
    @Test
    func lineStringWithDuplicates() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let valid = line.madeValid()
        #expect(valid != nil)
        #expect(valid?.coordinates.count == 2)
    }

    // MARK: - MultiLineString

    // Tests madeValid removes duplicates in MultiLineString.
    @Test
    func multiLineStringWithDuplicates() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let multi = try #require(MultiLineString([line]))
        let valid = multi.madeValid()
        #expect(valid != nil)
        #expect(valid?.lineStrings.first?.coordinates.count == 2)
    }

    // MARK: - Polygon

    // Tests madeValid on an already valid polygon.
    @Test
    func validPolygon() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
    }

    // Tests madeValid repairs a self-intersecting bowtie polygon.
    @Test
    func selfIntersectingBowtie() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.kinks().coordinates.isEmpty ?? true)
    }

    // Tests madeValid reverses clockwise winding order to counter-clockwise.
    @Test
    func wrongWindingOrder() throws {
        // (lat=0,lon=0) → (lat=1,lon=1) → (lat=0,lon=1) → back
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        #expect(ring.isClockwise)

        let polygon = try #require(Polygon([ring.coordinates]))
        #expect(polygon.outerRing?.isClockwise == true)

        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.outerRing?.isCounterClockwise == true)
    }

    // Tests madeValid removes duplicate coordinates from a polygon ring.
    @Test
    func polygonWithDuplicates() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.coordinates[0].count == 5)
    }

    // Tests madeValid closes an open polygon ring.
    @Test
    func polygonWithOpenRing() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.coordinates[0].first == valid?.coordinates[0].last)
    }

    // MARK: - MultiPolygon

    // Tests madeValid repairs invalid child polygons in a MultiPolygon.
    @Test
    func multiPolygonWithInvalidChild() throws {
        let validPolygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let bowtie = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))
        let multi = try #require(MultiPolygon([validPolygon, bowtie]))
        let valid = multi.madeValid()
        #expect(valid != nil)
        #expect(valid?.polygons.count == 2)
        for p in valid?.polygons ?? [] {
            #expect(p.isValid)
            #expect(p.outerRing?.isCounterClockwise == true)
        }
    }

    // MARK: - GeometryCollection

    // Tests madeValid repairs all geometries in a GeometryCollection.
    @Test
    func geometryCollection() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let collection = GeometryCollection([line, polygon])
        let valid = collection.madeValid()
        #expect(valid != nil)
        if let valid {
            let lineResult = valid.geometries[0] as? LineString
            let polyResult = valid.geometries[1] as? Polygon
            #expect(lineResult?.coordinates.count == 2)
            #expect(polyResult?.kinks().coordinates.isEmpty ?? true)
        }
    }

    // MARK: - Feature / FeatureCollection

    // Tests madeValid on a Feature preserves properties.
    @Test
    func feature() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let feature = Feature(polygon, properties: ["a": 1])
        let valid = feature.madeValid()
        #expect(valid != nil)
        #expect(valid?.properties["a"] as? Int == 1)
        let validPoly = valid?.geometry as? Polygon
        #expect(validPoly?.kinks().coordinates.isEmpty ?? true)
    }

    // Tests madeValid on a FeatureCollection.
    @Test
    func featureCollection() throws {
        let p1 = Point(Coordinate3D(latitude: 1.0, longitude: 2.0))
        let f1 = Feature(p1, properties: ["id": 1])
        let poly = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let f2 = Feature(poly, properties: ["id": 2])
        let fc = FeatureCollection([f1, f2])
        let valid = fc.madeValid()
        #expect(valid != nil)
        #expect(valid?.features.count == 2)
    }
}

// MARK: - Projections

extension MakeValidTests {

    // Tests madeValid preserves EPSG:3857 projection.
    @Test
    func validPolygon3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: -500_000.0, y: -500_000.0),
            Coordinate3D(x: 500_000.0, y: -500_000.0),
            Coordinate3D(x: 500_000.0, y: 500_000.0),
            Coordinate3D(x: -500_000.0, y: 500_000.0),
            Coordinate3D(x: -500_000.0, y: -500_000.0),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.projection == .epsg3857)
    }

    // Tests madeValid preserves EPSG:4978 projection.
    @Test
    func validPolygon4978() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 6_000_000.0, y: 6_000_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 6_000_100.0, y: 6_000_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 6_000_100.0, y: 6_000_100.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 6_000_000.0, y: 6_000_100.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 6_000_000.0, y: 6_000_000.0, z: 0.0, projection: .epsg4978),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.projection == .epsg4978)
    }

    // Tests madeValid preserves noSRID projection.
    @Test
    func validPolygonNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.projection == .noSRID)
    }

    // Tests madeValid repairs a bowtie polygon in EPSG:3857.
    @Test
    func bowtie3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: -500_000.0, y: -500_000.0),
            Coordinate3D(x: 500_000.0, y: 500_000.0),
            Coordinate3D(x: 500_000.0, y: -500_000.0),
            Coordinate3D(x: -500_000.0, y: 500_000.0),
            Coordinate3D(x: -500_000.0, y: -500_000.0),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.projection == .epsg3857)
        #expect(valid?.kinks().coordinates.isEmpty ?? true)
    }

    // Tests madeValid repairs a bowtie polygon in noSRID.
    @Test
    func bowtieNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 5.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.projection == .noSRID)
        #expect(valid?.kinks().coordinates.isEmpty ?? true)
    }

    // Tests madeValid reverses winding order in EPSG:3857.
    @Test
    func wrongWindingOrder3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 500_000.0, y: 500_000.0),
            Coordinate3D(x: 0.0, y: 500_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.projection == .epsg3857)
        #expect(valid?.outerRing?.isCounterClockwise == true)
    }

}

// MARK: - Antimeridian tests

extension MakeValidTests {

    // Tests madeValid on a polygon crossing the antimeridian.
    @Test
    func antimeridianValidPolygon() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: 170.0),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.outerRing?.isCounterClockwise == true)
    }

    // Tests madeValid repairs a bowtie crossing the antimeridian.
    @Test
    func antimeridianBowtie() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: -10.0, longitude: 175.0),
            Coordinate3D(latitude: 10.0, longitude: -175.0),
            Coordinate3D(latitude: 10.0, longitude: 175.0),
            Coordinate3D(latitude: -10.0, longitude: -175.0),
            Coordinate3D(latitude: -10.0, longitude: 175.0),
        ]]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        // The result should be a non-self-intersecting polygon
        #expect(valid?.kinks().coordinates.isEmpty ?? true)
    }

    // Tests madeValid reverses winding order on an antimeridian polygon.
    @Test
    func antimeridianWrongWindingOrder() throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 1.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
        ]))
        #expect(ring.isClockwise)

        let polygon = try #require(Polygon([ring.coordinates]))
        let valid = polygon.madeValid()
        #expect(valid != nil)
        #expect(valid?.outerRing?.isCounterClockwise == true)
    }

}

