@testable import GISTools
import Testing

struct ProjectionTests {

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

}
