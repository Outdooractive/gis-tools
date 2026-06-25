@testable import GISTools
import Testing

struct EllipseTests {

    @Test
    func ellipse() async throws {
        let point = Point(Coordinate3D(latitude: 39.984, longitude: -75.343))
        let ellipse = try #require(point.ellipse(xSemiAxis: 5000.0, ySemiAxis: 3000.0))
        #expect(ellipse.isValid)
        #expect(ellipse.outerRing?.coordinates.count == 65)
    }

    @Test
    func circle() async throws {
        let center = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let point = Point(center)
        let ellipse = try #require(point.ellipse(xSemiAxis: 5000.0, ySemiAxis: 5000.0))
        let coordinates = ellipse.outerRing!.coordinates
        #expect(coordinates.count == 65)
        for coordinate in coordinates {
            let distance = center.distance(from: coordinate)
            #expect(abs(distance - 5000.0) < 1.0)
        }
    }

    @Test
    func rotated() async throws {
        let point = Point(Coordinate3D(latitude: 39.984, longitude: -75.343))
        let ellipse = try #require(point.ellipse(xSemiAxis: 5000.0, ySemiAxis: 3000.0, angle: 45.0))
        #expect(ellipse.isValid)
        #expect(ellipse.outerRing?.coordinates.count == 65)
    }

    // MARK: - Projections

    @Test
    func ellipse3857() async throws {
        let point = Point(Coordinate3D(x: 0.0, y: 0.0))
        let ellipse = try #require(point.ellipse(xSemiAxis: 5000.0, ySemiAxis: 3000.0))
        #expect(ellipse.isValid)
    }

    @Test
    func ellipse4978() async throws {
        let center = Coordinate3D(
            latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let ellipse = try #require(center.ellipse(xSemiAxis: 5000.0, ySemiAxis: 3000.0))
        #expect(ellipse.isValid)
    }

    @Test
    func ellipseNoSRID() async throws {
        let center = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let ellipse = try #require(center.ellipse(xSemiAxis: 5000.0, ySemiAxis: 3000.0))
        #expect(ellipse.isValid)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 180.0))
        let ellipse = try #require(point.ellipse(xSemiAxis: 100_000.0, ySemiAxis: 50_000.0))
        #expect(ellipse.isValid)
    }

    // MARK: - Edge cases

    @Test
    func ellipseInvalid() async throws {
        let point = Point(Coordinate3D(latitude: 39.984, longitude: -75.343))
        #expect(point.ellipse(xSemiAxis: 0.0, ySemiAxis: 3000.0) == nil)
        #expect(point.ellipse(xSemiAxis: 5000.0, ySemiAxis: 0.0) == nil)
        #expect(point.ellipse(xSemiAxis: 5000.0, ySemiAxis: 3000.0, steps: 1) == nil)
    }

}
