import Foundation
@testable import GISTools
import Testing

struct AntimeridianCuttingTests {

    // MARK: - LineString

    // Tests that a LineString not crossing the antimeridian is detected and returned unchanged.
    @Test
    func lineStringNoCrossing() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 40.0, longitude: -10.0),
            Coordinate3D(latitude: 40.0, longitude: 10.0),
        ]))
        #expect(ls.crossesAntimeridian == false)

        let fc = ls.cutAtAntimeridian()
        #expect(fc.features.count == 1)
        #expect(fc.features[0].geometry is LineString)
    }

    // Tests antimeridian cutting of a LineString per RFC 7946 §3.1.9.
    @Test
    func lineStringCrossingRFCExample() async throws {
        // RFC 7946 §3.1.9: line from 45N,170E to 45N,170W
        let ls = try #require(LineString([
            Coordinate3D(latitude: 45.0, longitude: 170.0),
            Coordinate3D(latitude: 45.0, longitude: -170.0),
        ]))
        #expect(ls.crossesAntimeridian)

        let fc = ls.cutAtAntimeridian()
        #expect(fc.features.count == 2)

        // First feature: [170,45] → [180,45]
        let part1 = fc.features[0].geometry as! LineString
        #expect(part1.coordinates[0] == Coordinate3D(latitude: 45.0, longitude: 170.0))
        #expect(part1.coordinates[1] == Coordinate3D(latitude: 45.0, longitude: 180.0))

        // Second feature: [-180,45] → [-170,45]
        let part2 = fc.features[1].geometry as! LineString
        #expect(part2.coordinates[0] == Coordinate3D(latitude: 45.0, longitude: -180.0))
        #expect(part2.coordinates[1] == Coordinate3D(latitude: 45.0, longitude: -170.0))
    }

    // Tests antimeridian cutting of a LineString with latitude interpolation at the crossing point.
    @Test
    func lineStringCrossingWithLatitude() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 40.0, longitude: 160.0),
            Coordinate3D(latitude: 50.0, longitude: -150.0),
        ]))
        #expect(ls.crossesAntimeridian)

        let fc = ls.cutAtAntimeridian()
        #expect(fc.features.count == 2)

        let part1 = fc.features[0].geometry as! LineString
        #expect(part1.coordinates[0] == Coordinate3D(latitude: 40.0, longitude: 160.0))
        #expect(abs(part1.coordinates[1].latitude - 44.0) < 0.001)
        #expect(part1.coordinates[1].longitude == 180.0)

        let part2 = fc.features[1].geometry as! LineString
        #expect(abs(part2.coordinates[0].latitude - 44.0) < 0.001)
        #expect(part2.coordinates[0].longitude == -180.0)
        #expect(part2.coordinates[1] == Coordinate3D(latitude: 50.0, longitude: -150.0))
    }

    // Tests antimeridian cutting of a LineString that crosses the antimeridian multiple times.
    @Test
    func lineStringMultipleCrossings() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]))
        #expect(ls.crossesAntimeridian)

        let fc = ls.cutAtAntimeridian()
        #expect(fc.features.count == 3)
        #expect(fc.features[0].geometry is LineString)
        #expect(fc.features[1].geometry is LineString)
        #expect(fc.features[2].geometry is LineString)
    }

    // Tests antimeridian cutting of a LineString crossing from west to east.
    @Test
    func lineStringReverseCrossing() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 45.0, longitude: -170.0),
            Coordinate3D(latitude: 45.0, longitude: 170.0),
        ]))
        #expect(ls.crossesAntimeridian)

        let fc = ls.cutAtAntimeridian()
        #expect(fc.features.count == 2)

        let part1 = fc.features[0].geometry as! LineString
        #expect(part1.coordinates[0] == Coordinate3D(latitude: 45.0, longitude: -170.0))
        #expect(part1.coordinates[1] == Coordinate3D(latitude: 45.0, longitude: -180.0))

        let part2 = fc.features[1].geometry as! LineString
        #expect(part2.coordinates[0] == Coordinate3D(latitude: 45.0, longitude: 180.0))
        #expect(part2.coordinates[1] == Coordinate3D(latitude: 45.0, longitude: 170.0))
    }

    // Tests that a single-point LineString does not cross the antimeridian.
    @Test
    func lineStringSinglePoint() async throws {
        let ls = LineString()
        #expect(ls.crossesAntimeridian == false)

        let fc = ls.cutAtAntimeridian()
        #expect(fc.features.count == 1)
        #expect(fc.features[0].geometry is LineString)
    }

    // MARK: - Polygon

    // Tests that a Polygon not crossing the antimeridian is detected and returned unchanged.
    @Test
    func polygonNoCrossing() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(polygon.crossesAntimeridian == false)

        let fc = polygon.cutAtAntimeridian()
        #expect(fc.features.count == 1)
        #expect(fc.features[0].geometry is Polygon)
    }

    // Tests antimeridian cutting of a Polygon spanning the antimeridian.
    @Test
    func polygonCrossingRFCExample() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 40.0, longitude: 170.0),
            Coordinate3D(latitude: 50.0, longitude: 170.0),
            Coordinate3D(latitude: 50.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: 170.0),
        ]]))
        #expect(polygon.crossesAntimeridian)

        let fc = polygon.cutAtAntimeridian()
        #expect(fc.features.count == 2)

        #expect(fc.features[0].geometry is Polygon)
        #expect(fc.features[1].geometry is Polygon)
    }

    // Tests that antimeridian-cut Polygon rings remain properly closed (first equals last coordinate).
    @Test
    func polygonCrossingClosedRings() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 40.0, longitude: 170.0),
            Coordinate3D(latitude: 50.0, longitude: 170.0),
            Coordinate3D(latitude: 50.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: 170.0),
        ]]))

        let fc = polygon.cutAtAntimeridian()
        #expect(fc.features.count == 2)

        for feature in fc.features {
            let poly = feature.geometry as! Polygon
            let outerRing = try #require(poly.outerRing)
            let coords = outerRing.coordinates
            #expect(coords.count >= 4)
            #expect(coords.first == coords.last)
        }
    }

    // MARK: - MultiLineString

    // Tests antimeridian cutting of a MultiLineString with both crossing and non-crossing segments.
    @Test
    func multiLineStringCutting() async throws {
        let mls = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 45.0, longitude: 170.0),
                Coordinate3D(latitude: 45.0, longitude: -170.0),
            ],
            [
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
            ],
        ]))

        let fc = mls.cutAtAntimeridian()
        // first line crossing → 2 features, second line no crossing → 1 feature
        #expect(fc.features.count == 3)
        #expect(fc.features[0].geometry is LineString)
        #expect(fc.features[1].geometry is LineString)
        #expect(fc.features[2].geometry is LineString)
    }

    // MARK: - MultiPolygon

    // Tests antimeridian cutting of a MultiPolygon with both crossing and non-crossing polygons.
    @Test
    func multiPolygonCutting() async throws {
        let crossingPoly = try #require(Polygon([[
            Coordinate3D(latitude: 40.0, longitude: 170.0),
            Coordinate3D(latitude: 50.0, longitude: 170.0),
            Coordinate3D(latitude: 50.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: -170.0),
            Coordinate3D(latitude: 40.0, longitude: 170.0),
        ]]))
        let normalPoly = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let mp = try #require(MultiPolygon([crossingPoly, normalPoly]))

        let fc = mp.cutAtAntimeridian()
        // crossing → 2 features, normal → 1 feature
        #expect(fc.features.count == 3)
        #expect(fc.features[0].geometry is Polygon)
        #expect(fc.features[1].geometry is Polygon)
        #expect(fc.features[2].geometry is Polygon)
    }

    // MARK: - Feature

    // Tests that antimeridian cutting preserves feature id and properties on the first part.
    @Test
    func featureCutting() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 45.0, longitude: 170.0),
            Coordinate3D(latitude: 45.0, longitude: -170.0),
        ]))
        let feature = Feature(ls, id: .string("test"), properties: ["key": "value"])

        let fc = feature.cutAtAntimeridian()
        #expect(fc.features.count == 2)

        // First part keeps the id
        let first = fc.features[0]
        #expect(first.id == .string("test"))
        #expect(first.properties["key"] as? String == "value")
        #expect(first.geometry is LineString)

        // Second part has no id
        let second = fc.features[1]
        #expect(second.id == nil)
        #expect(second.properties["key"] as? String == "value")
        #expect(second.geometry is LineString)
    }

    // MARK: - FeatureCollection

    // Tests antimeridian cutting of a FeatureCollection containing both crossing and non-crossing features.
    @Test
    func featureCollectionCutting() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 45.0, longitude: 170.0),
            Coordinate3D(latitude: 45.0, longitude: -170.0),
        ]))
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))

        let fc = FeatureCollection([Feature(ls, id: .string("a")), Feature(point, id: .string("b"))])

        let result = fc.cutAtAntimeridian()
        // line splits into 2, point stays 1 → 3 total
        #expect(result.features.count == 3)

        #expect(result.features[0].id == .string("a"))
        #expect(result.features[0].geometry is LineString)

        #expect(result.features[1].id == nil)
        #expect(result.features[1].geometry is LineString)

        #expect(result.features[2].id == .string("b"))
        #expect(result.features[2].geometry is Point)
    }

    // MARK: - GeometryCollection

    // Tests antimeridian cutting of a GeometryCollection with mixed geometry types.
    @Test
    func geometryCollectionCutting() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 45.0, longitude: 170.0),
            Coordinate3D(latitude: 45.0, longitude: -170.0),
        ]))
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))

        let gc = GeometryCollection([ls, point])

        let fc = gc.cutAtAntimeridian()
        #expect(fc.features.count == 3)
        #expect(fc.features[0].geometry is LineString)
        #expect(fc.features[1].geometry is LineString)
        #expect(fc.features[2].geometry is Point)
    }

    // MARK: - Point (unchanged)

    // Tests that a Point is returned unchanged by antimeridian cutting.
    @Test
    func pointCutting() async throws {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 170.0))
        let fc = point.cutAtAntimeridian()
        #expect(fc.features.count == 1)
        #expect(fc.features[0].geometry is Point)
    }

    // MARK: - EPSG:3857

    // Tests that crossesAntimeridian detects crossing in EPSG:3857 via projection to 4326.
    @Test
    func lineStringCrossesAntimeridian3857() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 45.0, longitude: 170.0).projected(to: .epsg3857),
            Coordinate3D(latitude: 45.0, longitude: -170.0).projected(to: .epsg3857),
        ])
        #expect(ls.crossesAntimeridian == true)
    }

    // Tests that cutAtAntimeridian on an EPSG:3857 LineString produces correct results.
    @Test
    func lineStringCut3857() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 45.0, longitude: 170.0).projected(to: .epsg3857),
            Coordinate3D(latitude: 45.0, longitude: -170.0).projected(to: .epsg3857),
        ])
        let fc = ls.cutAtAntimeridian()
        #expect(fc.features.count == 2)
        for feature in fc.features {
            #expect(feature.geometry is LineString)
        }
    }

    // Tests that crossesAntimeridian detects crossing in an EPSG:3857 polygon.
    @Test
    func polygonCrossesAntimeridian3857() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: 170.0),
        ]
        let polygon = Polygon(unchecked: [coords4326.map { $0.projected(to: .epsg3857) }])
        #expect(polygon.crossesAntimeridian == true)
    }

    // Tests that cutAtAntimeridian on an EPSG:3857 polygon produces correct results.
    @Test
    func polygonCut3857() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: 170.0),
        ]
        let polygon = Polygon(unchecked: [coords4326.map { $0.projected(to: .epsg3857) }])
        let fc = polygon.cutAtAntimeridian()
        #expect(fc.features.count >= 2)
        for feature in fc.features {
            #expect(feature.geometry is Polygon)
        }
    }

    // MARK: - EPSG:4978 and noSRID (always false/self)

    // Tests that crossesAntimeridian returns false for EPSG:4978.
    @Test
    func crossesAntimeridian4978() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 45.0, longitude: 170.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 45.0, longitude: -170.0).projected(to: .epsg4978),
        ])
        #expect(ls.crossesAntimeridian == false)
    }

    // Tests that cutAtAntimeridian returns the original for EPSG:4978.
    @Test
    func cutAtAntimeridian4978() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 45.0, longitude: 170.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 45.0, longitude: -170.0).projected(to: .epsg4978),
        ])
        let fc = ls.cutAtAntimeridian()
        #expect(fc.features.count == 1)
        #expect(fc.features[0].geometry is LineString)
    }

    // Tests that crossesAntimeridian returns false for noSRID.
    @Test
    func crossesAntimeridianNoSRID() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
        ])
        #expect(ls.crossesAntimeridian == false)
    }

    // Tests that cutAtAntimeridian returns the original for noSRID.
    @Test
    func cutAtAntimeridianNoSRID() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
        ])
        let fc = ls.cutAtAntimeridian()
        #expect(fc.features.count == 1)
        #expect(fc.features[0].geometry is LineString)
    }

    // MARK: - crossesAntimeridian for all types

    // Tests crossesAntimeridian on MultiLineString across projections.
    @Test
    func multiLineStringCrossesAntimeridian() throws {
        let ls1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let ls2 = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
        ]))
        let mls = MultiLineString([ls1, ls2])!
        #expect(mls.crossesAntimeridian == true)

        let mlsNoCross = MultiLineString([ls2, ls2])!
        #expect(mlsNoCross.crossesAntimeridian == false)
    }

    @Test
    func multiLineStringCrossesAntimeridian3857() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg3857),
            Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg3857),
        ])
        let mls = MultiLineString(unchecked: [ls])
        #expect(mls.crossesAntimeridian == true)
    }

    @Test
    func multiLineStringCrossesAntimeridian4978() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg4978),
        ])
        let mls = MultiLineString(unchecked: [ls])
        #expect(mls.crossesAntimeridian == false)
    }

    // Tests crossesAntimeridian on MultiPolygon across projections.
    @Test
    func multiPolygonCrossesAntimeridian() throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 20.0, longitude: 0.0),
            Coordinate3D(latitude: 30.0, longitude: 0.0),
            Coordinate3D(latitude: 30.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 10.0),
            Coordinate3D(latitude: 20.0, longitude: 0.0),
        ]]))
        let mp = MultiPolygon([p1, p2])!
        #expect(mp.crossesAntimeridian == true)

        let mpNoCross = MultiPolygon([p2, p2])!
        #expect(mpNoCross.crossesAntimeridian == false)
    }

    @Test
    func multiPolygonCrossesAntimeridian3857() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: 170.0),
        ]
        let polygon = Polygon(unchecked: [coords4326.map { $0.projected(to: .epsg3857) }])
        let mp = MultiPolygon(unchecked: [polygon])
        #expect(mp.crossesAntimeridian == true)
    }

    @Test
    func multiPolygonCrossesAntimeridian4978() throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: 170.0),
        ]
        let polygon = Polygon(unchecked: [coords4326.map { $0.projected(to: .epsg4978) }])
        let mp = MultiPolygon(unchecked: [polygon])
        #expect(mp.crossesAntimeridian == false)
    }

    // Tests crossesAntimeridian on GeometryCollection across projections.
    @Test
    func geometryCollectionCrossesAntimeridian() throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let gc = GeometryCollection([ls, point])
        #expect(gc.crossesAntimeridian == true)

        let gcNoCross = GeometryCollection([point, point])
        #expect(gcNoCross.crossesAntimeridian == false)
    }

    @Test
    func geometryCollectionCrossesAntimeridian3857() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg3857),
            Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg3857),
        ])
        let gc = GeometryCollection([ls])
        #expect(gc.crossesAntimeridian == true)
    }

    @Test
    func geometryCollectionCrossesAntimeridian4978() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg4978),
        ])
        let gc = GeometryCollection([ls])
        #expect(gc.crossesAntimeridian == false)
    }

    // Tests crossesAntimeridian on Feature across projections.
    @Test
    func featureCrossesAntimeridian() throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let feature = Feature(ls)
        #expect(feature.crossesAntimeridian == true)

        let noCrossFeature = Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(noCrossFeature.crossesAntimeridian == false)
    }

    @Test
    func featureCrossesAntimeridian3857() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg3857),
            Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg3857),
        ])
        let feature = Feature(ls)
        #expect(feature.crossesAntimeridian == true)
    }

    @Test
    func featureCrossesAntimeridian4978() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg4978),
        ])
        let feature = Feature(ls)
        #expect(feature.crossesAntimeridian == false)
    }

    // Tests crossesAntimeridian on FeatureCollection across projections.
    @Test
    func featureCollectionCrossesAntimeridian() throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let f1 = Feature(ls)
        let f2 = Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        let fc = FeatureCollection([f1, f2])
        #expect(fc.crossesAntimeridian == true)

        let fcNoCross = FeatureCollection([f2, f2])
        #expect(fcNoCross.crossesAntimeridian == false)
    }

    @Test
    func featureCollectionCrossesAntimeridian3857() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg3857),
            Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg3857),
        ])
        let fc = FeatureCollection([Feature(ls)])
        #expect(fc.crossesAntimeridian == true)
    }

    @Test
    func featureCollectionCrossesAntimeridian4978() throws {
        let ls = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 170.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: -170.0).projected(to: .epsg4978),
        ])
        let fc = FeatureCollection([Feature(ls)])
        #expect(fc.crossesAntimeridian == false)
    }

    // Tests crossesAntimeridian for Polygon with noSRID (always false).
    @Test
    func polygonCrossesAntimeridianNoSRID() throws {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]])
        #expect(polygon.crossesAntimeridian == false)
    }

}
