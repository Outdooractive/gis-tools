import Testing
import Foundation
@testable import GISTools
@testable import GISToolsGeoPackage

struct GeoPackageFeatureTests {

    private let tmpDir = URL(fileURLWithPath: "/tmp")

    private func testUrl(_ name: String = #function) -> URL {
        let cleanName = name.hasSuffix("()") ? String(name.dropLast(2)) : name
        return tmpDir.appendingPathComponent("gpkg_\(cleanName).gpkg")
    }

    @Test
    func roundTripPoint() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        let feature = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        let fc = FeatureCollection([feature])
        try await fc.writeGeopackage(to: dbUrl)

        let read = try await FeatureCollection(geopackage: dbUrl, table: "features")
        #expect(read.features.count == 1)
        let readGeo = read.features[0].geometry
        #expect(readGeo is Point)
        let point = readGeo as! Point
        #expect(abs(point.coordinate.latitude - 45.0) < 0.000001)
        #expect(abs(point.coordinate.longitude - 10.0) < 0.000001)
    }

    @Test
    func roundTripLineString() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let feature = Feature(ls)
        let fc = FeatureCollection([feature])
        try await fc.writeGeopackage(to: dbUrl)

        let read = try await FeatureCollection(geopackage: dbUrl, table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].geometry is LineString)
    }

    @Test
    func roundTripPolygon() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        let poly = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let feature = Feature(poly)
        let fc = FeatureCollection([feature])
        try await fc.writeGeopackage(to: dbUrl)

        let read = try await FeatureCollection(geopackage: dbUrl, table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].geometry is Polygon)
    }

    @Test
    func roundTripWithProperties() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        let feature = Feature(
            Point(Coordinate3D(latitude: 45.0, longitude: 10.0)),
            properties: ["name": "Test", "value": 42, "ratio": 3.14])
        let fc = FeatureCollection([feature])
        try await fc.writeGeopackage(to: dbUrl)

        let read = try await FeatureCollection(geopackage: dbUrl, table: "features")
        #expect(read.features.count == 1)
        let props = read.features[0].properties
        #expect(props["name"] as? String == "Test")
        #expect(props["value"] as? Int == 42)
        #expect(abs((props["ratio"] as? Double ?? 0.0) - 3.14) < 0.001)
    }

    @Test
    func emptyCollectionThrows() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        let fc = FeatureCollection([Feature]())
        do {
            try await fc.writeGeopackage(to: dbUrl)
            Issue.record("Expected GeoPackageError to be thrown")
        }
        catch is GeoPackageError {
            // Expected
        }
    }

    @Test
    func mixedGeometryTypesAccepted() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        let point = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        let poly = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let fc = FeatureCollection([point, Feature(poly)])
        try await fc.writeGeopackage(to: dbUrl)

        let read = try await FeatureCollection(geopackage: dbUrl, table: "features")
        #expect(read.features.count == 2)
    }

    @Test
    func nonExistentFileThrows() async throws {
        do {
            let _ = try await FeatureCollection(geopackage: URL(fileURLWithPath: "/tmp/does_not_exist.gpkg"))
            Issue.record("Expected GeoPackageError to be thrown")
        }
        catch is GeoPackageError {
            // Expected
        }
    }

    @Test
    func roundTripMultiPoint() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let feature = Feature(multiPoint)
        let fc = FeatureCollection([feature])
        try await fc.writeGeopackage(to: dbUrl)

        let read = try await FeatureCollection(geopackage: dbUrl, table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].geometry is MultiPoint)
    }

    @Test
    func naturalEarthCountries() async throws {
        let url = testFixture("ne_110m_admin_0_countries_from_geojson.gpkg")
        let fc = try await FeatureCollection(geopackage: url, table: "ne_110m_admin_0_countries")
        #expect(fc.features.count == 177)
        #expect(fc.features.first?.properties["name"] as? String == "Afghanistan")
    }

    @Test
    func naturalEarthFromGeoJSON() async throws {
        let url = testFixture("ne_110m_admin_0_countries_from_geojson.gpkg")
        let fc = try await FeatureCollection(geopackage: url, table: "ne_110m_admin_0_countries")
        #expect(fc.features.count == 177)
    }

    @Test
    func naturalEarthFromShapefile() async throws {
        let url = testFixture("ne_110m_admin_0_countries_from_shp.gpkg")
        let fc = try await FeatureCollection(geopackage: url, table: "ne_110m_admin_0_countries")
        #expect(fc.features.count == 177)
    }

}
