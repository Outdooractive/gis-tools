@testable import GISTools
import Testing

struct TransformScaleTests {

    @Test
    func transformScale() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0)
        ]]))

        let transformed1 = polygon.transformedScale(factor: 2.0, anchor: .southWest)
        let transformed2 = polygon.transformedScale(factor: 2.0, anchor: .northEast)
        let transformed3 = polygon.transformedScale(factor: 2.0, anchor: .center)
        let transformed4 = polygon.transformedScale(factor: 2.0, anchor: .coordinate(.zero))

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

        #expect(transformed1 == result1)
        #expect(transformed2 == result2)
        #expect(transformed3 == result3)
        #expect(transformed4 == result4)
    }

}
