import Foundation
@testable import GISTools
import Testing

/// Tests for the North American NAD83 CRSs: the geographic EPSG:4269, the
/// UTM belt EPSG:26901–26960, the CONUS/BC Albers (EPSG:5070/3005) and the
/// Canadian Lambert conic grids (EPSG:3347/3978).
///
/// All reference values are pyproj/PROJ 9.8.1 ground-truth fixtures computed
/// from the EPSG parameterization (GRS80; NAD83 treated as coincident with
/// WGS84 at meter accuracy, like ETRS89). The Albers inverse was validated
/// in Python against PROJ before porting (forward ~33 nm, round trips
/// ~3.7 µm over a 3,000-point sweep).
struct Nad83CrsTests {

    // MARK: - SRID mapping

    /// Validates the NAD83/UTM belt SRID mapping.
    @Test
    func utmSridMapping() throws {
        for zone in 1 ... 60 {
            let projection = try #require(Projection(srid: 26900 + zone))
            #expect(projection.srid == 26900 + zone)
            #expect(projection.datum == .nad83)
            #expect(projection.definition.projection == projection)
        }

        // Out-of-belt SRIDs.
        #expect(Projection(srid: 26900) == nil)
        #expect(Projection(srid: 26961) == nil)
    }

    // MARK: - Reference values

    /// Validates forward conversions against the PROJ fixtures (Albers and
    /// Lambert CRSs plus the UTM belt).
    @Test
    func referenceValues() throws {
        let fixtures: [(srid: Int, lat: Double, lon: Double, x: Double, y: Double)] = [
            // EPSG:4269 (identity: NAD83 == WGS84 at this accuracy).
            (4269, 40.71278, -74.00594, -74.005940, 40.712780),
            (4269, 49.2827, -123.1207, -123.120700, 49.282700),
            (4269, 38.9, -77.036, -77.036000, 38.900000),
            // EPSG:5070 (Conus Albers).
            (5070, 39.7392, -104.9903, -762_409.047764, 1_893_843.599649),
            (5070, 49.2827, -123.1207, -1_973_389.591462, 3_202_764.950548),
            (5070, 64.0, -147.0, -2_804_005.629137, 5_215_460.567545),
            (5070, 18.2, -66.5, 3_190_667.860791, -17398.725404),
            (5070, 71.0, -156.0, -2_876_127.660540, 5_995_486.858520),
            (5070, 45.5, -75.7, 1_574_570.284842, 2_670_140.117098),
            // EPSG:3005 (BC Albers).
            (3005, 39.7392, -104.9903, 2_814_593.621605, -304_409.328996),
            (3005, 49.2827, -123.1207, 1_209_619.210086, 478_302.919749),
            (3005, 64.0, -147.0, -28545.666728, 2_264_295.131313),
            (3005, 18.2, -66.5, 7_288_379.612351, -1765.072449),
            (3005, 71.0, -156.0, -138_211.868428, 3_106_128.754607),
            (3005, 45.5, -75.7, 4_635_662.156330, 1_403_991.566244),
            // EPSG:3347 (Statistics Canada Lambert).
            (3347, 39.7392, -104.9903, 5_031_184.115247, 498_893.865849),
            (3347, 49.2827, -123.1207, 4_018_834.405551, 2_007_337.190170),
            (3347, 64.0, -147.0, 3_900_033.566599, 4_130_133.746469),
            (3347, 18.2, -66.5, 9_468_395.499107, -1_673_072.422382),
            (3347, 71.0, -156.0, 4_289_353.004192, 4_878_598.327055),
            (3347, 45.5, -75.7, 7_468_799.299107, 1_199_160.910276),
            // EPSG:3978 (Canada Atlas Lambert).
            (3978, 39.7392, -104.9903, -892_419.792486, -980_874.203859),
            (3978, 49.2827, -123.1207, -1_977_819.537812, 475_889.534795),
            (3978, 64.0, -147.0, -2_201_006.096577, 2_590_260.982474),
            (3978, 18.2, -66.5, 3_646_359.833712, -2_931_710.416120),
            (3978, 71.0, -156.0, -1_849_014.514943, 3_356_988.299933),
            (3978, 45.5, -75.7, 1_507_756.066217, -161_424.653615),
            // EPSG:26910/26918 (NAD83 UTM belt).
            (26910, 49.2827, -123.1207, 491_221.770667, 5_458_889.979981),
            (26918, 40.71278, -74.00594, 583_964.465499, 4_507_348.835356),
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

    // MARK: - Round trips

    /// Round-trips the Albers CRSs across their domains: the auxlat-series
    /// inverse keeps the round trips at micrometer level (validated in
    /// Python against PROJ over a 3,000-point sweep).
    @Test
    func albersRoundTrips() {
        let latitudes: [Double] = [18.0, 30.0, 45.0, 60.0, 71.0, 84.0]
        let longitudes: [Double] = [-170.0, -150.0, -126.0, -96.0, -66.5, 0.0]

        for projection in [Projection.epsg5070, .epsg3005] {
            for latitude in latitudes {
                for longitude in longitudes {
                    let original = Coordinate3D(latitude: latitude, longitude: longitude)
                    let projected = original.projected(to: projection)
                    let back = projected.projected(to: .epsg4326)

                    #expect(abs(back.latitude - latitude) < 0.00000001, "\(projection.srid), \(latitude)/\(longitude)")
                    #expect(abs(back.longitude - longitude) < 0.00000001, "\(projection.srid), \(latitude)/\(longitude)")
                }
            }
        }
    }

    // MARK: - Datums

    /// Validates the datum metadata: NAD83 uses GRS80 and is treated as
    /// coincident with WGS84 (identity transformation).
    @Test
    func datumMetadata() {
        #expect(Projection.epsg4269.datum == .nad83)
        #expect(Projection.epsg4269.datum.ellipsoid == .grs80)
        #expect(Projection.epsg5070.datum == .nad83)
        #expect(Projection.epsg3005.datum == .nad83)
        #expect(Projection.epsg3347.datum == .nad83)
        #expect(Projection.epsg3978.datum == .nad83)
        #expect(Projection.epsg26910.datum == .nad83)
        #expect(Projection.epsg26918.kind == .planar)
        #expect(Projection.epsg4269.kind == .geographic)
    }

    // MARK: - WKT matching

    /// Validates WKT identification: NAD83 names resolve to the geographic
    /// CRS and the UTM belt, ESRI variants included.
    @Test
    func wktMatching() throws {
        let geographic = try #require(Projection(
            wkt: "GEOGCS[\"NAD83\",DATUM[\"North_American_Datum_1983\",...]]"))
        #expect(geographic.srid == 4269)

        let esriVariant = try #require(Projection(
            wkt: "GEOGCS[\"GCS_North_American_1983\",DATUM[\"D_North_American_1983\",...]]"))
        #expect(esriVariant.srid == 4269)

        let utm = try #require(Projection(
            wkt: "PROJCS[\"NAD83 / UTM zone 18N\",GEOGCS[\"NAD83\",...]]"))
        #expect(utm.srid == 26918)

        let esriUtm = try #require(Projection(
            wkt: "PROJCS[\"NAD_1983_UTM_Zone_10N\",PROJECTION[\"Transverse_Mercator\"],...]]"))
        #expect(esriUtm.srid == 26910)

        let albers = try #require(Projection(
            wkt: "PROJCS[\"NAD83 / Conus Albers\",PROJECTION[\"Albers_Conic_Equal_Area\"],...]]"))
        #expect(albers.srid == 5070)
    }

    // MARK: - Batch equivalence

    /// Validates that the batch API produces values identical to the
    /// single-coordinate path for the Albers and UTM CRSs.
    @Test
    func batchEquivalence() {
        let geographic: [Coordinate3D] = [
            Coordinate3D(latitude: 39.7392, longitude: -104.9903),
            Coordinate3D(latitude: 49.2827, longitude: -123.1207),
            Coordinate3D(latitude: 64.0, longitude: -147.0),
        ]

        for projection in [Projection.epsg5070, .epsg3005, .epsg3347, .epsg3978, .epsg26910] {
            let batch = geographic.projected(to: projection)
            for (index, batchCoordinate) in batch.enumerated() {
                let single = geographic[index].projected(to: projection)
                #expect(abs(single.x - batchCoordinate.x) < 0.000000001, "\(projection.srid)")
                #expect(abs(single.y - batchCoordinate.y) < 0.000000001, "\(projection.srid)")
            }
        }
    }

}
