import Foundation
@testable import GISTools
import Testing

/// Tests for the German and Austrian Gauss-Krüger zone belts: DHDN /
/// Gauss-Krüger (EPSG:31466–31469) and MGI / Gauss-Krüger (EPSG:31255–31259).
///
/// All reference values are pyproj/PROJ 9.8.1 ground-truth fixtures computed
/// from the EPSG parameterization (Bessel 1841 transverse Mercator with the
/// published Helmert datum transformations — "DHDN to WGS 84 (2)", stated
/// accuracy ~3 m, and "MGI to WGS 84 (2)", ~1.5 m).
struct GaussKruegerTests {

    // MARK: - SRID mapping

    /// Validates that every zone SRID resolves to a registered definition
    /// with the expected zone metadata.
    @Test
    func sridMapping() throws {
        // DHDN: zones 2-5 = EPSG:31466-31469.
        for zone in 2 ... 5 {
            let projection = try #require(Projection(srid: 31464 + zone))
            let definition = try #require(DhdnGkDefinition.definition(for: projection))
            #expect(definition.zone == zone)
            #expect(definition.centralMeridian == Double(zone * 3))
            #expect(definition.datum == .dhdn)
            #expect(definition.projection == projection)
        }

        // MGI: EPSG:31255-31259.
        for srid in 31255 ... 31259 {
            let projection = try #require(Projection(srid: srid))
            let definition = try #require(MgiGkDefinition.definition(for: projection))
            #expect(definition.srid == srid)
            #expect(definition.datum == .mgi)
            #expect(definition.projection == projection)
        }

        // Specific central meridians and false eastings of the MGI belt.
        let m31 = try #require(MgiGkDefinition.definition(forSrid: 31257))
        #expect(abs(m31.centralMeridian - 10.333333333333) < 0.000000001)
        #expect(m31.falseEasting == 150_000.0)

        let m34 = try #require(MgiGkDefinition.definition(forSrid: 31258))
        #expect(abs(m34.centralMeridian - 13.333333333333) < 0.000000001)
        #expect(m34.falseEasting == 450_000.0)

        let eastVariant = try #require(MgiGkDefinition.definition(forSrid: 31259))
        #expect(abs(eastVariant.centralMeridian - 16.333333333333) < 0.000000001)
        #expect(eastVariant.falseEasting == 750_000.0)

        // The west variants share the central meridians but carry x0 = 0.
        let westM34 = try #require(MgiGkDefinition.definition(forSrid: 31255))
        #expect(abs(westM34.centralMeridian - m34.centralMeridian) < 0.0000000001)
        #expect(westM34.falseEasting == 0.0)

        // Out-of-belt SRIDs have no definitions.
        #expect(DhdnGkDefinition.definition(forSrid: 31465) == nil)
        #expect(DhdnGkDefinition.definition(forSrid: 31470) == nil)
        #expect(MgiGkDefinition.definition(forSrid: 31254) == nil)
        #expect(MgiGkDefinition.definition(forSrid: 31260) == nil)
        #expect(DhdnGkDefinition.definition(for: .epsg4326) == nil)
        #expect(MgiGkDefinition.definition(for: .epsg4326) == nil)
    }

    // MARK: - Registry coverage

    /// Validates that the projection constants resolve to registered
    /// definitions (registry coverage for the two belts).
    @Test
    func registryCoverage() throws {
        for srid in 31466 ... 31469 {
            let projection = try #require(Projection(srid: srid))
            #expect(projection.definition.projection == projection)
        }
        for srid in 31255 ... 31259 {
            let projection = try #require(Projection(srid: srid))
            #expect(projection.definition.projection == projection)
        }
    }

    // MARK: - Reference values

    /// Validates forward conversions against the PROJ fixtures (DHDN belt).
    @Test
    func dhdnReferenceValues() throws {
        let fixtures: [(srid: Int, lat: Double, lon: Double, x: Double, y: Double)] = [
            (31466, 51.2277, 6.7735, 2_554_073.170008, 5_677_262.991028),
            (31466, 50.9, 5.0, 2_429_694.310980, 5_640_997.518494),
            (31466, 52.0, 8.0, 2_637_390.373894, 5_764_794.896861),
            (31466, 47.99, 6.05, 2_503_776.810613, 5_316_877.223138),
            (31467, 48.1374, 11.5755, 3_691_756.262307, 5_336_476.209952),
            (31467, 47.99, 8.05, 3_429_168.818739, 5_317_311.687184),
            (31467, 51.0, 11.9, 3_703_628.948887, 5_655_652.662753),
            (31467, 53.55, 9.9, 3_559_723.189386, 5_935_768.276514),
            (31468, 52.52, 13.405, 4_595_471.684951, 5_821_692.367257),
            (31468, 51.0, 13.9, 4_633_475.660113, 5_653_364.081683),
            (31468, 53.5, 12.0, 4_500_102.628656, 5_929_824.189520),
            (31468, 50.0, 14.9, 4_708_008.527557, 5_544_439.218466),
            (31469, 51.0509, 13.7383, 5_411_666.384528, 5_658_060.385832),
            (31469, 50.9, 14.9, 5_493_101.668948, 5_640_520.933504),
            (31469, 52.0, 15.9, 5_561_945.036344, 5_763_281.886276),
            (31469, 51.5, 17.8, 5_694_552.001064, 5_710_988.334837),
        ]

        for fixture in fixtures {
            let projection = try #require(Projection(srid: fixture.srid))
            let projected = Coordinate3D(
                latitude: fixture.lat,
                longitude: fixture.lon)
                .projected(to: projection)
            #expect(abs(projected.x - fixture.x) < 0.001, "(\(fixture.srid), \(fixture.lat), \(fixture.lon))")
            #expect(abs(projected.y - fixture.y) < 0.001, "(\(fixture.srid), \(fixture.lat), \(fixture.lon))")

            let roundTripped = projected.projected(to: .epsg4326)
            #expect(abs(roundTripped.latitude - fixture.lat) < 0.0000001, "(\(fixture.srid), \(fixture.lat), \(fixture.lon))")
            #expect(abs(roundTripped.longitude - fixture.lon) < 0.0000001, "(\(fixture.srid), \(fixture.lat), \(fixture.lon))")
        }
    }

    /// Validates forward conversions against the PROJ fixtures (MGI belt).
    /// The west variants (EPSG:31255/31256) carry negative eastings inside
    /// their nominal sectors — the x₀ = 0 convention.
    @Test
    func mgiReferenceValues() throws {
        let fixtures: [(srid: Int, lat: Double, lon: Double, x: Double, y: Double)] = [
            (31255, 47.5, 9.5, -288_743.854967, 269_494.826416),
            (31255, 47.0, 12.9, -32904.067874, 206_860.539467),
            (31255, 48.0, 10.4, -218_834.325960, 322_123.083082),
            (31256, 47.5, 15.0, -100_371.491469, 263_210.878382),
            (31256, 47.0, 17.9, 119_238.215203, 207_944.443743),
            (31256, 48.2, 16.4, 5044.875344, 340_178.858740),
            (31257, 47.2692, 11.4041, 231_052.108202, 237_259.259640),
            (31257, 47.5, 9.4, 79703.943178, 262_790.958925),
            (31257, 46.8, 11.9, 269_619.907935, 185_731.810756),
            (31257, 47.3, 12.2, 291_197.273184, 241_815.493738),
            (31258, 47.8095, 13.0550, 429_209.781767, 296_806.097972),
            (31258, 47.5, 12.4, 379_734.967618, 262_781.185395),
            (31258, 48.0, 14.2, 514_733.104232, 318_310.497363),
            (31258, 47.0, 13.9, 493_152.246448, 206_922.492026),
            (31259, 48.2082, 16.3738, 753_096.804363, 341_089.369581),
            (31259, 47.5, 15.4, 679_765.547343, 262_770.209998),
            (31259, 48.7, 17.2, 813_886.643915, 396_136.848273),
            (31259, 47.9, 16.2, 740_118.568631, 306_828.318458),
        ]

        // The 2 mm tolerance: PROJ applies the MGI datum shift as a
        // geodetic-domain approximation ("approx" Helmert), the library as
        // the exact XYZ affine — the difference shows up at the ~1.9 mm
        // level for MGI's 5" rotations (invisible for DHDN's 0.2" ones).
        // Both are valid realizations of the ~1.5 m transformation.
        for fixture in fixtures {
            let projection = try #require(Projection(srid: fixture.srid))
            let projected = Coordinate3D(
                latitude: fixture.lat,
                longitude: fixture.lon)
                .projected(to: projection)
            #expect(abs(projected.x - fixture.x) < 0.002, "(\(fixture.srid), \(fixture.lat), \(fixture.lon))")
            #expect(abs(projected.y - fixture.y) < 0.002, "(\(fixture.srid), \(fixture.lat), \(fixture.lon))")

            let roundTripped = projected.projected(to: .epsg4326)
            #expect(abs(roundTripped.latitude - fixture.lat) < 0.0000001, "(\(fixture.srid), \(fixture.lat), \(fixture.lon))")
            #expect(abs(roundTripped.longitude - fixture.lon) < 0.0000001, "(\(fixture.srid), \(fixture.lat), \(fixture.lon))")
        }
    }

    // MARK: - Zone conventions

    /// Validates the DHDN zone-prefix convention: the easting's leading
    /// digit identifies the zone (a point near the central meridian of
    /// zone N has an easting starting with N).
    @Test
    func dhdnZonePrefix() throws {
        // A point on each zone's central meridian: the easting is the
        // x₀ plus the meridian convergence offset (a few meters).
        let samples: [(srid: Int, latitude: Double, longitude: Double)] = [
            (31466, 51.0, 6.0),
            (31467, 51.0, 9.0),
            (31468, 51.0, 12.0),
            (31469, 51.0, 15.0),
        ]
        for sample in samples {
            let projection = try #require(Projection(srid: sample.srid))
            let projected = Coordinate3D(latitude: sample.latitude, longitude: sample.longitude)
                .projected(to: projection)
            let zone = sample.srid - 31464
            #expect(
                projected.x > Double(zone * 1_000_000) && projected.x < Double(zone * 1_000_000 + 600_000),
                "zone \(zone): \(projected.x)"
            )
        }
    }

    /// Validates the MGI false-northing convention: the −5_000_000 m y₀
    /// keeps Austrian northings negative until the offset is added back.
    @Test
    func mgiFalseNorthing() {
        // Vienna in the east zone (EPSG:31259): northing ≈ 341_089 - the
        // 5-million offset is NOT added back in PROJ's parameterization
        // (y_0=-5000000 keeps the raw northing negative-shifted; the
        // published northing values are y - 5_000_000).
        let vienna = Coordinate3D(latitude: 48.2082, longitude: 16.3738)
            .projected(to: .epsg31259)
        #expect(vienna.y < 400_000.0)
        #expect(abs(vienna.y - 341_089.369581) < 0.002)
    }

    // MARK: - Datums

    /// Validates the datum metadata of the two belts.
    @Test
    func datumMetadata() {
        #expect(Projection.epsg31467.datum == .dhdn)
        #expect(Projection.epsg31467.datum.ellipsoid == .bessel1841)
        #expect(Projection.epsg31259.datum == .mgi)
        #expect(Projection.epsg31259.datum.ellipsoid == .bessel1841)
    }

    // MARK: - WKT matching

    /// Validates WKT identification of the two belts.
    @Test
    func wktMatching() throws {
        let dhdn = try #require(Projection(
            wkt: "PROJCS[\"DHDN / Gauss-Krueger zone 3\",GEOGCS[\"DHDN\",...]]"))
        #expect(dhdn.srid == 31467)

        let esriVariant = try #require(Projection(
            wkt: "PROJCS[\"Gauss_Kruger_DHDN_3\",PROJECTION[\"Transverse_Mercator\"],..."))
        #expect(esriVariant.srid == 31467)

        let mgi = try #require(Projection(
            wkt: "PROJCS[\"MGI / Gauss-Kruger Austria M34\",GEOGCS[\"MGI\",...]]"))
        #expect(mgi.srid == 31259)

        // The x₀-distinct variants via parameters (the "Central" variant
        // shares the M31 CM; only the false easting disambiguates).
        let central = try #require(Projection(
            wkt: "PROJCS[\"MGI / Austria GK Central\",...,PARAMETER[\"Central_Meridian\",13.3333333333333],PARAMETER[\"False_Easting\",0]]"))
        #expect(central.srid == 31255)

        let m31 = try #require(Projection(
            wkt: "PROJCS[\"MGI / Austria GK M31\",...,PARAMETER[\"False_Easting\",450000]]"))
        #expect(m31.srid == 31258)
    }

    // MARK: - Batch equivalence

    /// Validates that the batch API produces values identical to the
    /// single-coordinate path on a DHDN zone and an MGI zone.
    @Test
    func batchEquivalence() {
        let coordinates: [Coordinate3D] = [
            Coordinate3D(latitude: 50.11, longitude: 8.68),
            Coordinate3D(latitude: 47.2692, longitude: 11.4041),
            Coordinate3D(latitude: 48.2082, longitude: 16.3738),
        ]

        let geographic = coordinates.map { Coordinate3D(latitude: $0.latitude, longitude: $0.longitude) }

        let batchDhdn = geographic.projected(to: .epsg31468)
        for (index, batch) in batchDhdn.enumerated() {
            let single = geographic[index].projected(to: .epsg31468)
            #expect(abs(single.x - batch.x) < 0.000000001)
            #expect(abs(single.y - batch.y) < 0.000000001)
        }

        let batchMgi = geographic.projected(to: .epsg31259)
        for (index, batch) in batchMgi.enumerated() {
            let single = geographic[index].projected(to: .epsg31259)
            #expect(abs(single.x - batch.x) < 0.000000001)
            #expect(abs(single.y - batch.y) < 0.000000001)
        }
    }

}
