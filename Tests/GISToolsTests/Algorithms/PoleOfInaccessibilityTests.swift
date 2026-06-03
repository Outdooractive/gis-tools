import Foundation
@testable import GISTools
import Testing

struct PoleOfInaccessibilityTests {

    @Test
    func squarePole() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let pole = try #require(polygon.poleOfInaccessibility())
        // Should be near the center
        #expect(abs(pole.coordinate.latitude - 5.0) < 1.0)
        #expect(abs(pole.coordinate.longitude - 5.0) < 1.0)
        #expect(polygon.contains(pole.coordinate))
    }

    @Test
    func trianglePole() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let pole = try #require(polygon.poleOfInaccessibility())
        #expect(polygon.contains(pole.coordinate))
    }

    @Test
    func poleWithPrecision() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let pole1 = try #require(polygon.poleOfInaccessibility(precision: 1.0))
        let pole2 = try #require(polygon.poleOfInaccessibility(precision: 0.1))
        #expect(polygon.contains(pole1.coordinate))
        #expect(polygon.contains(pole2.coordinate))
    }

    @Test
    func poleLShaped() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let pole = try #require(polygon.poleOfInaccessibility())
        #expect(polygon.contains(pole.coordinate))
    }

    @Test
    func poleNoOuterRing() async throws {
        let polygon = Polygon()
        #expect(polygon.poleOfInaccessibility() == nil)
    }

}
