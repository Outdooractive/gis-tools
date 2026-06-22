@testable import GISTools
import Testing

struct PlanepointTests {

    /// Interpolates the z-value at the centroid of a flat triangle.
    @Test
    func flatTriangleCentroid() async throws {
        let triangle = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 10.0),
            ],
        ]))
        let point = Coordinate3D(latitude: 3.0, longitude: 5.0)
        let z = try #require(triangle.planepoint(point))
        #expect(abs(z - 10.0) < 0.001)
    }

    /// Interpolates the z-value at a vertex returns that vertex's z-value.
    @Test
    func vertexZ() async throws {
        let triangle = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 200.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 300.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            ],
        ]))
        let z = try #require(triangle.planepoint(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        #expect(abs(z - 100.0) < 0.001)
    }

    /// Interpolates along an edge: halfway between (0,0,z=0) and (10,10,z=100)
    /// at (5,5) should give z=50.
    @Test
    func edgeMidpoint() async throws {
        let triangle = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 100.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0),
            ],
        ]))
        let point = Coordinate3D(latitude: 5.0, longitude: 5.0)
        let z = try #require(triangle.planepoint(point))
        #expect(abs(z - 50.0) < 1.0)
    }

    /// Returns nil for a point outside the triangle.
    @Test
    func outsideTriangle() async throws {
        let triangle = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0),
            ],
        ]))
        let point = Coordinate3D(latitude: 50.0, longitude: 50.0)
        #expect(triangle.planepoint(point) == nil)
    }

    /// Returns nil for a non-triangular polygon.
    @Test
    func notATriangle() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0),
            ],
        ]))
        #expect(polygon.planepoint(Coordinate3D(latitude: 5.0, longitude: 5.0)) == nil)
    }

    // MARK: - EPSG:3857

    @Test
    func planepoint3857() async throws {
        let triangle = try #require(Polygon([
            [
                Coordinate3D(x: 0.0, y: 0.0, z: 10.0),
                Coordinate3D(x: 100_000.0, y: 100_000.0, z: 10.0),
                Coordinate3D(x: 0.0, y: 100_000.0, z: 10.0),
                Coordinate3D(x: 0.0, y: 0.0, z: 10.0),
            ],
        ]))
        let point = Coordinate3D(x: 30_000.0, y: 50_000.0)
        let z = triangle.planepoint(point)
        #expect(z != nil)
        #expect(z!.isFinite)
    }

    // MARK: - Antimeridian

    /// A triangle crossing the date line: vertices at lon=179 and lon=-179.
    /// The query point is between them (lon=180, the short way across).
    @Test
    func antimeridianTriangle() async throws {
        let triangle = Polygon(unchecked: [
            [
                Coordinate3D(latitude: 0.0, longitude: 179.0, altitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: -179.0, altitude: 100.0),
                Coordinate3D(latitude: 0.0, longitude: -179.0, altitude: 50.0),
                Coordinate3D(latitude: 0.0, longitude: 179.0, altitude: 0.0),
            ],
        ])
        // Point near the centre of the triangle
        let point = Coordinate3D(latitude: 2.5, longitude: 180.0)
        let z = try #require(triangle.planepoint(point))
        #expect(z > 20.0)
        #expect(z < 80.0)
    }

    // MARK: - TIN to point cloud

    @Test
    func tinToPointCloud() async throws {
        let triangle1 = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 100.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 50.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0),
            ],
        ]))
        let triangle2 = try #require(Polygon([
            [
                Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 100.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 200.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 50.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 100.0),
            ],
        ]))
        let fc = FeatureCollection([Feature(triangle1), Feature(triangle2)])
        let cloud = fc.tinToPointCloud()
        #expect(cloud.features.count == 2)
        for feature in cloud.features {
            let point = try #require(feature.geometry as? Point)
            #expect(point.coordinate.altitude != nil)
            #expect(point.coordinate.altitude! > 0.0)
        }
    }

}
