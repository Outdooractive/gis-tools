@testable import GISTools
import Testing

struct TransformScaleTests {

    // Validates scaling a polygon with different anchor points (southWest, northEast, center, coordinate).
    @Test
    func scale() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0)
        ]]))

        let scaled1 = polygon.scaled(factor: 2.0, anchor: .southWest)
        let scaled2 = polygon.scaled(factor: 2.0, anchor: .northEast)
        let scaled3 = polygon.scaled(factor: 2.0, anchor: .center)
        let scaled4 = polygon.scaled(factor: 2.0, anchor: .coordinate(.zero))

        let result1 =  try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 20.315053115711862),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0)
        ]]))
        let result2 =  try #require(Polygon([[
            Coordinate3D(latitude: -10.0, longitude: -10.0),
            Coordinate3D(latitude: 10.0, longitude: -10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: -10.0)
        ]]))
        let result3 =  try #require(Polygon([[
            Coordinate3D(latitude: -5.0190006978611512, longitude: -4.9616312267024796),
            Coordinate3D(latitude: 14.980999302138857, longitude: -5.0384246584612811),
            Coordinate3D(latitude: 14.980999302138846, longitude: 15.116349907099902),
            Coordinate3D(latitude: -5.0190006978611512, longitude: 15.03836877329752),
            Coordinate3D(latitude: -5.0190006978611512, longitude: -4.9616312267024796)
        ]]))
        let result4 =  try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 20.315053115711862),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0)
        ]]))

        #expect(scaled1 == result1)
        #expect(scaled2 == result2)
        #expect(scaled3 == result3)
        #expect(scaled4 == result4)
    }

}
