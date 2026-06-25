import Foundation
@testable import GISTools
import Testing

struct TinTests {

    // Validates that 3 points produce 1 triangle.
    @Test
    func tinThreePoints() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
        ]))

        let fc = try #require(mp.tin())
        #expect(fc.features.count == 1)
        let tri = try #require(fc.features[0].geometry as? Polygon)
        #expect(tri.projection == .epsg4326)
    }

    // Validates that 4 points in a square produce 2 triangles.
    @Test
    func tinSquare() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))

        let fc = try #require(mp.tin())
        #expect(fc.features.count == 2)
        let tri = try #require(fc.features[0].geometry as? Polygon)
        #expect(tri.projection == .epsg4326)
    }

    // Validates that fewer than 3 distinct points returns nil.
    @Test
    func tinInsufficientPoints() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(mp.tin() == nil)
    }

    // Single point returns nil.
    @Test
    func tinSinglePoint() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        #expect(mp.tin() == nil)
    }

    // Validates triangulation from a LineString works.
    @Test
    func tinLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))

        let fc = try #require(ls.tin())
        #expect(fc.features.count == 2)
    }

    // Validates triangulation from a Feature works.
    @Test
    func tinFeature() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
        ]))
        let feature = Feature(mp)
        let fc = try #require(feature.tin())
        #expect(fc.features.count == 1)
    }

    // Validates that all triangle vertices are distinct and form valid polygons.
    @Test
    func tinTrianglesAreValid() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
        ]))

        let fc = try #require(mp.tin())
        for feature in fc.features {
            let polygon = try #require(feature.geometry as? Polygon)
            let coords = try #require(polygon.outerRing?.coordinates)
            #expect(coords.count == 4) // 3 vertices + closing
        }
    }

    // Validates triangulation of points straddling the antimeridian.
    @Test
    func tinCrossingAntimeridian() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 175.0),
            Coordinate3D(latitude: 10.0, longitude: -175.0),
            Coordinate3D(latitude: 5.0, longitude: 180.0),
        ]))

        let fc = try #require(mp.tin())
        #expect(fc.features.count >= 1)
    }

    // Validates that the TIN covers all input points (each point is a vertex of at least one triangle).
    @Test
    func tinCoversAllPoints() async throws {
        let inputPoints = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]
        let mp = try #require(MultiPoint(inputPoints))

        let fc = try #require(mp.tin())
        var coveredPoints = Set<Coordinate3D>()

        for feature in fc.features {
            let polygon = try #require(feature.geometry as? Polygon)
            let coords = try #require(polygon.outerRing?.coordinates)
            for coord in coords {
                coveredPoints.insert(coord)
            }
        }

        for point in inputPoints {
            #expect(coveredPoints.contains(point))
        }
    }

    // MARK: - Projections

    @Test
    func tin3857() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 50_000.0, y: 100_000.0),
        ]))
        let fc = try #require(mp.tin())
        #expect(fc.features.count == 1)
        let tri = try #require(fc.features[0].geometry as? Polygon)
        #expect(tri.projection == .epsg3857)
    }

    @Test
    func tinNoSRID() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100_000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 50_000.0, y: 100_000.0, projection: .noSRID),
        ]))
        let fc = try #require(mp.tin())
        #expect(fc.features.count == 1)
        let tri = try #require(fc.features[0].geometry as? Polygon)
        #expect(tri.projection == .noSRID)
    }


    @Test
    func tin4978() async throws {
        // Small triangle in ECEF space near the equatorial XY plane.
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 6_378_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 6_378_100.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 6_378_050.0, y: 100.0, z: 0.0, projection: .epsg4978),
        ]))
        let fc = try #require(mp.tin())
        #expect(fc.features.count == 1)
        let tri = try #require(fc.features[0].geometry as? Polygon)
        #expect(tri.projection == .epsg4978)
    }

}
