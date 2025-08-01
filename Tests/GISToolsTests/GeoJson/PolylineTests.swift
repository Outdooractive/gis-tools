import Foundation
@testable import GISTools
import Testing

struct PolylineTests {

    let coordinates: [Coordinate3D] = [
        .init(latitude: 38.5, longitude: -120.2),
        .init(latitude: 40.7, longitude: -120.95),
        .init(latitude: 43.252, longitude: -126.453),
    ]
    let polylines: [String] = [
        "_p~iF~ps|U",
        "_flwFn`faV",
        "_t~fGfzxbW",
    ]
    let encodedPolyline = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"

    @Test
    func encodePolyline() async throws {
        for (i, coordinate) in coordinates.enumerated() {
            #expect(Polyline.encode(coordinates: [coordinate]) == polylines[i])
        }

        #expect(coordinates.encodePolyline() == encodedPolyline)
    }

    @Test
    func decodePolyline() async throws {
        #expect(encodedPolyline.decodePolyline() == coordinates)
    }

}
