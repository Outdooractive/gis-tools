@testable import GISTools
import Testing

struct ConversionTests {

    @Test
    func metersPerPixelAtEquator() async throws {
        var mppAtZoomLevels: [Double] = Array(repeating: 0.0, count: 21)
        mppAtZoomLevels[0] = 156_543.03392804096

        for zoom in 1...20 {
            mppAtZoomLevels[zoom] = mppAtZoomLevels[zoom - 1] / 2.0

            #expect(abs(GISTool.metersPerPixel(atZoom: zoom) - mppAtZoomLevels[zoom]) < 0.00001)
        }
    }

    @Test
    func metersPerPixelAt45() async throws {
        var mppAtZoomLevels: [Double] = Array(repeating: 0.0, count: 21)
        mppAtZoomLevels[0] = 110_692.6408380335

        for zoom in 1...20 {
            mppAtZoomLevels[zoom] = mppAtZoomLevels[zoom - 1] / 2.0

            #expect(abs(GISTool.metersPerPixel(atZoom: zoom, latitude: 45.0) - mppAtZoomLevels[zoom]) < 0.00001)
        }
    }

    @Test
    func metersAtLatitude() async throws {
        let meters = 10000.0
        let degreesLatitude1 = try #require(GISTool.convert(length: meters, from: .meters, to: .degrees))
        let degreesLatitude2 = GISTool.degrees(fromMeters: meters, atLatitude: 0.0).latitudeDegrees

        #expect(abs(degreesLatitude1 - degreesLatitude2) < 0.00000001)
    }

}
