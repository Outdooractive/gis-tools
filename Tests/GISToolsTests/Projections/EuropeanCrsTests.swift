import Foundation
@testable import GISTools
import Testing

/// Tests for the pan-European and national CRS additions:
/// EPSG:3035 (LAEA Europe), EPSG:3034 (LCC Europe), EPSG:2154
/// (Lambert-93), EPSG:28992 (RD New) and the ETRS89/UTM zone belt
/// EPSG:25831–25837. All reference values are pyproj/PROJ ground-truth
/// fixtures computed from the EPSG parameterization.
struct EuropeanCrsTests {

    // MARK: - EPSG:3035 (LAEA Europe)

    @Test
    func laeaEurope() throws {
        let projection = try #require(Projection(srid: 3035))

        let fixtures: [(lat: Double, lon: Double, x: Double, y: Double)] = [
            (52.0, 10.0, 4_321_000.0, 3_210_000.0),
            (50.0, 8.0, 4_177_612.5211, 2_989_464.3148),
            (60.0, 15.0, 4_600_451.8747, 4_109_791.6599),
            (45.0, 25.0, 5_496_673.7667, 2_550_763.7938),
            (68.0, 25.0, 4_948_738.5124, 5_055_028.4167),
            (44.0, -5.0, 3_124_312.9333, 2_441_559.5791),
            (35.0, 25.0, 5_695_390.1838, 1_461_721.5538),
            (71.0, 35.0, 5_218_155.2075, 5_483_772.5606),
            (35.0, -10.0, 2_498_537.9996, 1_565_571.7660),
            (0.0, 10.0, 4_321_000.0, -2_360_911.2579),
            (10.0, -20.0, 878_363.8410, -731_245.0240),
            (-20.0, 10.0, 4_321_000.0, -4_257_767.5129),
            (-35.0, 15.0, 4_948_546.9661, -5_523_972.2732),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(
                latitude: fixture.lat,
                longitude: fixture.lon)
                .projected(to: projection)
            #expect(abs(projected.x - fixture.x) < 0.001, "(\(fixture.lat), \(fixture.lon))")
            #expect(abs(projected.y - fixture.y) < 0.001, "(\(fixture.lat), \(fixture.lon))")

            let roundTripped = projected.projected(to: .epsg4326)
            #expect(abs(roundTripped.latitude - fixture.lat) < 0.00000005)
            #expect(abs(roundTripped.longitude - fixture.lon) < 0.00000005)
        }
    }

    // Validates the auxlat-series authalic latitude conversion of the laea
    // inverse (Karney 2024, PROJ 9's `pj_auxlat_coeffs` for AUTHALIC ->
    // GEOGRAPHIC; issue #252): the series reaches full double precision,
    // so the round trips are sub-micrometer even at the farthest corners
    // of the EPSG:3035 domain — measured worst 0.6 um against pyproj/PROJ
    // 9.8 (the legacy 3-term Snyder series lost ~1.3 mm at Cairo's
    // distance). The reference values are pyproj round trips at PROJ's
    // own series precision.
    @Test
    func laeaAuxlatSeriesRoundTrips() throws {
        let projection = try #require(Projection(srid: 3035))

        // (lat, lon, x, y): pyproj/PROJ 9.8 forward values, full precision.
        let fixtures: [(lat: Double, lon: Double, x: Double, y: Double)] = [
            (52.0, 10.0, 4_321_000.000000000, 3_210_000.000000000),
            (50.0, 8.0, 4_177_612.521121177, 2_989_464.314838307),
            (60.0, 15.0, 4_600_451.874746643, 4_109_791.659876869),
            (30.04425, 31.23568, 6_378_371.692019264, 1_066_020.182666041),
            (28.29339, -16.62464, 1_708_968.279021428, 1_041_235.042661348),
            (68.0, 25.0, 4_948_738.512438167, 5_055_028.416669874),
            (71.0, 35.0, 5_218_155.207532424, 5_483_772.560573562),
            (35.0, -10.0, 2_498_537.999600947, 1_565_571.766022666),
            (0.0, 10.0, 4_321_000.000000000, -2_360_911.257874457),
            (10.0, -20.0, 878_363.840956741, -731_245.023989615),
            (-20.0, 10.0, 4_321_000.000000000, -4_257_767.512893031),
            (-35.0, 15.0, 4_948_546.966053404, -5_523_972.273195663),
            (73.0, 46.0, 5_449_803.807291598, 5_846_214.864111062),
            (27.0, -32.0, 272_241.736256454, 1_568_920.529576781),
            (72.9, -31.9, 3_027_279.092778229, 5_943_590.137293485),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(
                latitude: fixture.lat,
                longitude: fixture.lon)
                .projected(to: projection)
            #expect(abs(projected.x - fixture.x) < 0.000001, "(\(fixture.lat), \(fixture.lon))")
            #expect(abs(projected.y - fixture.y) < 0.000001, "(\(fixture.lat), \(fixture.lon))")

            let roundTripped = projected.projected(to: .epsg4326)
            #expect(abs(roundTripped.latitude - fixture.lat) < 0.000000001, "(\(fixture.lat), \(fixture.lon))")
            #expect(abs(roundTripped.longitude - fixture.lon) < 0.000000001, "(\(fixture.lat), \(fixture.lon))")
        }
    }

    // MARK: - EPSG:3034 (LCC Europe)

    @Test
    func lccEurope() throws {
        let projection = try #require(Projection(srid: 3034))

        let fixtures: [(lat: Double, lon: Double, x: Double, y: Double)] = [
            (52.0, 10.0, 4_000_000.0, 2_800_000.0),
            (50.0, 8.0, 3_861_540.1096, 2_587_014.5073),
            (60.0, 15.0, 4_272_945.4159, 3_673_790.2029),
            (45.0, 25.0, 5_139_888.5759, 2_163_393.1468),
            (68.0, 25.0, 4_634_734.4084, 4_617_630.1953),
            (44.0, -5.0, 2_838_351.5888, 2_057_675.3336),
            (71.0, 35.0, 4_930_501.0997, 5_056_840.3824),
            (10.0, -20.0, 150_523.7874, -1_253_545.9484),
            (-35.0, 15.0, 5_247_793.3514, -10_711_230.6237),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(
                latitude: fixture.lat,
                longitude: fixture.lon)
                .projected(to: projection)
            #expect(abs(projected.x - fixture.x) < 0.001, "(\(fixture.lat), \(fixture.lon))")
            #expect(abs(projected.y - fixture.y) < 0.001, "(\(fixture.lat), \(fixture.lon))")

            let roundTripped = projected.projected(to: .epsg4326)
            #expect(abs(roundTripped.latitude - fixture.lat) < 0.0000001)
            #expect(abs(roundTripped.longitude - fixture.lon) < 0.0000001)
        }
    }

    // MARK: - EPSG:2154 (Lambert-93)

    @Test
    func lambert93() throws {
        let projection = try #require(Projection(srid: 2154))

        let fixtures: [(lat: Double, lon: Double, x: Double, y: Double)] = [
            (52.0, 10.0, 1_181_938.1776, 7_233_428.2223),
            (50.0, 8.0, 1_058_573.5880, 7_000_411.4612),
            (60.0, 15.0, 1_387_231.6052, 8_168_353.5754),
            (45.0, 25.0, 2_411_244.7429, 6_673_360.9718),
            (68.0, 25.0, 1_689_382.1419, 9_196_882.7187),
            (44.0, -5.0, 59_447.5958, 6_354_809.3729),
            (35.0, 25.0, 2_718_589.1724, 5_598_931.6407),
            (71.0, 35.0, 1_972_367.6398, 9_689_736.7120),
            (35.0, -10.0, -502_924.1783, 5_415_141.4805),
            (0.0, 10.0, 1_740_647.0735, 947_513.3874),
            (10.0, -20.0, -2_274_599.6812, 2_733_821.2254),
            (-20.0, 10.0, 2_045_508.3828, -2_482_416.2953),
            (-35.0, 15.0, 3_549_695.8877, -5_951_393.1067),
            (53.36, -6.26, 80_888.7063, 7_400_509.8818),
            (59.91149, 10.75793, 1_146_285.1814, 8_127_816.7047),
            (41.89333, 12.48278, 1_486_817.0185, 6_135_367.1743),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(
                latitude: fixture.lat,
                longitude: fixture.lon)
                .projected(to: projection)
            #expect(abs(projected.x - fixture.x) < 0.001, "(\(fixture.lat), \(fixture.lon))")
            #expect(abs(projected.y - fixture.y) < 0.001, "(\(fixture.lat), \(fixture.lon))")

            let roundTripped = projected.projected(to: .epsg4326)
            #expect(abs(roundTripped.latitude - fixture.lat) < 0.00000001)
            #expect(abs(roundTripped.longitude - fixture.lon) < 0.00000001)
        }
    }

    // MARK: - EPSG:28992 (RD New)

    @Test
    func rdNew() throws {
        let projection = try #require(Projection(srid: 28992))

        let fixtures: [(lat: Double, lon: Double, x: Double, y: Double)] = [
            (52.0, 10.0, 471_621.7561, 455_796.0861),
            (50.0, 8.0, 342_349.9271, 226_555.8660),
            (60.0, 15.0, 692_497.8099, 1_375_342.3877),
            (45.0, 25.0, 1_696_651.7300, -133_411.6326),
            (68.0, 25.0, 980_378.1198, 2_364_282.3194),
            (44.0, -5.0, -680_725.9062, -388_570.9630),
            (71.0, 35.0, 1_226_691.4191, 2_834_439.6664),
            (0.0, 10.0, 791_009.8092, -5_737_352.0334),
            (-20.0, 10.0, 893_055.5316, -8_767_934.0271),
            (-35.0, 15.0, 1_827_258.0900, -11_574_575.2743),
            (53.36, -6.26, -618_044.6211, 659_837.7468),
            (59.91149, 10.75793, 456_597.5192, 1_339_602.7581),
            (41.89333, 12.48278, 748_070.2194, -653_755.1363),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(
                latitude: fixture.lat,
                longitude: fixture.lon)
                .projected(to: projection)
            #expect(abs(projected.x - fixture.x) < 0.1, "(\(fixture.lat), \(fixture.lon))")
            #expect(abs(projected.y - fixture.y) < 0.1, "(\(fixture.lat), \(fixture.lon))")

            let roundTripped = projected.projected(to: .epsg4326)
            #expect(abs(roundTripped.latitude - fixture.lat) < 0.000001)
            #expect(abs(roundTripped.longitude - fixture.lon) < 0.000001)
        }
    }

    // MARK: - EPSG:25831–25837 (ETRS89/UTM belt)

    @Test
    func etrs89UtmBelt() throws {
        let fixtures: [(srid: Int, lat: Double, lon: Double, x: Double, y: Double)] = [
            (25_831, 52.0, 6.0, 705_928.9189, 5_765_288.2547),
            (25_831, 59.0, 4.0, 557_450.9413, 6_540_481.7784),
            (25_832, 50.0, 8.0, 428_333.5525, 5_539_109.8152),
            (25_832, 59.0, 13.0, 729_721.5666, 6_546_929.7509),
            (25_833, 52.0, 12.0, 294_071.0811, 5_765_288.2547),
            (25_833, 59.0, 17.0, 614_893.6711, 6_541_771.1395),
            (25_834, 52.0, 18.0, 294_071.0811, 5_765_288.2547),
            (25_834, 62.0, 21.0, 500_000.0000, 6_874_180.1477),
            (25_835, 62.0, 26.0, 447_624.2003, 6_874_583.7270),
            (25_835, 71.0, 27.0, 500_000.0000, 7_877_396.7666),
            (25_836, 62.0, 32.0, 447_624.2003, 6_874_583.7270),
            (25_836, 71.0, 33.0, 500_000.0000, 7_877_396.7666),
            (25_837, 62.0, 38.0, 447_624.2003, 6_874_583.7270),
            (25_837, 71.0, 39.0, 500_000.0000, 7_877_396.7666),
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
            #expect(abs(roundTripped.latitude - fixture.lat) < 0.0000001)
            #expect(abs(roundTripped.longitude - fixture.lon) < 0.0000001)
        }
    }

    // MARK: - WKT matching

    @Test
    func wktMatching() throws {
        let laea = try #require(Projection(
            wkt: "PROJCS[\"ETRS89-extended / LAEA Europe\",GEOGCS[\"ETRS89\",...]]"))
        #expect(laea.srid == 3035)

        let lcc = try #require(Projection(
            wkt: "PROJCS[\"ETRS89-extended / LCC Europe\",GEOGCS[\"ETRS89\",...]]"))
        #expect(lcc.srid == 3034)

        let lambert93 = try #require(Projection(
            wkt: "PROJCS[\"RGF93 / Lambert-93\",GEOGCS[\"RGF93\",...]]"))
        #expect(lambert93.srid == 2154)

        let rd = try #require(Projection(
            wkt: "PROJCS[\"Amersfoort / RD New\",GEOGCS[\"Amersfoort\",...]]"))
        #expect(rd.srid == 28992)
    }

    @Test
    func etrs89UtmWktIdentification() throws {
        let etrs32 = try #require(Projection(
            wkt: "PROJCS[\"ETRS89 / UTM zone 32N\",GEOGCS[\"ETRS89\",...]]"))
        #expect(etrs32.srid == 25_832)

        let esriVariant = try #require(Projection(
            wkt: "PROJCS[\"ETRS_1989_UTM_Zone_33N\",PROJECTION[\"Transverse_Mercator\"],..."))
        #expect(esriVariant.srid == 25_833)

        // Outside the defined belt: falls back to the WGS84 zones.
        let outside = try #require(Projection(
            wkt: "PROJCS[\"ETRS89 / UTM zone 38N\",GEOGCS[\"ETRS89\",...]]"))
        #expect(outside.srid == 32_638)

        // Southern hemisphere: no ETRS belt defined.
        let southern = try #require(Projection(
            wkt: "PROJCS[\"ETRS89 / UTM zone 32S\",GEOGCS[\"ETRS89\",...]]"))
        #expect(southern.srid == 32_732)

        // Without an ETRS token: standard WGS84 zone.
        let wgs = try #require(Projection(
            wkt: "PROJCS[\"WGS_1984_UTM_Zone_19N\",GEOGCS[\"WGS 84\",...]]"))
        #expect(wgs.srid == 32_619)
    }

    // MARK: - Datum metadata

    @Test
    func datumMetadata() {
        #expect(Projection.epsg3035.datum == .etrs89)
        #expect(Projection.epsg3034.datum == .etrs89)
        #expect(Projection.epsg2154.datum == .etrs89)   // RGF93 = ETRS89 at meter accuracy
        #expect(Projection.epsg28992.datum == .amersfoort)
        #expect(Projection.epsg28992.datum.ellipsoid == .bessel1841)
        #expect(Projection.epsg25832.datum == .etrs89)
        #expect(Projection.epsg25832.utmZone == 32)
        #expect(Projection.epsg25835.utmHemisphere == .north)
    }

}
