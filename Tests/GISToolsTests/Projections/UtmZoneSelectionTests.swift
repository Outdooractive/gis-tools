import Foundation
@testable import GISTools
import Testing

/// Tests for the UTM zone selection with the EPSG Norway/Svalbard
/// banding exceptions.
struct UtmZoneSelectionTests {

    // MARK: - Regular banding

    /// Standard 6° banding on both sides of the globe.
    @Test
    func regularZones() {
        let cases: [(latitude: Double, longitude: Double, zone: Int)] = [
            // Zone 1 starts at -180°.
            (0.0, -180.0, 1),
            (20.0, -179.9, 1),
            // Each zone boundary shifts the zone.
            (20.0, -174.0, 2),
            (20.0, -174.1, 1),
            (50.0, -3.0, 30),
            (10.0, 0.0, 31),
            (40.0, 12.0, 33),
            (10.0, 12.1, 33),
            (-20.0, 66.0, 42), // zone 42 starts at 66°E
            (50.0, 179.9, 60),
        ]
        for (latitude, longitude, zone) in cases {
            let utm = UtmDefinition.zone(for: Coordinate3D(latitude: latitude, longitude: longitude))
            #expect(utm?.zone == zone, "(\(latitude), \(longitude))")
        }
    }

    /// The hemisphere follows the equator, switching the EPSG SRID block.
    @Test
    func hemispheres() {
        let northern = UtmDefinition.zone(for: Coordinate3D(latitude: 0.0, longitude: 12.0))
        #expect(northern?.hemisphere == .north)
        #expect(northern?.projection.srid == 32_633)

        let southern = UtmDefinition.zone(for: Coordinate3D(latitude: -0.1, longitude: 12.0))
        #expect(southern?.hemisphere == .south)
        #expect(southern?.projection.srid == 32_733)
    }

    // MARK: - Norway exception

    /// Norway (56°N–64°N, 3°E–12°E) is covered by zone 32 ("32V").
    @Test
    func norwayException() {
        let cases: [(latitude: Double, longitude: Double, zone: Int)] = [
            // Oslo: standard banding would put 10.75°E into zone 31.
            (59.91149, 10.75793, 32),
            // Borders: the exception covers [56, 64) N and [3, 12) E.
            (56.0, 3.0, 32),
            (63.9, 11.9, 32),
            // Just outside the longitude window: back to standard banding.
            (58.0, 2.9, 31),
            (58.0, 12.0, 33),
            // Just outside the latitude window: back to standard banding
            // (5°E is zone 31 for all latitudes).
            (55.9, 5.0, 31),
            (64.0, 5.0, 31),
        ]
        for (latitude, longitude, zone) in cases {
            let utm = UtmDefinition.zone(for: Coordinate3D(latitude: latitude, longitude: longitude))
            #expect(utm?.zone == zone, "(\(latitude), \(longitude))")
        }
    }

    /// The Norwegian exception keeps the "32V" region inside the zone's
    /// expected easting range.
    @Test
    func norwayExceptionProducesPlausibleEastings() async throws {
        let cases: [(latitude: Double, longitude: Double)] = [
            (59.91149, 10.75793), // Oslo
            (57.5, 4.0),
            (63.0, 11.5),
        ]
        for (latitude, longitude) in cases {
            let utm = try #require(UtmDefinition.zone(for: Coordinate3D(latitude: latitude, longitude: longitude)))
            let projected = utm.forward(Coordinate3D(latitude: latitude, longitude: longitude))
            #expect(!projected.x.isNaN && !projected.y.isNaN)
            #expect(projected.x >= 100_000.0 && projected.x <= 900_000.0, "easting \(projected.x) for (\(latitude), \(longitude))")
        }
    }

    // MARK: - Svalbard exceptions

    /// The 72°N–84°N band uses 3°-wide zones 31/33/35/37 and the 9°-wide
    /// zone 32 ("31X/32X/33X/35X/37X").
    @Test
    func svalbardException() {
        let cases: [(latitude: Double, longitude: Double, zone: Int)] = [
            (78.0, 5.0, 31), // Longyearbyen's approximate field
            (72.0, 0.0, 31),
            (78.0, 9.0, 33),
            (78.0, 20.99, 33),
            (78.0, 21.0, 35),
            (78.0, 33.0, 37),
            (78.0, 41.9, 37),
            (78.0, 42.0, 38), // Directly east of the re-banded region
            (78.0, -5.0, 30), // Western edge of the exception window
            (83.9, 9.0, 33),
        ]
        for (latitude, longitude, zone) in cases {
            let utm = UtmDefinition.zone(for: Coordinate3D(latitude: latitude, longitude: longitude))
            #expect(utm?.zone == zone, "(\(latitude), \(longitude))")
        }
    }

    // MARK: - Antimeridian

    /// Both antimeridian representations select zone 1.
    @Test
    func antimeridian() {
        let plus = UtmDefinition.zone(for: Coordinate3D(latitude: 20.0, longitude: 180.0))
        #expect(plus?.zone == 1)
        #expect(plus?.hemisphere == .north)

        let minus = UtmDefinition.zone(for: Coordinate3D(latitude: 20.0, longitude: -180.0))
        #expect(minus?.zone == 1)
        #expect(minus?.hemisphere == .north)

        // Slightly wrapped values beyond ±180 normalize to their
        // canonical equivalents (−190° ≡ 170°E).
        let wrapped = UtmDefinition.zone(for: Coordinate3D(latitude: 20.0, longitude: 540.0))
        #expect(wrapped?.zone == 1)

        let wrappedNegative = UtmDefinition.zone(for: Coordinate3D(latitude: 20.0, longitude: -190.0))
        #expect(wrappedNegative?.zone == 59)

        let wrappedPositive = UtmDefinition.zone(for: Coordinate3D(latitude: 20.0, longitude: 250.0))
        #expect(wrappedPositive?.zone == 12) // ≡ −110°E
    }

    // MARK: - Outside the UTM grid

    /// Polar latitude ranges lie in the Universal Polar Stereographic
    /// regions outside the UTM grid.
    @Test
    func polarRegionsReturnNil() {
        #expect(UtmDefinition.zone(for: Coordinate3D(latitude: 84.1, longitude: 10.0)) == nil)
        #expect(UtmDefinition.zone(for: Coordinate3D(latitude: 90.0, longitude: 0.0)) == nil)
        #expect(UtmDefinition.zone(for: Coordinate3D(latitude: -80.1, longitude: 10.0)) == nil)
        #expect(UtmDefinition.zone(for: Coordinate3D(latitude: -90.0, longitude: 0.0)) == nil)

        // The exact limits still resolve.
        #expect(UtmDefinition.zone(for: Coordinate3D(latitude: 84.0, longitude: 5.0))?.zone == 31)
        #expect(UtmDefinition.zone(for: Coordinate3D(latitude: -80.0, longitude: 5.0))?.zone == 31)
    }

    // MARK: - Projection helper

    /// The `Projection`-level helper returns the registered projection.
    @Test
    func projectionHelper() throws {
        let oslo = Coordinate3D(latitude: 59.91149, longitude: 10.75793)
        let projection = try #require(Projection.utmZone(for: oslo))
        #expect(projection.srid == 32_632)
        #expect(projection.utmZone == 32)

        let dublin = Coordinate3D(latitude: 53.3, longitude: -8.0)
        let dublinProjection = try #require(Projection.utmZone(for: dublin))
        #expect(dublinProjection.srid == 32_629)
        #expect(dublinProjection.utmHemisphere == .north)

        let polar = Coordinate3D(latitude: 85.0, longitude: 14.0)
        #expect(Projection.utmZone(for: polar) == nil)
    }

    /// The selected zone round-trips every test point: converting forward
    /// and back reproduces the input.
    @Test
    func roundTrip() async throws {
        let sample: [(latitude: Double, longitude: Double)] = [
            (52.37233, 4.90497), // Amsterdam
            (-22.91157, -43.18266), // Rio de Janeiro
            (78.22636, 15.63067), // Longyearbyen (33X)
            (59.91149, 10.75793), // Oslo (32V exception)
            (30.04425, 31.23568), // Cairo
            (-33.86849, 151.19509), // Sydney
        ]

        for (latitude, longitude) in sample {
            let utm = try #require(UtmDefinition.zone(for: Coordinate3D(latitude: latitude, longitude: longitude)))
            let forward = utm.forward(Coordinate3D(latitude: latitude, longitude: longitude))
            let back = utm.inverse(forward)
            #expect(abs(back.longitude - longitude) < 0.000001)
            #expect(abs(back.latitude - latitude) < 0.000001)
        }
    }

}
