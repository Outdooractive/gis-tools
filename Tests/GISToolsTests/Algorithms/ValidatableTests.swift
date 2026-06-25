import Foundation
@testable import GISTools
import Testing

struct ValidatableTests {

    // MARK: - Point

    // Validates that a valid Point is recognized as valid.
    @Test
    func pointValid() async throws {
        #expect(Point(Coordinate3D(latitude: 1.0, longitude: 1.0)).isValid)
    }

    // MARK: - MultiPoint

    // Validates that a valid MultiPoint is recognized as valid.
    @Test
    func multiPointValid() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        #expect(mp.isValid)
    }

    // Validates that an empty MultiPoint is recognized as invalid.
    @Test
    func multiPointInvalid() async throws {
        let mp = MultiPoint()
        #expect(mp.isValid == false)
    }

    // MARK: - LineString

    // Validates that a valid LineString is recognized as valid.
    @Test
    func lineStringValid() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(ls.isValid)
    }

    // Validates that an empty LineString is recognized as invalid.
    @Test
    func lineStringInvalid() async throws {
        let ls = LineString()
        #expect(ls.isValid == false)
    }

    // MARK: - MultiLineString

    // Validates that a valid MultiLineString is recognized as valid.
    @Test
    func multiLineStringValid() async throws {
        let mls = try #require(MultiLineString([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))
        #expect(mls.isValid)
    }

    // Validates that an empty MultiLineString is recognized as invalid.
    @Test
    func multiLineStringInvalid() async throws {
        let mls = MultiLineString()
        #expect(mls.isValid == false)
    }

    // MARK: - Polygon

    // Validates that a valid Polygon is recognized as valid.
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

    // Validates that an empty Polygon is recognized as invalid.
    @Test
    func polygonInvalid() async throws {
        let polygon = Polygon()
        #expect(polygon.isValid == false)
    }

    // MARK: - MultiPolygon

    // Validates that a valid MultiPolygon is recognized as valid.
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

    // Validates that an empty MultiPolygon is recognized as invalid.
    @Test
    func multiPolygonInvalid() async throws {
        let mp = MultiPolygon()
        #expect(mp.isValid == false)
    }

    // MARK: - GeometryCollection

    // Validates that an empty GeometryCollection is recognized as valid.
    @Test
    func geometryCollectionValid() async throws {
        let gc = GeometryCollection([])
        #expect(gc.isValid)
    }

    // Validates that a GeometryCollection with valid geometries is recognized as valid.
    @Test
    func geometryCollectionWithValidGeometries() async throws {
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 1.0))
        let gc = GeometryCollection([point])
        #expect(gc.isValid)
    }

    // Validates that a GeometryCollection containing an invalid geometry is invalid.
    @Test
    func geometryCollectionWithInvalidGeometry() async throws {
        let emptyLS = LineString()
        #expect(emptyLS.isValid == false)
        let gc = GeometryCollection([emptyLS])
        #expect(gc.isValid == false)
    }

    // MARK: - Feature

    // Validates that a Feature with a valid geometry is recognized as valid.
    @Test
    func featureValid() async throws {
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 1.0))
        #expect(Feature(point).isValid)
    }

    // Validates that a Feature with an invalid geometry is recognized as invalid.
    @Test
    func featureInvalid() async throws {
        #expect(Feature(LineString()).isValid == false)
    }

    // MARK: - FeatureCollection

    // Validates that an empty FeatureCollection is recognized as valid.
    @Test
    func featureCollectionValid() async throws {
        let fc = FeatureCollection()
        #expect(fc.isValid)
    }

    // Validates that a FeatureCollection with all valid features is recognized as valid.
    @Test
    func featureCollectionAllValid() async throws {
        let fc = FeatureCollection([Feature(Point(Coordinate3D(latitude: 1.0, longitude: 1.0)))])
        #expect(fc.isValid)
    }

    // Validates that a FeatureCollection containing an invalid feature is invalid.
    @Test
    func featureCollectionWithInvalidFeature() async throws {
        let fc = FeatureCollection([Feature(LineString())])
        #expect(fc.isValid == false)
    }

    // MARK: - Static per-type isValid

    // Validates that static isValid returns true for valid GeoJSON objects of each type.
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

    // Validates that static isValid returns false when the GeoJSON type does not match the expected type.
    @Test
    func staticIsValidWrongType() async throws {
        let geoJson: [String: Any] = ["type": "Point", "coordinates": [1.0, 2.0]]
        #expect(Point.isValid(geoJson: geoJson))
        #expect(LineString.isValid(geoJson: geoJson) == false)
    }

    // Validates that static isValid returns false for malformed or incomplete GeoJSON.
    @Test
    func staticIsValidInvalid() async throws {
        #expect(Point.isValid(geoJson: [:]) == false)
        #expect(Point.isValid(geoJson: ["coordinates": [1.0, 2.0]]) == false)
        #expect(Point.isValid(geoJson: ["type": "Invalid", "coordinates": [1.0, 2.0]]) == false)
        #expect(Point.isValid(geoJson: ["type": "Point"]) == false)
        #expect(Feature.isValid(geoJson: ["type": "Feature"]) == false)
    }

    // MARK: - validated property

    @Test
    func validatedReturnsSelfWhenValid() async throws {
        let point = Point(Coordinate3D(latitude: 1.0, longitude: 1.0))
        #expect(point.validated != nil)
        #expect(point.validated?.isValid == true)
    }

    @Test
    func validatedReturnsNilWhenInvalid() async throws {
        let empty = MultiPoint()
        #expect(empty.validated == nil)
    }

    @Test
    func validatedFeatureCollection() async throws {
        let valid = FeatureCollection([Feature(Point(Coordinate3D(latitude: 1.0, longitude: 1.0)))])
        #expect(valid.validated != nil)
        let invalid = FeatureCollection([Feature(LineString())])
        #expect(invalid.validated == nil)
    }

    // Validates that a valid Polygon in EPSG:3857 is recognized as valid.
    @Test
    // MARK: - Projections

    func validatable3857() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        #expect(polygon.isValid)
    }

    // Validates that a valid Polygon in EPSG:4978 is recognized as valid.
    @Test
    func validatable4978() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100_000.0, y: 100_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 100_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]]))
        #expect(polygon.isValid)
    }

}
