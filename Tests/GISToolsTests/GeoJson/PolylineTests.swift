@testable import GISTools
import XCTest

final class PolylineTests: XCTestCase {

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

    func testEncodePolyline() throws {
        for (i, coordinate) in coordinates.enumerated() {
            XCTAssertEqual(Polyline.encode(coordinates: [coordinate]), polylines[i])
        }

        XCTAssertEqual(coordinates.encodePolyline(), encodedPolyline)
    }

    func testDecodePolyline() throws {
        XCTAssertEqual(encodedPolyline.decodePolyline(), coordinates)
    }

}
