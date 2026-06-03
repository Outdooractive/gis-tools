import Foundation
@testable import GISTools
import Testing

struct CoordinateFormatTests {

    // MARK: - DMS string

    @Test
    func dmsString() async throws {
        let coord = try #require(Coordinate3D(dms: "40°26'46\" N 79°58'56\" W"))
        #expect(abs(coord.latitude - 40.44611) < 0.001)
        #expect(abs(coord.longitude - (-79.98222)) < 0.001)
    }

    @Test
    func dmsStringSpaceSeparated() async throws {
        let coord = try #require(Coordinate3D(dms: "40 26 46 N 79 58 56 W"))
        #expect(abs(coord.latitude - 40.44611) < 0.001)
        #expect(abs(coord.longitude - (-79.98222)) < 0.001)
    }

    @Test
    func dmsStringEast() async throws {
        let coord = try #require(Coordinate3D(dms: "51°30'26\" N 0°7'39\" E"))
        #expect(coord.latitude > 50)
        #expect(coord.longitude > 0)
    }

    @Test
    func dmsStringSouthWest() async throws {
        let coord = try #require(Coordinate3D(dms: "33°52'0\" S 151°12'0\" E"))
        #expect(coord.latitude < 0)
        #expect(coord.longitude > 0)
    }

    // MARK: - DMS components

    @Test
    func dmsComponents() async throws {
        let coord = try #require(Coordinate3D(
            latitudeDegrees: 40, latitudeMinutes: 26, latitudeSeconds: 46,
            latitudeDirection: "N",
            longitudeDegrees: 79, longitudeMinutes: 58, longitudeSeconds: 56,
            longitudeDirection: "W"))
        #expect(abs(coord.latitude - 40.44611) < 0.001)
        #expect(abs(coord.longitude - (-79.98222)) < 0.001)
    }

    // MARK: - UTM

    @Test
    func utmNorthern() async throws {
        // UTM zone 18N, roughly New York City area
        let coord = try #require(Coordinate3D(
            easting: 583_960.0, northing: 4_504_896.0,
            zone: 18, hemisphere: "N"))
        #expect(abs(coord.latitude - 40.68) < 0.2)
        #expect(abs(coord.longitude - (-74.0)) < 0.5)
    }

    @Test
    func utmSouthern() async throws {
        // UTM zone 56S, roughly Sydney area
        let coord = try #require(Coordinate3D(
            easting: 334_895.0, northing: 6_253_780.0,
            zone: 56, hemisphere: "S"))
        #expect(coord.latitude < -30)
        #expect(coord.longitude > 150)
    }

    @Test
    func utmInvalidZone() async throws {
        #expect(Coordinate3D(
            easting: 500_000, northing: 4_500_000,
            zone: 99, hemisphere: "N") == nil)
    }

}
