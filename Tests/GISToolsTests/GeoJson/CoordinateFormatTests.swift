import Foundation
@testable import GISTools
import Testing

struct CoordinateFormatTests {

    // MARK: - DMS string

    // Validates parsing a DMS string with degree/minute/second symbols into a Coordinate3D.
    @Test
    func dmsString() async throws {
        let coord = try #require(Coordinate3D(dms: "40°26'46\" N 79°58'56\" W"))
        let expectedLatitude = 40.0 + 26.0 / 60.0 + 46.0 / 3600.0
        let expectedLongitude = -(79.0 + 58.0 / 60.0 + 56.0 / 3600.0)

        #expect(abs(coord.latitude - expectedLatitude) < GISTool.equalityDelta)
        #expect(abs(coord.longitude - expectedLongitude) < GISTool.equalityDelta)
    }

    // Validates parsing a DMS string with space-separated values into a Coordinate3D.
    @Test
    func dmsStringSpaceSeparated() async throws {
        let coord = try #require(Coordinate3D(dms: "40 26 46 N 79 58 56 W"))
        let expectedLatitude = 40.0 + 26.0 / 60.0 + 46.0 / 3600.0
        let expectedLongitude = -(79.0 + 58.0 / 60.0 + 56.0 / 3600.0)

        #expect(abs(coord.latitude - expectedLatitude) < GISTool.equalityDelta)
        #expect(abs(coord.longitude - expectedLongitude) < GISTool.equalityDelta)
    }

    // Validates parsing a DMS string with Eastern hemisphere longitude into a Coordinate3D.
    @Test
    func dmsStringEast() async throws {
        let coord = try #require(Coordinate3D(dms: "51°30'26\" N 0°7'39\" E"))
        let expectedLatitude = 51.0 + 30.0 / 60.0 + 26.0 / 3600.0
        let expectedLongitude = 7.0 / 60.0 + 39.0 / 3600.0

        #expect(abs(coord.latitude - expectedLatitude) < GISTool.equalityDelta)
        #expect(abs(coord.longitude - expectedLongitude) < GISTool.equalityDelta)
    }

    // Validates parsing a DMS string with Southern and Eastern hemispheres into a Coordinate3D.
    @Test
    func dmsStringSouthWest() async throws {
        let coord = try #require(Coordinate3D(dms: "33°52'0\" S 151°12'0\" E"))
        let expectedLatitude = -(33.0 + 52.0 / 60.0)
        let expectedLongitude = 151.0 + 12.0 / 60.0

        #expect(abs(coord.latitude - expectedLatitude) < GISTool.equalityDelta)
        #expect(abs(coord.longitude - expectedLongitude) < GISTool.equalityDelta)
    }

    // MARK: - DMS components

    // Validates creating a Coordinate3D from individual DMS degree/minute/second components.
    @Test
    func dmsComponents() async throws {
        let coord = try #require(Coordinate3D(
            latitudeDegrees: 40, latitudeMinutes: 26, latitudeSeconds: 46,
            latitudeDirection: "N",
            longitudeDegrees: 79, longitudeMinutes: 58, longitudeSeconds: 56,
            longitudeDirection: "W"))
        let expectedLatitude = 40.0 + 26.0 / 60.0 + 46.0 / 3600.0
        let expectedLongitude = -(79.0 + 58.0 / 60.0 + 56.0 / 3600.0)

        #expect(abs(coord.latitude - expectedLatitude) < GISTool.equalityDelta)
        #expect(abs(coord.longitude - expectedLongitude) < GISTool.equalityDelta)
    }

    // MARK: - UTM

    // Validates converting a UTM coordinate in the northern hemisphere to a Coordinate3D.
    @Test
    func utmNorthern() async throws {
        // UTM zone 18N, roughly New York City area
        let coord = try #require(Coordinate3D(
            easting: 583_960.0, northing: 4_504_896.0,
            zone: 18, hemisphere: "N"))
        #expect(abs(coord.latitude - 40.69068691113357) < 0.000001)
        #expect(abs(coord.longitude - (-74.00632127165716)) < 0.000001)
    }

    // Validates converting a UTM coordinate in the southern hemisphere to a Coordinate3D.
    @Test
    func utmSouthern() async throws {
        // UTM zone 56S, roughly Sydney area
        let coord = try #require(Coordinate3D(
            easting: 334_895.0, northing: 6_253_780.0,
            zone: 56, hemisphere: "S"))
        #expect(abs(coord.latitude - (-33.843355905446565)) < 0.000001)
        #expect(abs(coord.longitude - 151.2155194510673) < 0.000001)
    }

    // Validates that UTM conversion returns nil for an invalid zone number.
    @Test
    func utmInvalidZone() async throws {
        #expect(Coordinate3D(
            easting: 500_000, northing: 4_500_000,
            zone: 99, hemisphere: "N") == nil)
    }

}
