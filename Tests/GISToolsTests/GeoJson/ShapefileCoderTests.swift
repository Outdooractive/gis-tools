import Foundation
import Testing
@testable import GISTools

#if EnableShapefileSupport

struct ShapefileCoderTests {

    private func tempShapefileURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("shp_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("test")
    }

    private func cleanup(_ url: URL) {
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: dir)
    }

    private func roundTrip(_ features: [Feature]) throws -> FeatureCollection {
        let original = FeatureCollection(features)
        let url = tempShapefileURL()
        defer { cleanup(url) }

        try original.writeShapefile(to: url)
        guard let loaded = FeatureCollection(shapefile: url) else {
            throw ShapefileCoder.ShapefileCoderError.ioError("Failed to read back shapefile")
        }

        return loaded
    }

    /// Validates round-trip of a Point with a single Boolean property.
    @Test
    func booleanPropertyRoundTrip() async throws {
        var trueFeature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        trueFeature.properties = ["flag": true]

        var falseFeature = Feature(Point(Coordinate3D(latitude: 1.0, longitude: 0.0)))
        falseFeature.properties = ["flag": false]

        let loaded = try roundTrip([trueFeature, falseFeature])
        #expect(loaded.features.count == 2)
        #expect(loaded.features[0].properties["flag"] as? Bool == true)
        #expect(loaded.features[1].properties["flag"] as? Bool == false)
    }

    /// Validates round-trip of an empty FeatureCollection.
    @Test
    func emptyCollection() async throws {
        let original = FeatureCollection()
        let url = tempShapefileURL()
        defer { cleanup(url) }

        try original.writeShapefile(to: url)
        let loaded = try #require(FeatureCollection(shapefile: url))
        #expect(loaded.features.isEmpty)
    }

    /// Validates that an invalid .shp file returns nil.
    @Test
    func invalidFile() async throws {
        let url = tempShapefileURL()
        defer { cleanup(url) }

        let shpURL = url.appendingPathExtension("shp")
        try Data("not a shapefile".utf8).write(to: shpURL)

        let dbfURL = url.appendingPathExtension("dbf")
        try Data("not a dbf".utf8).write(to: dbfURL)

        let loaded = FeatureCollection(shapefile: url)
        #expect(loaded == nil)
    }

    /// Validates round-trip of a Point with String, Int, Double, and Bool properties.
    @Test
    func multiplePropertyTypes() async throws {
        var feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        feature.properties = [
            "str": "hello",
            "num": 42,
            "dec": 3.14,
            "yes": true,
        ]

        let loaded = try roundTrip([feature])
        let props = loaded.features[0].properties
        #expect(props["str"] as? String == "hello")
        #expect(props["num"] as? Int == 42)
        #expect(props["dec"] as? Double == 3.14)
        #expect(props["yes"] as? Bool == true)
    }

    /// Validates .prj file writing for EPSG:3857.
    @Test
    func projection3857() async throws {
        let feature = Feature(Point(Coordinate3D(x: 1_000_000.0, y: 2_000_000.0)))
        let original = FeatureCollection([feature])

        let url = tempShapefileURL()
        defer { cleanup(url) }

        try original.writeShapefile(to: url)

        let prjURL = url.appendingPathExtension("prj")
        #expect(FileManager.default.fileExists(atPath: prjURL.path))
    }

    /// Validates round-trip of a Point coordinate (no Z/M).
    @Test
    func pointCoordinateRoundTrip() async throws {
        let coord = Coordinate3D(latitude: 48.1, longitude: 16.3)
        let feature = Feature(Point(coord))

        let loaded = try roundTrip([feature])
        let loadedPoint = loaded.features[0].geometry as! Point
        #expect(abs(loadedPoint.coordinate.latitude - 48.1) < 1e-6)
        #expect(abs(loadedPoint.coordinate.longitude - 16.3) < 1e-6)
    }

    /// Validates round-trip of a Point with altitude (PointZ).
    @Test
    func pointZRoundTrip() async throws {
        let coord = Coordinate3D(latitude: 48.1, longitude: 16.3, altitude: 200.0)
        let feature = Feature(Point(coord))

        let loaded = try roundTrip([feature])
        let loadedPoint = loaded.features[0].geometry as! Point
        #expect(abs(loadedPoint.coordinate.latitude - 48.1) < 1e-6)
        #expect(abs(loadedPoint.coordinate.longitude - 16.3) < 1e-6)
        #expect(abs((loadedPoint.coordinate.altitude ?? 0) - 200.0) < 0.01)
    }

    /// Validates multiple Point features round-trip correctly.
    @Test
    func multipleFeatures() async throws {
        var features: [Feature] = []
        for i in 0..<10 {
            var f = Feature(Point(Coordinate3D(latitude: Double(i), longitude: Double(i * 2))))
            f.properties = ["index": i]
            features.append(f)
        }

        let loaded = try roundTrip(features)
        #expect(loaded.features.count == 10)
    }

    /// Validates reading the Natural Earth populated places shapefile.
    @Test
    func naturalEarthPopulatedPlaces() async throws {
        let url = TestData.shapefileUrl(package: "Shapefiles", name: "ne_10m_populated_places_simple")
        let fc = try ShapefileCoder.read(from: url)
        #expect(fc.features.count == 7342)
        #expect(fc.projection == .epsg4326)

        let first = fc.features[0]
        let firstPoint = try #require(first.geometry as? Point)
        #expect(abs(firstPoint.coordinate.latitude - (-34.5)) < 1.0)
        #expect(abs(firstPoint.coordinate.longitude - (-57.8)) < 1.0)
        #expect(first.properties["scalerank"] != nil)
        #expect(first.properties["name"] != nil)
        #expect(first.properties["featurecla"] != nil)

        let last = fc.features.last!
        let lastPoint = try #require(last.geometry as? Point)
        #expect(abs(lastPoint.coordinate.latitude - 22.3) < 1.0)
        #expect(abs(lastPoint.coordinate.longitude - 114.2) < 1.0)

        if let vienna = fc.features.first(where: {
            ($0.properties["name"] as? String) == "Vienna"
        }) {
            let viennaPoint = try #require(vienna.geometry as? Point)
            #expect(abs(viennaPoint.coordinate.latitude - 48.2) < 0.5)
            #expect(abs(viennaPoint.coordinate.longitude - 16.37) < 0.5)
            #expect(vienna.properties["pop_max"] != nil)
        }

        let allTypes = Set(fc.features.compactMap { $0.properties["featurecla"] as? String })
        #expect(allTypes.contains("Admin-0 capital"))
        #expect(allTypes.contains("Populated place"))
    }

    /// Reads the Natural Earth shapefile and prints the first 10 features as a table.
    /// Disabled by default — enable explicitly to inspect data.
    @Test(.disabled("Enable manually to inspect shapefile data"))
    func dumpNaturalEarth() async throws {
        let url = TestData.shapefileUrl(package: "Shapefiles", name: "ne_10m_populated_places_simple")
        let fc = try ShapefileCoder.read(from: url)

        func pad(_ s: String, _ len: Int) -> String {
            if s.count >= len { return String(s.prefix(len)) }
            return s + String(repeating: " ", count: len - s.count)
        }

        print(String(repeating: "-", count: 120))
        print("  \(pad("Name", 30)) \(pad("Feature Class", 22)) \(pad("Lat", 10)) \(pad("Lon", 10)) \(pad("Pop Max", 12)) \(pad("Country", 20))")
        print(String(repeating: "-", count: 120))

        for i in 0..<min(10, fc.features.count) {
            let f = fc.features[i]
            let props = f.properties
            let name = pad((props["name"] as? String) ?? "", 30)
            let featurecla = pad((props["featurecla"] as? String) ?? "", 22)
            let coord = f.geometry.allCoordinates.first!
            let lat = pad(String(format: "%.4f", coord.latitude), 10)
            let lon = pad(String(format: "%.4f", coord.longitude), 10)
            let popStr: String
            if let pop = props["pop_max"] {
                popStr = pad("\(pop)", 12)
            }
            else {
                popStr = String(repeating: " ", count: 12)
            }
            let country = pad((props["adm0name"] as? String) ?? "", 20)

            print("  \(name) \(featurecla) \(lat) \(lon) \(popStr) \(country)")
        }

        print(String(repeating: "-", count: 120))
        print("Total features: \(fc.features.count)")
    }

    /// Reads the Natural Earth shapefile and writes it back to `<project-root>/ne_output.shp`.
    /// Disabled by default — enable to regenerate the test output for comparison.
    @Test(.disabled("Enable to regenerate output shapefile"))
    func regenerateNaturalEarth() async throws {
        let input = TestData.shapefileUrl(package: "Shapefiles", name: "ne_10m_populated_places_simple")
        let fc = try ShapefileCoder.read(from: input)

        let output = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("ne_output")

        try ShapefileCoder.write(fc, to: output)
        print("Wrote \(fc.features.count) features to \(output.path).shp")
    }

}

#endif
