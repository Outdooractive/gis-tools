import Foundation
@testable import GISTools
import Testing

/// Focused coverage for the four PROJ `laea` modes and their domain guards.
struct LambertAzimuthalModeTests {

    private let ellipsoid = Datum.etrs89.ellipsoid

    @Test
    func polarAndEquatorialModesRoundTrip() {
        let cases: [(name: String, latitudeOfOrigin: Double, latitude: Double, longitude: Double)] = [
            ("north pole", 90.0, 80.0, 30.0),
            ("south pole", -90.0, -75.0, -40.0),
            ("equator", 0.0, 0.0, 20.0),
            ("oblique", 52.0, 48.0, 16.0),
        ]

        for item in cases {
            let math = LambertAzimuthalEqualAreaMath(
                ellipsoid: ellipsoid,
                latitudeOfOrigin: item.latitudeOfOrigin,
                longitudeOfOrigin: 10.0)
            let projected = math.forward(latitude: item.latitude, longitude: item.longitude)
            #expect(projected.x.isFinite, "\(item.name) x")
            #expect(projected.y.isFinite, "\(item.name) y")

            let back = math.inverse(x: projected.x, y: projected.y)
            #expect(back.latitude.isFinite, "\(item.name) latitude")
            #expect(back.longitude.isFinite, "\(item.name) longitude")
            #expect(abs(back.latitude - item.latitude) < 0.000001, "\(item.name) latitude")
            #expect(abs(back.longitude - item.longitude) < 0.000001, "\(item.name) longitude")
        }
    }

    @Test
    func projectionCenterInverseReturnsOrigin() {
        for latitudeOfOrigin in [90.0, -90.0, 0.0, 45.0] {
            let math = LambertAzimuthalEqualAreaMath(
                ellipsoid: ellipsoid,
                latitudeOfOrigin: latitudeOfOrigin,
                longitudeOfOrigin: 7.0)
            let center = math.inverse(x: 0.0, y: 0.0)
            #expect(abs(center.latitude - latitudeOfOrigin) < 0.000001)
            #expect(abs(center.longitude - 7.0) < 0.000001)
        }
    }

    @Test
    func outsideDomainInverseReturnsNaN() {
        let math = LambertAzimuthalEqualAreaMath(
            ellipsoid: ellipsoid,
            latitudeOfOrigin: 45.0,
            longitudeOfOrigin: 0.0)
        let outside = math.inverse(x: 100_000_000.0, y: 100_000_000.0)
        #expect(outside.latitude.isNaN)
        #expect(outside.longitude.isNaN)
    }

}
