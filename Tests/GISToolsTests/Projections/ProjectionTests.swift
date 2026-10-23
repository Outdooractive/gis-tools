import Foundation
@testable import GISTools
import Testing

struct ProjectionTests {

    /// Tests coordinate projection from EPSG:4326 to EPSG:3857, including coordinates crossing the 180th meridian.
    @Test
    func convertTo3857() async throws {
        let coordinate1 = Coordinate3D(latitude: 41.0, longitude: -71.0)
        let result1 = coordinate1.projected(to: .epsg3857)
        #expect(abs(result1.longitude - -7_903_683.846322424) < 0.000001)
        #expect(abs(result1.latitude - 5_012_341.663847514) < 0.000001)

        let coordinate1b = Coordinate3D(latitude: 35.522895, longitude: -97.552175)
        let result1b = coordinate1b.projected(to: .epsg3857)
        #expect(abs(result1b.longitude - -10_859_458.446776) < 0.000001)
        #expect(abs(result1b.latitude - 4_235_169.496066) < 0.000001)

        let coordinate2 = Coordinate3D(latitude: -23.563987128451217, longitude: -246.796875)
        let result2 = coordinate2.projected(to: .epsg3857)
        #expect(abs(result2.longitude - -27_473_302.454371188) < 0.000001)
        #expect(abs(result2.latitude - -2_700_367.3352587065) < 0.000001)

        let coordinate3 = Coordinate3D(latitude: -23.563987128451217, longitude: -246.796875)
        let result3 = coordinate3.normalized().projected(to: .epsg3857)
        #expect(abs(result3.longitude - 12_601_714.231207296) < 0.000001)
        #expect(abs(result3.latitude - -2_700_367.3352587065) < 0.000001)

        let coordinate4 = Coordinate3D(latitude: 11.350796722383672, longitude: 286.5234375)
        let result4 = coordinate4.projected(to: .epsg3857)
        #expect(abs(result4.longitude - 31_895_643.162838347) < 0.000001)
        #expect(abs(result4.latitude - 1_271_912.1506653326) < 0.000001)

        let coordinate5 = Coordinate3D(latitude: 11.350796722383672, longitude: 286.5234375)
        let result5 = coordinate5.normalized().projected(to: .epsg3857)
        #expect(abs(result5.longitude - -8_179_373.522740141) < 0.000001)
        #expect(abs(result5.latitude - 1_271_912.1506653326) < 0.000001)
    }

    /// Tests coordinate projection from EPSG:3857 to EPSG:4326, including coordinates crossing the 180th meridian.
    @Test
    func convertTo4326() async throws {
        let coordinate1 = Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514, projection: .epsg3857)
        let result1 = coordinate1.projected(to: .epsg4326)
        #expect(abs(result1.latitude - 41.0) < 0.000001)
        #expect(abs(result1.longitude - -71.0) < 0.000001)

        let coordinate1b = Coordinate3D(x: -10_859_458.446776, y: 4_235_169.496066, projection: .epsg3857)
        let result1b = coordinate1b.projected(to: .epsg4326)
        #expect(abs(result1b.latitude - 35.522895) < 0.000001)
        #expect(abs(result1b.longitude - -97.552175) < 0.000001)

        let coordinate2 = Coordinate3D(x: 12_601_714.231207296, y: -2_700_367.3352587065, projection: .epsg3857)
        let result2 = coordinate2.projected(to: .epsg4326)
        #expect(abs(result2.latitude - -23.563987128451217) < 0.000001)
        #expect(abs(result2.longitude - 113.203125) < 0.000001)

        let coordinate3 = Coordinate3D(x: -8_179_373.522740139, y: 1_271_912.1506653326, projection: .epsg3857)
        let result3 = coordinate3.projected(to: .epsg4326)
        #expect(abs(result3.latitude - 11.350796722383672) < 0.000001)
        #expect(abs(result3.longitude - -73.476562) < 0.000001)
    }

    /// Tests coordinate projection from EPSG:4326 to EPSG:4978 (ECEF), including round-trip and cross-projection chaining.
    @Test
    func convertTo4978() async throws {
        // Null Island → ECEF X = a, Y = 0, Z = 0
        let nullIsland = Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0)
        let nullEcef = nullIsland.projected(to: .epsg4978)
        #expect(abs(nullEcef.longitude - 6_378_137.0) < 0.001)
        #expect(abs(nullEcef.latitude) < 0.001)
        #expect(abs(nullEcef.altitude ?? 0.0) < 0.001)

        // Round-trip: 4326 → 4978 → 4326
        let coord1 = Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 0.0)
        let ecef1 = coord1.projected(to: .epsg4978)
        let back1 = ecef1.projected(to: .epsg4326)
        #expect(abs(back1.latitude - coord1.latitude) < 0.00000001)
        #expect(abs(back1.longitude - coord1.longitude) < 0.00000001)
        #expect(abs((back1.altitude ?? 0.0)) < 0.001)

        let coord2 = Coordinate3D(latitude: 35.522895, longitude: -97.552175, altitude: 0.0)
        let ecef2 = coord2.projected(to: .epsg4978)
        let back2 = ecef2.projected(to: .epsg4326)
        #expect(abs(back2.latitude - coord2.latitude) < 0.00000001)
        #expect(abs(back2.longitude - coord2.longitude) < 0.00000001)
        #expect(abs((back2.altitude ?? 0.0)) < 0.001)

        // Round-trip with altitude preserved
        let coord3 = Coordinate3D(latitude: -33.86, longitude: 151.21, altitude: 500.0)
        let ecef3 = coord3.projected(to: .epsg4978)
        let back3 = ecef3.projected(to: .epsg4326)
        #expect(abs(back3.latitude - coord3.latitude) < 0.00000001)
        #expect(abs(back3.longitude - coord3.longitude) < 0.00000001)
        #expect(abs((back3.altitude ?? 0.0) - 500.0) < 0.001)

        // EPSG:3857 → EPSG:4978 via chaining matches 4326 → 4978
        let merc = Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514, projection: .epsg3857)
        let via3857 = merc.projected(to: .epsg4978)
        let direct4326 = merc.projected(to: .epsg4326)
        let directEcef = direct4326.projected(to: .epsg4978)
        #expect(abs(via3857.longitude - directEcef.longitude) < 0.001)
        #expect(abs(via3857.latitude - directEcef.latitude) < 0.001)
        #expect(abs((via3857.altitude ?? 0.0) - (directEcef.altitude ?? 0.0)) < 0.001)
    }

    /// Tests coordinate projection from EPSG:4978 (ECEF) back to EPSG:4326 and EPSG:3857.
    @Test
    func convertFrom4978() async throws {
        // ECEF Null Island (a, 0, 0) → lat=0, lon=0
        let ecefNull = Coordinate3D(x: 6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978)
        let geoNull = ecefNull.projected(to: .epsg4326)
        #expect(abs(geoNull.latitude) < 0.0000000001)
        #expect(abs(geoNull.longitude) < 0.0000000001)

        // Round-trip: 4978 → 4326 → 4978
        let ecef1 = Coordinate3D(x: 4_000_000.0, y: 5_000_000.0, z: 3_000_000.0, projection: .epsg4978)
        let geo1 = ecef1.projected(to: .epsg4326)
        let back1 = geo1.projected(to: .epsg4978)
        #expect(abs(back1.longitude - ecef1.longitude) < 0.001)
        #expect(abs(back1.latitude - ecef1.latitude) < 0.001)
        #expect(abs((back1.altitude ?? 0.0) - (ecef1.altitude ?? 0)) < 0.001)

        // EPSG:4978 → EPSG:3857 via chaining matches 4978 → 4326 → 3857
        let merc = ecef1.projected(to: .epsg3857)
        let via4326 = ecef1.projected(to: .epsg4326).projected(to: .epsg3857)
        #expect(abs(merc.longitude - via4326.longitude) < 0.001)
        #expect(abs(merc.latitude - via4326.latitude) < 0.001)
    }

    /// Tests that near-geocenter ECEF coordinates project to valid latitudes
    /// in [-90, 90]. The iterative ECEF→geodetic solver can diverge for
    /// points near the geocenter (huge negative altitude), producing
    /// |latitude| > 90 without clamping.
    @Test
    func convertFrom4978NearOriginClampsLatitude() {
        let nearOriginPoints: [(x: Double, y: Double, z: Double)] = [
            (0.0, 0.0, 0.0),
            (1_000.0, 0.0, 0.0),
            (1_000.0, 1_000.0, 0.0),
            (0.0, 1_000.0, 0.0),
            (500.0, 500.0, 0.0),
        ]
        for (x, y, z) in nearOriginPoints {
            let geo = Coordinate3D(x: x, y: y, z: z, projection: .epsg4978).projected(to: .epsg4326)
            #expect(geo.latitude >= -90.0, "latitude \(geo.latitude) < -90 for ECEF (\(x), \(y), \(z))")
            #expect(geo.latitude <= 90.0, "latitude \(geo.latitude) > 90 for ECEF (\(x), \(y), \(z))")
        }
    }

    /// Validates that each projection case reports the correct SRID number.
    @Test
    func cases() async throws {
        #expect(Projection.noSRID.srid == 0)
        #expect(Projection.epsg3857.srid == 3857)
        #expect(Projection.epsg4326.srid == 4326)
        #expect(Projection.epsg4978.srid == 4978)
    }

    /// Validates initialization from supported SRID numbers.
    @Test
    func initFromSrid() async throws {
        #expect(Projection(srid: 0) == .noSRID)
        #expect(Projection(srid: 4326) == .epsg4326)
        #expect(Projection(srid: 3857) == .epsg3857)
        #expect(Projection(srid: 4978) == .epsg4978)
        #expect(Projection(srid: 3395) == .epsg3395)
        #expect(Projection(srid: 32662) == .epsg32662)
    }

    /// Validates initialization from known EPSG:3857 alias SRIDs.
    @Test
    func initFromSridAliases() async throws {
        #expect(Projection(srid: 102_100) == .epsg3857)
        #expect(Projection(srid: 102_113) == .epsg3857)
        #expect(Projection(srid: 900_913) == .epsg3857)
        #expect(Projection(srid: 3587) == .epsg3857)
        #expect(Projection(srid: 3785) == .epsg3857)
        #expect(Projection(srid: 41_001) == .epsg3857)
        #expect(Projection(srid: 54_004) == .epsg3857)
    }

    /// Validates that unsupported SRID numbers return `nil`.
    @Test
    func initFromUnsupportedSrid() async throws {
        #expect(Projection(srid: 1234) == nil)
        #expect(Projection(srid: -1) == nil)
    }

    /// Validates the human-readable description of each projection.
    @Test
    func description() async throws {
        #expect(Projection.noSRID.description == "No SRID")
        #expect(Projection.epsg3857.description == "EPSG:3857")
        #expect(Projection.epsg4326.description == "EPSG:4326")
        #expect(Projection.epsg4978.description == "EPSG:4978")
        #expect(Projection.epsg3395.description == "EPSG:3395")
        #expect(Projection.epsg32662.description == "EPSG:32662")
    }

    /// Validates the `srid` computed property returns the correct integer.
    @Test
    func sridProperty() async throws {
        #expect(Projection.noSRID.srid == 0)
        #expect(Projection.epsg3857.srid == 3857)
        #expect(Projection.epsg4326.srid == 4326)
        #expect(Projection.epsg4978.srid == 4978)
        #expect(Projection.epsg3395.srid == 3395)
        #expect(Projection.epsg32662.srid == 32662)
    }

    /// Validates equality and inequality between projections.
    @Test
    func equatable() async throws {
        #expect(Projection.epsg4326 == .epsg4326)
        #expect(Projection.epsg4326 != .epsg3857)
        #expect(Projection.noSRID != .epsg4326)
        #expect(Projection.epsg4978 != .epsg4326)
        #expect(Projection.epsg4978 == .epsg4978)
    }

    /// Validates round-trip JSON encoding and decoding for all projections.
    @Test
    func codableRoundTrip() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for projection: Projection in [.noSRID, .epsg3857, .epsg4326, .epsg4978] {
            let data = try encoder.encode(projection)
            let decoded = try decoder.decode(Projection.self, from: data)
            #expect(decoded == projection)
        }
    }

    /// Validates the raw JSON values for each projection's Codable representation.
    @Test
    func codableRawValues() async throws {
        let encoder = JSONEncoder()

        #expect(String(data: try encoder.encode(Projection.noSRID), encoding: .utf8) == "0")
        #expect(String(data: try encoder.encode(Projection.epsg3857), encoding: .utf8) == "3857")
        #expect(String(data: try encoder.encode(Projection.epsg4326), encoding: .utf8) == "4326")
        #expect(String(data: try encoder.encode(Projection.epsg4978), encoding: .utf8) == "4978")
    }

    /// Validates ``Projection.init(wkt:)`` with common ``.prj`` strings.
    @Test
    func initFromWkt() async throws {
        #expect(Projection(wkt: #"GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]]"#) == .epsg4326)
        #expect(Projection(wkt: #"GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]]"#) == .epsg4326)
        #expect(Projection(wkt: #"PROJCS["WGS 84 / Pseudo-Mercator",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]],PROJECTION["Mercator_1SP"],PARAMETER["central_meridian",0],PARAMETER["scale_factor",1],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1]]"#) == .epsg3857)
        #expect(Projection(wkt: #"GEOCCS["WGS 84 (geocentric)",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["metre",1]]"#) == .epsg4978)
        #expect(Projection(wkt: #"PROJCS["WGS 84 / World Mercator",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]],PROJECTION["Mercator_1SP"],PARAMETER["central_meridian",0],PARAMETER["scale_factor",1],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1]]"#) == .epsg3395)
        #expect(Projection(wkt: #"PROJCS["WGS 84 / Plate Carree",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]],PROJECTION["Equirectangular"],PARAMETER["central_meridian",0],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1]]"#) == .epsg32662)
        #expect(Projection(wkt: "unknown") == nil)
        #expect(Projection(wkt: "") == nil)
    }

    /// Validates the semantic category of each projection.
    @Test
    func kind() async throws {
        #expect(Projection.noSRID.kind == .undefined)
        #expect(Projection.epsg3857.kind == .planar)
        #expect(Projection.epsg4326.kind == .geographic)
        #expect(Projection.epsg4978.kind == .geocentric)
        #expect(Projection.epsg3395.kind == .planar)
        #expect(Projection.epsg32662.kind == .planar)
    }

    /// Validates the projection kind flag computed properties.
    @Test
    func kindFlags() async throws {
        #expect(Projection.epsg4326.isGeographic)
        #expect(!Projection.epsg3857.isGeographic)
        #expect(!Projection.epsg4978.isGeographic)
        #expect(!Projection.noSRID.isGeographic)
        #expect(!Projection.epsg3395.isGeographic)
        #expect(!Projection.epsg32662.isGeographic)

        #expect(Projection.epsg3857.isPlanar)
        #expect(!Projection.epsg4326.isPlanar)
        #expect(!Projection.epsg4978.isPlanar)
        #expect(!Projection.noSRID.isPlanar)
        #expect(Projection.epsg3395.isPlanar)
        #expect(Projection.epsg32662.isPlanar)

        #expect(Projection.epsg4978.isGeocentric)
        #expect(!Projection.epsg4326.isGeocentric)
        #expect(!Projection.epsg3857.isGeocentric)
        #expect(!Projection.noSRID.isGeocentric)
        #expect(!Projection.epsg3395.isGeocentric)
        #expect(!Projection.epsg32662.isGeocentric)

        #expect(Projection.epsg4326.hasSRID)
        #expect(Projection.epsg3857.hasSRID)
        #expect(Projection.epsg4978.hasSRID)
        #expect(!Projection.noSRID.hasSRID)
        #expect(Projection.epsg3395.hasSRID)
        #expect(Projection.epsg32662.hasSRID)
    }

    /// Validates the horizontal wraparound extent of each projection.
    @Test
    func wraparoundExtent() async throws {
        #expect(Projection.epsg4326.wraparoundExtent == 180.0)
        #expect(Projection.epsg3857.wraparoundExtent == GISTool.originShift)
        #expect(Projection.epsg4978.wraparoundExtent == nil)
        #expect(Projection.noSRID.wraparoundExtent == nil)
        #expect(Projection.epsg3395.wraparoundExtent == GISTool.originShift)
        #expect(Projection.epsg32662.wraparoundExtent == GISTool.originShift)
    }

    /// Validates meter-to-CRS-unit conversion.
    @Test
    func crsLengthFromMeters() async throws {
        #expect(Projection.epsg4326.crsLength(fromMeters: 111_325.0) == 1.0)
        #expect(abs(Projection.epsg4326.crsLength(fromMeters: 55_662.5) - 0.5) < 0.0000000001)
        #expect(Projection.epsg3857.crsLength(fromMeters: 1000.0) == 1000.0)
        #expect(Projection.epsg4978.crsLength(fromMeters: 1000.0) == 1000.0)
        #expect(Projection.noSRID.crsLength(fromMeters: 1000.0) == 1000.0)
    }

    /// Round-trips a coordinate through every projection pair; the result must
    /// match the original (within projection precision).
    @Test
    func roundTrips() async throws {
        let base = Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 250.0, m: 7.0)
        let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978, .epsg3395, .epsg32662]

        for source in projections {
            let start = base.projected(to: source)
            #expect(start.projection == source)

            for target in projections where source != target {
                let there = start.projected(to: target)
                #expect(there.projection == target)
                #expect(there.m == 7.0)

                let back = there.projected(to: source)
                #expect(back.projection == source)
                #expect(abs(back.latitude - start.latitude) < 0.000001)
                #expect(abs(back.longitude - start.longitude) < 0.000001)
                #expect(abs((back.altitude ?? 0.0) - (start.altitude ?? 0.0)) < 0.001)
            }
        }
    }

    /// Tests coordinate projection from EPSG:4326 to EPSG:3395 (ellipsoidal
    /// Mercator) and back. Reference values computed independently with the
    /// Snyder ellipsoidal Mercator formulas on the WGS84 ellipsoid.
    @Test
    func convertTo3395() async throws {
        let coordinate1 = Coordinate3D(latitude: 41.0, longitude: -71.0)
        let result1 = coordinate1.projected(to: .epsg3395)
        #expect(abs(result1.longitude - -7_903_683.846322423) < 0.000001)
        #expect(abs(result1.latitude - 4_984_302.519220173) < 0.000001)

        let coordinate2 = Coordinate3D(latitude: 35.522895, longitude: -97.552175)
        let result2 = coordinate2.projected(to: .epsg3395)
        #expect(abs(result2.longitude - -10_859_458.446776314) < 0.000001)
        #expect(abs(result2.latitude - 4_210_342.228773801) < 0.000001)

        // The equator is identical to EPSG:3857.
        let equator = Coordinate3D(latitude: 0.0, longitude: 23.5)
        let resultEquator = equator.projected(to: .epsg3395)
        let resultEquator3857 = equator.projected(to: .epsg3857)
        #expect(abs(resultEquator.longitude - resultEquator3857.longitude) < 0.0000000001)
        #expect(abs(resultEquator.latitude - resultEquator3857.latitude) < 0.0000000001)

        // Away from the equator, ellipsoidal y is smaller than spherical y
        // in the northern hemisphere.
        #expect(abs(result1.latitude) < abs(Coordinate3D(latitude: 41.0, longitude: -71.0).projected(to: .epsg3857).latitude))

        // Round trips, including near the projection's y extent.
        for latitude in [0.0, 41.0, -33.86, 80.0, -80.0] {
            let coordinate = Coordinate3D(latitude: latitude, longitude: -71.0, altitude: 10.0)
            let back = coordinate.projected(to: .epsg3395).projected(to: .epsg4326)
            #expect(abs(back.latitude - latitude) < 0.000001)
            #expect(abs(back.longitude - -71.0) < 0.000001)
            #expect(abs((back.altitude ?? 0.0) - 10.0) < 0.0000000001)
        }
    }

    /// Tests coordinate projection from EPSG:4326 to EPSG:32662 (Plate Carree)
    /// and back. EPSG:32662 is an equirectangular projection in meters:
    /// `x = a·λ`, `y = a·φ` with `a` the WGS84 semi-major axis.
    @Test
    func convertTo32662() async throws {
        let coordinate = Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 100.0, m: 3.0)
        let result = coordinate.projected(to: .epsg32662)
        // Reference values: PROJ `+proj=eqc +lat_ts=0 +datum=WGS84 +units=m`.
        #expect(abs(result.longitude - -7_903_683.846322424) < 0.000001)
        #expect(abs(result.latitude - 4_540_573.291229727) < 0.000001)
        #expect(result.altitude == 100.0)
        #expect(result.m == 3.0)

        let back = result.projected(to: .epsg4326)
        #expect(abs(back.longitude + 71.0) < 0.0000000001)
        #expect(abs(back.latitude - 41.0) < 0.0000000001)
        #expect(back.altitude == 100.0)
        #expect(back.m == 3.0)

        // Values outside the valid extent are copied as-is (no wrap/clamp on
        // plain conversion).
        let outOfRange = Coordinate3D(latitude: 41.0, longitude: 200.0).projected(to: .epsg32662)
        #expect(abs(outOfRange.longitude - 22_263_898.158654716) < 0.000001)
    }

    /// EPSG:3857 → EPSG:4978 (and back) is routed through the EPSG:4326 pivot
    /// and matches the chained manual conversion.
    @Test
    func pivotRouting3857To4978() async throws {
        let mercator = Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514, z: 100.0, m: 3.0, projection: .epsg3857)

        let ecef = mercator.projected(to: .epsg4978)
        let chained = mercator.projected(to: .epsg4326).projected(to: .epsg4978)
        #expect(abs(ecef.longitude - chained.longitude) < 0.0000000001)
        #expect(abs(ecef.latitude - chained.latitude) < 0.0000000001)
        #expect(abs((ecef.altitude ?? 0.0) - (chained.altitude ?? 0.0)) < 0.0000000001)
        #expect(ecef.m == 3.0)

        let back = ecef.projected(to: .epsg3857)
        #expect(abs(back.longitude - mercator.longitude) < 0.000001)
        #expect(abs(back.latitude - mercator.latitude) < 0.000001)
    }

    /// Pins the noSRID semantics:
    /// - Coordinates without an SRID are always copied verbatim, regardless
    ///   of the target projection: without a CRS there is nothing to
    ///   transform from.
    /// - Projecting to `.noSRID` copies values verbatim as well.
    /// - Per-axis helpers treat noSRID values as already being in the target.
    @Test
    func noSridSemantics() async throws {
        let coordinate = Coordinate3D(x: -71.0, y: 41.0, z: 50.0, m: 2.0, projection: .noSRID)

        // Verbatim copy into every target projection.
        for target: Projection in [.epsg4326, .epsg3857, .epsg4978] {
            let result = coordinate.projected(to: target)
            #expect(result.projection == target)
            #expect(result.longitude == -71.0)
            #expect(result.latitude == 41.0)
            #expect(result.altitude == 50.0)
            #expect(result.m == 2.0)
        }

        // Verbatim copy when dropping the SRID.
        let mercator = Coordinate3D(latitude: 41.0, longitude: -71.0).projected(to: .epsg3857)
        let dropped = mercator.projected(to: .noSRID)
        #expect(dropped.projection == .noSRID)
        #expect(dropped.longitude == mercator.longitude)
        #expect(dropped.latitude == mercator.latitude)
        #expect(dropped.altitude == mercator.altitude)
        #expect(dropped.m == mercator.m)

        // Per-axis helpers return the values unchanged for noSRID sources.
        #expect(coordinate.latitudeProjected(to: .epsg3857) == 41.0)
        #expect(coordinate.longitudeProjected(to: .epsg3857) == -71.0)
        #expect(coordinate.latitudeProjected(to: .epsg4978) == 41.0)
        #expect(coordinate.longitudeProjected(to: .epsg4978) == -71.0)
    }

    /// Per-axis helpers match the corresponding full projection for all
    /// non-noSRID projections.
    @Test
    func perAxisHelpersMatchProjection() async throws {
        let sources: [Coordinate3D] = [
            Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 10.0),
            Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514, z: 10.0, projection: .epsg3857),
            Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 0.0).projected(to: .epsg4978),
        ]
        let targets: [Projection] = [.epsg4326, .epsg3857, .epsg4978]

        for source in sources {
            for target in targets {
                let projected = source.projected(to: target)
                #expect(abs(source.latitudeProjected(to: target) - projected.latitude) < 0.0000000001)
                #expect(abs(source.longitudeProjected(to: target) - projected.longitude) < 0.0000000001)
            }
        }
    }

    /// Altitude and m values are preserved through projections where defined.
    @Test
    func altitudeAndMPreserved() async throws {
        let withAltitude = Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 300.0, m: 5.0)

        let mercator = withAltitude.projected(to: .epsg3857)
        #expect(mercator.altitude == 300.0)
        #expect(mercator.m == 5.0)

        // In EPSG:4978 the altitude becomes the ECEF z coordinate; m is preserved.
        let ecef = withAltitude.projected(to: .epsg4978)
        #expect(ecef.altitude != nil)
        #expect(ecef.m == 5.0)
        let back = ecef.projected(to: .epsg4326)
        #expect(abs((back.altitude ?? 0.0) - 300.0) < 0.001)

        // Without altitude, EPSG:3857 keeps nil and EPSG:4978 gains a computed z.
        let withoutAltitude = Coordinate3D(latitude: 41.0, longitude: -71.0)
        #expect(withoutAltitude.projected(to: .epsg3857).altitude == nil)
        #expect(withoutAltitude.projected(to: .epsg4978).altitude != nil)
    }

    /// Validates `clamped()` against the valid extent of each projection.
    @Test
    func clamped() async throws {
        // EPSG:4326: ±180 longitude, ±90 latitude.
        let geographic = Coordinate3D(latitude: 95.0, longitude: 200.0).clamped()
        #expect(geographic.latitude == 90.0)
        #expect(geographic.longitude == 180.0)

        // EPSG:3857: ±originShift on both axes.
        let shift = GISTool.originShift
        let planar = Coordinate3D(x: shift + 1000.0, y: -(shift + 1000.0), projection: .epsg3857).clamped()
        #expect(planar.longitude == shift)
        #expect(planar.latitude == -shift)

        // EPSG:4978 and noSRID are unbounded no-ops.
        let ecef = Coordinate3D(x: 1_000_000_000.0, y: -1_000_000_000.0, projection: .epsg4978).clamped()
        #expect(ecef.longitude == 1_000_000_000.0)
        #expect(ecef.latitude == -1_000_000_000.0)

        let noSrid = Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID).clamped()
        #expect(noSrid.longitude == 500.0)
        #expect(noSrid.latitude == 500.0)

        // In-range values are returned unchanged.
        let inRange = Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 9.0, m: 1.0).clamped()
        #expect(inRange.latitude == 41.0)
        #expect(inRange.longitude == -71.0)
        #expect(inRange.altitude == 9.0)
        #expect(inRange.m == 1.0)
    }

    // MARK: - Audit


    // MARK: - Registry contract

    /// Every built-in SRID resolves to a definition carrying that SRID, and
    /// the canonical constant (where one exists) is identical.
    @Test
    func registryMatchesDefinitions() throws {
        for srid in Self.builtinSrids {
            let projection = try #require(Projection(srid: srid), "missing SRID \(srid)")
            #expect(projection.srid == srid)
            #expect(projection.definition.projection == projection)
        }
    }

    /// The registry does not invent CRSs that EPSG does not define.
    ///
    /// In particular, EPSG:26924–26960 are not NAD83/UTM zones: 26924–26928
    /// are unassigned and 26929–26960 are NAD83 State Plane zones, which
    /// this library does not implement. Accepting them as UTM zones (the
    /// previous behavior) produced silently wrong coordinates.
    @Test
    func undefinedSridsAreRejected() {
        for srid in [26924, 26925, 26926, 26927, 26928, 26929, 26940, 26960] {
            #expect(Projection(srid: srid) == nil, "SRID \(srid) must not resolve")
        }
        #expect(Projection(srid: 1234) == nil)
        #expect(Projection(srid: -1) == nil)
        #expect(Projection(srid: 0) == .noSRID)
    }

    /// UTM metadata resolves for all three UTM belts and nowhere else.
    @Test
    func utmMetadata() throws {
        for zone in 1 ... 60 {
            let north = try #require(Projection(srid: 32600 + zone))
            #expect(north.utmZone == zone)
            #expect(north.utmHemisphere == .north)

            let south = try #require(Projection(srid: 32700 + zone))
            #expect(south.utmZone == zone)
            #expect(south.utmHemisphere == .south)
        }

        for zone in 28 ... 38 {
            let projection = try #require(Projection(srid: 25800 + zone))
            #expect(projection.utmZone == zone)
            #expect(projection.utmHemisphere == .north)
        }

        for zone in 1 ... 23 {
            let projection = try #require(Projection(srid: 26900 + zone))
            #expect(projection.utmZone == zone)
            #expect(projection.utmHemisphere == .north)
        }

        #expect(Projection.epsg4326.utmZone == nil)
        #expect(Projection.epsg3857.utmZone == nil)
        #expect(Projection.epsg3035.utmZone == nil)
    }

    // MARK: - Independent reference values

    /// EPSG:32662 is metre-valued equirectangular, not degree-valued.
    ///
    /// PROJ reference (`+proj=eqc +lat_ts=0 +datum=WGS84 +units=m`):
    /// (10°E, 50°N) → (1,113,194.907933, 5,540,847.041684).
    @Test
    func plateCarreeReferenceValues() throws {
        let projection = Projection.epsg32662
        let projected = Coordinate3D(latitude: 50.0, longitude: 10.0).projected(to: projection)

        #expect(abs(projected.x - 1_113_194.9079327357) < 0.000001)
        #expect(abs(projected.y - 5_540_847.041684148) < 0.000001)
        #expect(projection.wraparoundExtent == GISTool.originShift)

        let back = projected.projected(to: .epsg4326)
        #expect(abs(back.latitude - 50.0) < 0.0000000001)
        #expect(abs(back.longitude - 10.0) < 0.0000000001)
    }

    /// NAD83/UTM zone 10N reference values from PROJ.
    ///
    /// (49.2827°N, 123.1207°W) → (491,221.770667, 5,458,889.979981).
    @Test
    func nad83UtmReferenceValues() throws {
        let projection = try #require(Projection(srid: 26910))
        let projected = Coordinate3D(latitude: 49.2827, longitude: -123.1207).projected(to: projection)

        #expect(abs(projected.x - 491_221.770667) < 0.001)
        #expect(abs(projected.y - 5_458_889.979981) < 0.001)
        #expect(projection.datum == .nad83)
    }

    // MARK: - Round trips

    /// Round-trips every built-in projection at a representative point.
    ///
    /// The tolerance is 1 µm for projected and geocentric coordinates and
    /// 1e-9° (~0.1 mm) for geographic ones, well below the projection
    /// formulas' numerical error.
    @Test
    func roundTripsForEveryBuiltin() throws {
        for srid in Self.builtinSrids {
            let projection = try #require(Projection(srid: srid))
            let point = Self.representativePoint(for: projection)
            let original = Coordinate3D(latitude: point.latitude, longitude: point.longitude, altitude: 123.0)

            let projected = original.projected(to: projection)
            #expect(projected.projection == projection)

            let back = projected.projected(to: .epsg4326)
            // Helmert datum CRSs carry the iterative geocentric inverse;
            // their round trip is accurate to ~1e-8°, while identity-datum
            // geographic CRSs and all projected CRSs round-trip much
            // tighter.
            let isHelmertGeographic = [4267, 4277].contains(srid)
            let tolerance = projection.isGeographic
                ? (isHelmertGeographic ? 0.0000001 : 0.000000001)
                : 0.000001
            #expect(
                abs(back.latitude - point.latitude) < tolerance,
                "SRID \(srid) latitude \(back.latitude) != \(point.latitude)")
            #expect(
                abs(back.longitude - point.longitude) < tolerance,
                "SRID \(srid) longitude \(back.longitude) != \(point.longitude)")
            #expect(abs((back.altitude ?? 0.0) - 123.0) < 0.001, "SRID \(srid) altitude")
        }
    }

    /// A coordinate without an SRID is never transformed, in either
    /// direction; the values are copied verbatim and only the label changes.
    @Test
    func noSridIsCopiedVerbatim() {
        let coordinate = Coordinate3D(x: 123.0, y: 456.0, z: 7.0, m: 8.0, projection: .noSRID)

        for target: Projection in [.epsg4326, .epsg3857, .epsg4978, .epsg32662, .epsg32631] {
            let projected = coordinate.projected(to: target)
            #expect(projected.x == 123.0)
            #expect(projected.y == 456.0)
            #expect(projected.altitude == 7.0)
            #expect(projected.m == 8.0)
            #expect(projected.projection == target)

            let back = projected.projected(to: .noSRID)
            #expect(back.x == 123.0)
            #expect(back.y == 456.0)
            #expect(back.altitude == 7.0)
            #expect(back.m == 8.0)
            #expect(back.projection == .noSRID)
        }
    }

    // MARK: - WKT

    /// Malformed or unrecognised WKT must be rejected rather than guessed,
    /// and the UTM/Gauss-Krüger zone matchers must reject inconsistent
    /// central meridians.
    @Test
    func malformedWktIsRejected() {
        #expect(Projection(wkt: "") == nil)
        #expect(Projection(wkt: "unknown") == nil)
        #expect(Projection(wkt: "PROJCS[\"Something else\"]") == nil)
        #expect(Projection(wkt: "GEOGCS[\"Not A Known Datum\"]") == nil)

        // UTM zone token without a hemisphere.
        #expect(Projection(wkt: "PROJCS[\"WGS 84 / UTM zone 32\"]") == nil)
        // Zone token and central meridian disagree.
        #expect(Projection(
            wkt: "PROJCS[\"WGS 84 / UTM zone 32N\",PARAMETER[\"Central_Meridian\",15]]") == nil)
        // Zone token outside 1...60.
        #expect(Projection(wkt: "PROJCS[\"WGS 84 / UTM zone 61N\"]") == nil)
        // NAD83/UTM zone 24N does not exist.
        #expect(Projection(wkt: "PROJCS[\"NAD83 / UTM zone 24N\"]") == nil)
    }

    /// EPSG:32662's real WKT declares metre units.
    @Test
    func plateCarreeWkt() throws {
        let wkt = #"PROJCS["WGS 84 / Plate Carree",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]],PROJECTION["Equirectangular"],PARAMETER["central_meridian",0],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1]]"#
        let projection = try #require(Projection(wkt: wkt))
        #expect(projection == .epsg32662)
    }

    // MARK: - Fixtures

    /// All built-in SRIDs, mirroring `ProjectionRegistry`'s registration
    /// loops. Keeping the list explicit means a new registry entry must
    /// also be added here, and a removed one shows up as a test failure.
    private static let builtinSrids: [Int] = [
        0, 3857, 4326, 4978, 3395, 32_662,
        4258, 4267, 4277, 27700, 2056, 21_781, 29_902, 29_903, 2157,
        3035, 3034, 2154, 28_992, 4269, 5070, 3005, 3347, 3978,
    ] + Array(32_601 ... 32_660)
        + Array(32_701 ... 32_760)
        + Array(25_828 ... 25_838)
        + Array(26_901 ... 26_923)
        + Array(31_466 ... 31_469)
        + Array(31_255 ... 31_259)

    /// A point comfortably inside each projection's area of use.
    private static func representativePoint(for projection: Projection) -> (latitude: Double, longitude: Double) {
        if let zone = projection.utmZone {
            let centralMeridian = Double((zone - 1) * 6 - 180 + 3)
            let latitude = projection.utmHemisphere == .south ? -45.0 : 45.0
            return (latitude, centralMeridian)
        }

        switch projection.srid {
        case 0, 4326, 3857, 4978, 3395, 32_662, 4258, 4269:
            return (45.0, 10.0)
        case 4267:
            return (40.0, -100.0)
        case 4277, 27700:
            return (52.5, -1.5)
        case 2056, 21_781:
            return (46.95, 7.44)
        case 29_902, 29_903, 2157:
            return (53.3, -8.0)
        case 3035, 3034:
            return (52.0, 10.0)
        case 2154:
            return (48.85, 2.35)
        case 28_992:
            return (52.0, 5.0)
        case 5070:
            return (40.0, -100.0)
        case 3005, 3347, 3978:
            return (50.0, -110.0)
        case 31_466 ... 31_469:
            let zone = projection.srid - 31_464
            return (50.0, Double(zone * 3))
        case 31_255 ... 31_259:
            return (47.5, 13.33)
        default:
            return (45.0, 10.0)
        }
    }


    // MARK: - Batch audit

    /// The batch transform path (hoisted `prepared` closures) must agree with
    /// the single-coordinate path for every built-in projection, in both
    /// directions. This covers the datum, conic and equal-area `prepared`
    /// overrides that the single-point matrix does not execute.
    @Test
    func batchTransformsMatchSinglePathForEveryBuiltin() throws {
        for srid in Self.builtinSrids {
            let projection = try #require(Projection(srid: srid))
            let point = Self.representativePoint(for: projection)
            let original = Coordinate3D(
                latitude: point.latitude,
                longitude: point.longitude,
                altitude: 12.0)

            let single = original.projected(to: projection)
            let batch = [original, original].projected(to: projection)
            #expect(batch.count == 2)
            #expect(abs(batch[0].x - single.x) < 0.000000001, "SRID \(srid) forward x")
            #expect(abs(batch[0].y - single.y) < 0.000000001, "SRID \(srid) forward y")

            let singleBack = single.projected(to: .epsg4326)
            let batchBack = batch.projected(to: .epsg4326)
            #expect(abs(batchBack[0].latitude - singleBack.latitude) < 0.000000001, "SRID \(srid) inverse latitude")
            #expect(abs(batchBack[0].longitude - singleBack.longitude) < 0.000000001, "SRID \(srid) inverse longitude")
        }
    }

    /// `Projectable.project(to:)` is the in-place variant and must behave
    /// exactly like assigning `projected(to:)`.
    @Test
    func projectInPlace() {
        var coordinate = Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 50.0)
        let expected = coordinate.projected(to: .epsg3857)
        coordinate.project(to: .epsg3857)
        #expect(coordinate == expected)

        // Projecting to the same projection is a no-op.
        let unchanged = coordinate
        coordinate.project(to: .epsg3857)
        #expect(coordinate == unchanged)
    }


}
