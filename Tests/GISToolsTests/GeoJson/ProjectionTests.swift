import Foundation
@testable import GISTools
import Testing

struct ProjectionTests {

    // Tests coordinate projection from EPSG:4326 to EPSG:3857, including coordinates crossing the 180th meridian.
    @Test
    func convertTo3857() async throws {
        // A simple case
        let coordinate1 = Coordinate3D(latitude: 41.0, longitude: -71.0)
        let result1 = coordinate1.projected(to: .epsg3857)
        #expect(abs(result1.longitude - -7_903_683.846322424) < 0.000001)
        #expect(abs(result1.latitude - 5_012_341.663847514) < 0.000001)

        let coordinate1b = Coordinate3D(latitude: 35.522895, longitude: -97.552175)
        let result1b = coordinate1b.projected(to: .epsg3857)
        #expect(abs(result1b.longitude - -10_859_458.446776) < 0.000001)
        #expect(abs(result1b.latitude - 4_235_169.496066) < 0.000001)

        // A coordinate that passed the 180th meridian
        let coordinate2 = Coordinate3D(latitude: -23.563987128451217, longitude: -246.796875)
        let result2 = coordinate2.projected(to: .epsg3857)
        #expect(abs(result2.longitude - -27_473_302.454371188) < 0.000001)
        #expect(abs(result2.latitude - -2_700_367.3352587065) < 0.000001)

        // A coordinate that passed the 180th meridian
        let coordinate3 = Coordinate3D(latitude: -23.563987128451217, longitude: -246.796875)
        let result3 = coordinate3.normalized().projected(to: .epsg3857)
        #expect(abs(result3.longitude - 12_601_714.231207296) < 0.000001)
        #expect(abs(result3.latitude - -2_700_367.3352587065) < 0.000001)

        // Another coordinate that passed the 180th meridian
        let coordinate4 = Coordinate3D(latitude: 11.350796722383672, longitude: 286.5234375)
        let result4 = coordinate4.projected(to: .epsg3857)
        #expect(abs(result4.longitude - 31_895_643.162838347) < 0.000001)
        #expect(abs(result4.latitude - 1_271_912.1506653326) < 0.000001)

        // Another coordinate that passed the 180th meridian
        let coordinate5 = Coordinate3D(latitude: 11.350796722383672, longitude: 286.5234375)
        let result5 = coordinate5.normalized().projected(to: .epsg3857)
        #expect(abs(result5.longitude - -8_179_373.522740141) < 0.000001)
        #expect(abs(result5.latitude - 1_271_912.1506653326) < 0.000001)
    }

    // Tests coordinate projection from EPSG:3857 to EPSG:4326, including coordinates crossing the 180th meridian.
    @Test
    func convertTo4326() async throws {
        // A simple case
        let coordinate1 = Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514)
        let result1 = coordinate1.projected(to: .epsg4326)
        #expect(abs(result1.latitude - 41.0) < 0.000001)
        #expect(abs(result1.longitude - -71.0) < 0.000001)

        let coordinate1b = Coordinate3D(x: -10_859_458.446776, y: 4_235_169.496066)
        let result1b = coordinate1b.projected(to: .epsg4326)
        #expect(abs(result1b.latitude - 35.522895) < 0.000001)
        #expect(abs(result1b.longitude - -97.552175) < 0.000001)

        // A coordinate that passed the 180th meridian
        let coordinate2 = Coordinate3D(x: 12_601_714.231207296, y: -2_700_367.3352587065)
        let result2 = coordinate2.projected(to: .epsg4326)
        #expect(abs(result2.latitude - -23.563987128451217) < 0.000001)
        #expect(abs(result2.longitude - 113.203125) < 0.000001)

        // Another coordinate that passed the 180th meridian
        let coordinate3 = Coordinate3D(x: -8_179_373.522740139, y: 1_271_912.1506653326)
        let result3 = coordinate3.projected(to: .epsg4326)
        #expect(abs(result3.latitude - 11.350796722383672) < 0.000001)
        #expect(abs(result3.longitude - -73.476562) < 0.000001)
    }

    @Test
    func cases() async throws {
        #expect(Projection.noSRID.srid == 0)
        #expect(Projection.epsg3857.srid == 3857)
        #expect(Projection.epsg4326.srid == 4326)
    }

    @Test
    func initFromSrid() async throws {
        #expect(Projection(srid: 0) == .noSRID)
        #expect(Projection(srid: 4326) == .epsg4326)
        #expect(Projection(srid: 3857) == .epsg3857)
    }

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

    @Test
    func initFromUnsupportedSrid() async throws {
        #expect(Projection(srid: 1234) == nil)
        #expect(Projection(srid: -1) == nil)
    }

    @Test
    func description() async throws {
        #expect(Projection.noSRID.description == "No SRID")
        #expect(Projection.epsg3857.description == "EPSG:3857")
        #expect(Projection.epsg4326.description == "EPSG:4326")
    }

    @Test
    func sridProperty() async throws {
        #expect(Projection.noSRID.srid == 0)
        #expect(Projection.epsg3857.srid == 3857)
        #expect(Projection.epsg4326.srid == 4326)
    }

    @Test
    func equatable() async throws {
        #expect(Projection.epsg4326 == .epsg4326)
        #expect(Projection.epsg4326 != .epsg3857)
        #expect(Projection.noSRID != .epsg4326)
    }

    @Test
    func codableRoundTrip() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for projection: Projection in [.noSRID, .epsg3857, .epsg4326] {
            let data = try encoder.encode(projection)
            let decoded = try decoder.decode(Projection.self, from: data)
            #expect(decoded == projection)
        }
    }

    @Test
    func codableRawValues() async throws {
        let encoder = JSONEncoder()

        #expect(String(data: try encoder.encode(Projection.noSRID), encoding: .utf8) == "0")
        #expect(String(data: try encoder.encode(Projection.epsg3857), encoding: .utf8) == "3857")
        #expect(String(data: try encoder.encode(Projection.epsg4326), encoding: .utf8) == "4326")
    }

    /// Validates ``Projection.init(wkt:)`` with common ``.prj`` strings.
    @Test
    func initFromWkt() async throws {
        #expect(Projection(wkt: #"GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]]"#) == .epsg4326)
        #expect(Projection(wkt: #"GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]]"#) == .epsg4326)
        #expect(Projection(wkt: #"PROJCS["WGS 84 / Pseudo-Mercator",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]],PROJECTION["Mercator_1SP"],PARAMETER["central_meridian",0],PARAMETER["scale_factor",1],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1]]"#) == .epsg3857)
        #expect(Projection(wkt: "unknown") == nil)
        #expect(Projection(wkt: "") == nil)
    }

}
