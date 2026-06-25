@testable import GISTools
import Testing

struct MakeValidTests {

    // MARK: - Point

    @Test
    func point() {
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 2.0))
        let valid = point.madeValid()
        #expect(valid != nil)
        #expect(valid?.coordinate == point.coordinate)
    }

    // MARK: - MultiPoint

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

    @Test
    func wrongWindingOrder() throws {
        // Build a clockwise ring matching the existing booleanClockwise test pattern:
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

    @Test
    func antimeridianValidPolygon() throws {
        // Square that crosses the antimeridian: from 170° to -170°
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

    @Test
    func antimeridianBowtie() throws {
        // Self-intersecting bowtie that crosses the antimeridian
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

    @Test
    func antimeridianWrongWindingOrder() throws {
        // Clockwise ring crossing the antimeridian
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

