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

    // MARK: - Projections

    // Validates rotation in EPSG:3857.
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
        #expect(result.projection == .epsg3857)
    }

    // Validates rotation in EPSG:4978.
    @Test
    func transformRotate4978() async throws {
        let c00 = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let c10 = Coordinate3D(latitude: 0.009, longitude: 0.0).projected(to: .epsg4978)
        let c11 = Coordinate3D(latitude: 0.009, longitude: 0.009).projected(to: .epsg4978)
        let c01 = Coordinate3D(latitude: 0.0, longitude: 0.009).projected(to: .epsg4978)
        let polygon = try #require(Polygon([[c00, c10, c11, c01, c00]]))
        let result = polygon.rotated(angle: 45.0, pivot: Coordinate3D?.none)
        #expect(result.allCoordinates.count == 5)
        #expect(result.projection == .epsg4978)
    }

    // Validates rotation with noSRID.
    @Test
    func transformRotateNoSRID() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
        ]))
        let result = lineString.rotated(angle: 90.0, pivot: Coordinate3D?.none)
        #expect(result.coordinates.count == 2)
        #expect(result.projection == .noSRID)
    }

    // MARK: - Antimeridian

    // Validates rotation across the antimeridian.
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
