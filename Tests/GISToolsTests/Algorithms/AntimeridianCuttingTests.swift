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

}
