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
        let coordinate1 = Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514)
        let result1 = coordinate1.projected(to: .epsg4326)
        #expect(abs(result1.latitude - 41.0) < 0.000001)
        #expect(abs(result1.longitude - -71.0) < 0.000001)

        let coordinate1b = Coordinate3D(x: -10_859_458.446776, y: 4_235_169.496066)
        let result1b = coordinate1b.projected(to: .epsg4326)
        #expect(abs(result1b.latitude - 35.522895) < 0.000001)
        #expect(abs(result1b.longitude - -97.552175) < 0.000001)

        let coordinate2 = Coordinate3D(x: 12_601_714.231207296, y: -2_700_367.3352587065)
        let result2 = coordinate2.projected(to: .epsg4326)
        #expect(abs(result2.latitude - -23.563987128451217) < 0.000001)
        #expect(abs(result2.longitude - 113.203125) < 0.000001)

        let coordinate3 = Coordinate3D(x: -8_179_373.522740139, y: 1_271_912.1506653326)
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
        let merc = Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514)
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
    }

    /// Validates the `srid` computed property returns the correct integer.
    @Test
    func sridProperty() async throws {
        #expect(Projection.noSRID.srid == 0)
        #expect(Projection.epsg3857.srid == 3857)
        #expect(Projection.epsg4326.srid == 4326)
        #expect(Projection.epsg4978.srid == 4978)
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
        #expect(Projection(wkt: "unknown") == nil)
        #expect(Projection(wkt: "") == nil)
    }

}
