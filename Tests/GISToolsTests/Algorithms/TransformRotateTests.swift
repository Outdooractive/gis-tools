@testable import GISTools
import Testing

struct TransformRotateTests {

    // Validates rotating a point 90 degrees around the origin.
    @Test
    func rotate() async throws {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 0.0))
        let pointTransformed = point.rotated(angle: 90.0, pivot: Coordinate3D.zero)
        let pointResult = Point(Coordinate3D(latitude: 0.0, longitude: 45.0))

        #expect(pointTransformed == pointResult)
    }

    // MARK: - EPSG:3857

    @Test
    func transformRotate3857() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let result = polygon.rotated(angle: 45.0, pivot: Coordinate3D?.none)
        #expect(result.allCoordinates.count == 5)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        // coordinates straddling the date line
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0)
        ]]))
        let result = polygon.rotated(angle: 10.0, pivot: Coordinate3D?.none)
        #expect(result != polygon)
        for coord in result.allCoordinates {
            #expect(abs(coord.longitude) > 150.0)
        }
    }

}
