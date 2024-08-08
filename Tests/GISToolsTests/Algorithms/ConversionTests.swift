@testable import GISTools
import XCTest

final class ConversionTests: XCTestCase {

    func testMetersPerPixelAtEquator() {
        var mppAtZoomLevels: [Double] = Array(repeating: 0.0, count: 21)
        mppAtZoomLevels[0] = 156_543.03392804096

        for zoom in 1...20 {
            mppAtZoomLevels[zoom] = mppAtZoomLevels[zoom - 1] / 2.0

            XCTAssertEqual(GISTool.metersPerPixel(atZoom: zoom),
                           mppAtZoomLevels[zoom],
                           accuracy: 0.00001)
        }
    }

    func testMetersPerPixelAt45() {
        var mppAtZoomLevels: [Double] = Array(repeating: 0.0, count: 21)
        mppAtZoomLevels[0] = 110_692.6408380335

        for zoom in 1...20 {
            mppAtZoomLevels[zoom] = mppAtZoomLevels[zoom - 1] / 2.0

            XCTAssertEqual(GISTool.metersPerPixel(atZoom: zoom, latitude: 45.0),
                           mppAtZoomLevels[zoom],
                           accuracy: 0.00001)
        }
    }

    func testMetersAtLatitude() throws {
        let meters = 10000.0
        let degreesLatitude1 = try XCTUnwrap(GISTool.convert(length: meters, from: .meters, to: .degrees))
        let degreesLatitude2 = GISTool.degrees(fromMeters: meters, atLatitude: 0.0).latitudeDegrees

        XCTAssertEqual(degreesLatitude1, degreesLatitude2, accuracy: 0.00000001)
    }

}
