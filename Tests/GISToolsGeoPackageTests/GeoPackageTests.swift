import Testing
import Foundation
@testable import GISTools
@testable import GISToolsGeoPackage

struct GeoPackageTests {

    private let tmpDir = URL(fileURLWithPath: "/tmp")

    private func testUrl(_ name: String = #function) -> URL {
        tmpDir.appendingPathComponent("gpkg_\(name).gpkg")
    }

    // Validates writing and reading a FeatureCollection with a Point geometry.
    @Test
    func roundTripPoint() async throws {
        let feature = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        let readGeo = read.features[0].geometry
        #expect(readGeo is Point)
        let point = readGeo as! Point
        #expect(abs(point.coordinate.latitude - 45.0) < 1e-6)
        #expect(abs(point.coordinate.longitude - 10.0) < 1e-6)
    }

    // Validates round-trip with a LineString.
    @Test
    func roundTripLineString() async throws {
        let ls = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])!
        let feature = Feature(ls)
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].geometry is LineString)
    }

    // Validates round-trip with a Polygon.
    @Test
    func roundTripPolygon() async throws {
        let poly = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let feature = Feature(poly)
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].geometry is Polygon)
    }

    // Validates round-trip with features that have properties.
    @Test
    func roundTripWithProperties() async throws {
        var feature = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        feature.properties["name"] = "Test Point"
        feature.properties["elevation"] = 1000.0
        feature.properties["id"] = 42
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].properties["name"] as? String == "Test Point")
        #expect(read.features[0].properties["elevation"] as? Double == 1000.0)
        #expect(read.features[0].properties["id"] as? Int == 42)
    }

    // Validates that writing an empty FeatureCollection throws an error.
    @Test
    func emptyCollectionThrows() async throws {
        let fc = FeatureCollection()
        #expect(throws: (any Error).self) {
            try fc.writeGeopackage(to: testUrl())
        }
    }

    // Validates that mixed geometry types throw an error.
    @Test
    func mixedGeometryTypesThrow() async throws {
        let p1 = Feature(Point(Coordinate3D(latitude: 45.0, longitude: 10.0)))
        let p2 = Feature(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])!)
        let fc = FeatureCollection([p1, p2])
        #expect(throws: (any Error).self) {
            try fc.writeGeopackage(to: testUrl())
        }
    }

    // Validates reading from a non-existent file throws.
    @Test
    func nonExistentFileThrows() async throws {
        #expect(throws: (any Error).self) {
            let _ = try FeatureCollection(geopackage: URL(fileURLWithPath: "/tmp/nonexistent.gpkg"), table: "features")
        }
    }

    // Validates round-trip with a MultiPoint.
    @Test
    func roundTripMultiPoint() async throws {
        let mp = MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])!
        let feature = Feature(mp)
        let fc = FeatureCollection([feature])
        try fc.writeGeopackage(to: testUrl())

        let read = try FeatureCollection(geopackage: testUrl(), table: "features")
        #expect(read.features.count == 1)
        #expect(read.features[0].geometry is MultiPoint)
    }

}
