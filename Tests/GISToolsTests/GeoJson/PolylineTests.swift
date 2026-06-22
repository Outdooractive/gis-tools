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

    // Validates encoding coordinates to Google Polyline format.
    @Test
    func encodePolyline() async throws {
        for (i, coordinate) in coordinates.enumerated() {
            #expect(Polyline.encode(coordinates: [coordinate]) == polylines[i])
        }

        #expect(coordinates.encodePolyline() == encodedPolyline)
    }

    // Validates decoding a Google Polyline encoded string back to coordinates.
    @Test
    func decodePolyline() async throws {
        #expect(encodedPolyline.decodePolyline() == coordinates)
    }

    // Validates roundtrip: encode 3857 coordinates, decode, verify they match (in 4326).
    @Test
    func roundtrip3857() throws {
        let coords3857: [Coordinate3D] = [
            Coordinate3D(latitude: 38.5, longitude: -120.2).projected(to: .epsg3857),
            Coordinate3D(latitude: 40.7, longitude: -120.95).projected(to: .epsg3857),
            Coordinate3D(latitude: 43.252, longitude: -126.453).projected(to: .epsg3857),
        ]
        let encoded = coords3857.encodePolyline()
        let decoded = try #require(encoded.decodePolyline())

        let expected4326 = coords3857.map { $0.projected(to: .epsg4326) }
        #expect(decoded == expected4326)
    }

    // Validates roundtrip: encode 4978 coordinates, decode, verify they match (in 4326).
    @Test
    func roundtrip4978() throws {
        let coords4978: [Coordinate3D] = [
            Coordinate3D(latitude: 38.5, longitude: -120.2).projected(to: .epsg4978),
            Coordinate3D(latitude: 40.7, longitude: -120.95).projected(to: .epsg4978),
            Coordinate3D(latitude: 43.252, longitude: -126.453).projected(to: .epsg4978),
        ]
        let encoded = coords4978.encodePolyline()
        let decoded = try #require(encoded.decodePolyline())

        let expected4326 = coords4978.map { $0.projected(to: .epsg4326) }
        #expect(decoded.count == expected4326.count)
        for i in decoded.indices {
            #expect(decoded[i].equals(other: expected4326[i], includingAltitude: false))
        }
    }

}
