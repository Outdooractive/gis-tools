import Foundation
@testable import GISTools
import Testing

struct ValidatableTests {

    // MARK: - Point

    @Test
    func pointValid() async throws {
        #expect(Point(Coordinate3D(latitude: 1.0, longitude: 1.0)).isValid)
    }

    // MARK: - MultiPoint

    @Test
    func multiPointValid() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        #expect(mp.isValid)
    }

    @Test
    func multiPointInvalid() async throws {
        let mp = MultiPoint()
        #expect(mp.isValid == false)
    }

    // MARK: - LineString

    @Test
    func lineStringValid() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(ls.isValid)
    }

    @Test
    func lineStringInvalid() async throws {
        let ls = LineString()
        #expect(ls.isValid == false)
    }

    // MARK: - MultiLineString

    @Test
    func multiLineStringValid() async throws {
        let mls = try #require(MultiLineString([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))
        #expect(mls.isValid)
    }

    @Test
    func multiLineStringInvalid() async throws {
        let mls = MultiLineString()
        #expect(mls.isValid == false)
    }

    // MARK: - Polygon

    @Test
    func polygonValid() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(polygon.isValid)
    }

    @Test
    func polygonInvalid() async throws {
        let polygon = Polygon()
        #expect(polygon.isValid == false)
    }

    // MARK: - MultiPolygon

    @Test
    func multiPolygonValid() async throws {
        let poly = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([poly]))
        #expect(mp.isValid)
    }

    @Test
    func multiPolygonInvalid() async throws {
        let mp = MultiPolygon()
        #expect(mp.isValid == false)
    }

    // MARK: - GeometryCollection

    @Test
    func geometryCollectionValid() async throws {
        let gc = GeometryCollection([])
        #expect(gc.isValid)
    }

    @Test
    func geometryCollectionWithValidGeometries() async throws {
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 1.0))
        let gc = GeometryCollection([point])
        #expect(gc.isValid)
    }

    @Test
    func geometryCollectionWithInvalidGeometry() async throws {
        let emptyLS = LineString()
        #expect(emptyLS.isValid == false)
        let gc = GeometryCollection([emptyLS])
        #expect(gc.isValid == false)
    }

    // MARK: - Feature

    @Test
    func featureValid() async throws {
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 1.0))
        #expect(Feature(point).isValid)
    }

    @Test
    func featureInvalid() async throws {
        #expect(Feature(LineString()).isValid == false)
    }

    // MARK: - FeatureCollection

    @Test
    func featureCollectionValid() async throws {
        let fc = FeatureCollection()
        #expect(fc.isValid)
    }

    @Test
    func featureCollectionAllValid() async throws {
        let fc = FeatureCollection([Feature(Point(Coordinate3D(latitude: 1.0, longitude: 1.0)))])
        #expect(fc.isValid)
    }

    @Test
    func featureCollectionWithInvalidFeature() async throws {
        let fc = FeatureCollection([Feature(LineString())])
        #expect(fc.isValid == false)
    }

    // MARK: - Static per-type isValid

    @Test
    func staticIsValid() async throws {
        #expect(Point.isValid(geoJson: ["type": "Point", "coordinates": [1.0, 2.0]]))
        #expect(LineString.isValid(geoJson: ["type": "LineString", "coordinates": [[1.0, 2.0]]]))
        #expect(MultiLineString.isValid(geoJson: ["type": "MultiLineString", "coordinates": [[[1.0, 2.0]]]]))
        #expect(MultiPoint.isValid(geoJson: ["type": "MultiPoint", "coordinates": [[1.0, 2.0]]]))
        #expect(MultiPolygon.isValid(geoJson: ["type": "MultiPolygon", "coordinates": [[[[0, 0], [1, 0], [1, 1], [0, 0]]]]]))
        #expect(Polygon.isValid(geoJson: ["type": "Polygon", "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 0]]]]))
        #expect(GeometryCollection.isValid(geoJson: ["type": "GeometryCollection", "geometries": []]))
        #expect(Feature.isValid(geoJson: ["type": "Feature", "geometry": ["type": "Point", "coordinates": [1.0, 2.0]]]))
        #expect(FeatureCollection.isValid(geoJson: ["type": "FeatureCollection", "features": []]))
    }

    @Test
    func staticIsValidWrongType() async throws {
        let geoJson: [String: Any] = ["type": "Point", "coordinates": [1.0, 2.0]]
        #expect(Point.isValid(geoJson: geoJson))
        #expect(LineString.isValid(geoJson: geoJson) == false)
    }

    @Test
    func staticIsValidInvalid() async throws {
        #expect(Point.isValid(geoJson: [:]) == false)
        #expect(Point.isValid(geoJson: ["coordinates": [1.0, 2.0]]) == false)
        #expect(Point.isValid(geoJson: ["type": "Invalid", "coordinates": [1.0, 2.0]]) == false)
        #expect(Point.isValid(geoJson: ["type": "Point"]) == false)
        #expect(Feature.isValid(geoJson: ["type": "Feature"]) == false)
    }

}
