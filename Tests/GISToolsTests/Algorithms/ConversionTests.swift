@testable import GISTools
import Testing

struct ConversionTests {

    // Validates meters per pixel at the equator halves correctly at each zoom level.
    @Test
    func metersPerPixelAtEquator() async throws {
        var mppAtZoomLevels: [Double] = Array(repeating: 0.0, count: 21)
        mppAtZoomLevels[0] = 156_543.03392804096

        for zoom in 1...20 {
            mppAtZoomLevels[zoom] = mppAtZoomLevels[zoom - 1] / 2.0

            #expect(abs(GISTool.metersPerPixel(atZoom: zoom) - mppAtZoomLevels[zoom]) < 0.00001)
        }
    }

    // Validates meters per pixel at 45 degrees latitude halves correctly at each zoom level.
    @Test
    func metersPerPixelAt45() async throws {
        var mppAtZoomLevels: [Double] = Array(repeating: 0.0, count: 21)
        mppAtZoomLevels[0] = 110_692.6408380335

        for zoom in 1...20 {
            mppAtZoomLevels[zoom] = mppAtZoomLevels[zoom - 1] / 2.0

            #expect(abs(GISTool.metersPerPixel(atZoom: zoom, latitude: 45.0) - mppAtZoomLevels[zoom]) < 0.00001)
        }
    }

    // Validates that meter-to-degree conversion at the equator matches the degrees(fromMeters:) method.
    @Test
    func metersAtLatitude() async throws {
        let meters = 10000.0
        let degreesLatitude1 = try #require(GISTool.convert(length: meters, from: .meters, to: .degrees))
        let degreesLatitude2 = GISTool.degrees(fromMeters: meters, atLatitude: 0.0).latitudeDegrees

        #expect(abs(degreesLatitude1 - degreesLatitude2) < 0.00000001)
    }

    // MARK: - unit factors

    // Validates the factor returned for each supported unit type.
    @Test
    func factorForUnit() async throws {
        #expect(GISTool.factor(for: .meters) == GISTool.earthRadius)
        #expect(GISTool.factor(for: .kilometers)! < GISTool.earthRadius)
        #expect(GISTool.factor(for: .miles)! < GISTool.earthRadius)
        #expect(GISTool.factor(for: .radians) == 1.0)
        #expect(GISTool.factor(for: .acres) == nil)
    }

    // Validates the units factor returned for each supported unit type.
    @Test
    func unitsFactorForUnit() async throws {
        #expect(GISTool.unitsFactor(for: .meters) == 1.0)
        #expect(GISTool.unitsFactor(for: .kilometers) == 0.001)
        #expect(abs(GISTool.unitsFactor(for: .feet)! - 3.28084) < 0.00001)
        #expect(GISTool.unitsFactor(for: .acres) == nil)
    }

    // Validates the area factor returned for each supported unit type.
    @Test
    func areaFactorForUnit() async throws {
        #expect(GISTool.areaFactor(for: .meters) == 1.0)
        #expect(GISTool.areaFactor(for: .kilometers) == 0.000001)
        #expect(GISTool.areaFactor(for: .acres) == 0.000247105)
        #expect(GISTool.areaFactor(for: .degrees) == nil)
    }

    // MARK: - length conversion

    // Validates length conversion between meters, kilometers, and miles, and rejects negative values.
    @Test
    func convertLength() async throws {
        // meters → kilometers
        let km = try #require(GISTool.convert(length: 1000.0, from: .meters, to: .kilometers))
        #expect(abs(km - 1.0) < 0.00001)

        // miles → meters
        let m = try #require(GISTool.convert(length: 1.0, from: .miles, to: .meters))
        #expect(abs(m - 1609.344) < 0.1)

        // negative → nil
        #expect(GISTool.convert(length: -1.0, from: .meters, to: .kilometers) == nil)
    }

    // Validates area conversion between square meters, square kilometers, and acres, and rejects negative values.
    @Test
    func convertArea() async throws {
        // sq meters → sq kilometers
        let sqKm = try #require(GISTool.convert(area: 1_000_000.0, from: .meters, to: .kilometers))
        #expect(abs(sqKm - 1.0) < 0.00001)

        // sq meters → acres
        let acres = try #require(GISTool.convert(area: 10000.0, from: .meters, to: .acres))
        #expect(abs(acres - 2.47105) < 0.001)

        // negative → nil
        #expect(GISTool.convert(area: -1.0, from: .meters, to: .kilometers) == nil)
    }

    // MARK: - convertToMeters

    // Validates conversion of various distance units to meters.
    @Test
    func convertToMeters() async throws {
        #expect(GISTool.convertToMeters(5.0, .kilometers) == 5000.0)
        #expect(GISTool.convertToMeters(1.0, .miles) == 1609.344)
        #expect(GISTool.convertToMeters(100.0, .centimeters) == 1.0)
        #expect(GISTool.convertToMeters(1000.0, .millimeters) == 1.0)
        #expect(GISTool.convertToMeters(1.0, .nauticalMiles) == 1852.0)
        #expect(GISTool.convertToMeters(1.0, .meters) == 1.0)
        #expect(GISTool.convertToMeters(1.0, .inches) > 0.0)
    }

    // MARK: - pixel to coordinate

    // Validates round-trip conversion from pixel coordinates to geographic coordinates at zoom level 0.
    @Test
    func coordinateFromPixel() async throws {
        // Validate round-trip: pixel → coordinate → pixel (roughly)
        let coord = GISTool.coordinate(fromPixelX: 0.0, pixelY: 0.0, zoom: 0)
        #expect(abs(coord.latitude) > 0)
        #expect(abs(coord.longitude) > 0)
    }

    // MARK: - meters to degrees

    // Validates that 111,325 meters at the equator converts to approximately 1 degree of latitude and longitude.
    @Test
    func degreesFromMeters() async throws {
        let result = GISTool.degrees(fromMeters: 111_325.0, atLatitude: 0.0)
        #expect(abs(result.latitudeDegrees - 1.0) < 0.01)
        #expect(abs(result.longitudeDegrees - 1.0) < 0.01)
    }

    // Validates longitude degrees expand near the pole due to meridian convergence.
    @Test
    func degreesFromMetersAtPole() async throws {
        let result = GISTool.degrees(fromMeters: 111_325.0, atLatitude: 85.0)
        // At 85°, longitude degrees should be much larger (meridians converge)
        #expect(abs(result.latitudeDegrees - 1.0) < 0.01)
        #expect(result.longitudeDegrees > 5.0) // much larger than latitude
    }

    // Validates the Coordinate3D instance method for converting meters to degrees at the origin.
    @Test
    func coordinateDegreesFromMeters() async throws {
        let coord = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let result = coord.degrees(fromMeters: 111_325.0)
        #expect(abs(result.latitudeDegrees - 1.0) < 0.01)
        #expect(abs(result.longitudeDegrees - 1.0) < 0.01)
    }

    // Validates projecting a coordinate from EPSG:4326 to EPSG:3857 and back.
    @Test
    func conversion3857() async throws {
        let original = Coordinate3D(latitude: 48.8566, longitude: 2.3522)
        let projected = original.projected(to: .epsg3857)
        #expect(projected.projection == .epsg3857)
        #expect(abs(projected.x) > 0)
        #expect(abs(projected.y) > 0)

        let roundtrip = projected.projected(to: .epsg4326)
        #expect(abs(roundtrip.latitude - original.latitude) < 0.0001)
        #expect(abs(roundtrip.longitude - original.longitude) < 0.0001)
    }

}
