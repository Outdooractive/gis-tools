import Testing
import Foundation
@testable import GISTools

struct VoronoiTests {

    // Validates that 3 points produce 3 Voronoi cells within the bounding box.
    @Test
    func testThreePoints() throws {
        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 15.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 15.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = try #require(feature.geometry as? Polygon)
            #expect(poly.coordinates[0].count >= 4)
            #expect(poly.projection == .epsg4326)
        }
    }

    // Validates that 4 points at the corners produce cells filling the bounding box.
    @Test
    func testFourPoints() {
        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 15.0))),
            Feature(Point(Coordinate3D(latitude: 15.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 15.0, longitude: 15.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 4)
    }

    // Validates that points exactly on the bounding box edge still produce valid cells.
    @Test
    func testPointsOnBboxEdge() {
        let points = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 10.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 0.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)
    }

    // Validates that fewer than 3 points returns an empty FeatureCollection.
    @Test
    func testTooFewPoints() {
        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.isEmpty)
    }

    // Validates that an empty FeatureCollection returns an empty result.
    @Test
    func testEmptyPoints() {
        let fc = FeatureCollection()
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.isEmpty)
    }

    // Validates that the Voronoi cells do not extend outside the bounding box.
    @Test
    func testCellsWithinBbox() {
        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 15.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 15.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        for feature in result.features {
            guard let poly = feature.geometry as? Polygon else {
                Issue.record("Expected Polygon")
                continue
            }
            for coord in poly.allCoordinates {
                #expect(coord.latitude >= 0.0 - 0.0000000001)
                #expect(coord.latitude <= 20.0 + 0.0000000001)
                #expect(coord.longitude >= 0.0 - 0.0000000001)
                #expect(coord.longitude <= 20.0 + 0.0000000001)
            }
        }
    }

    // Validates a Voronoi diagram with points on both sides of the antimeridian,
    // within a world-spanning bounding box.
    @Test
    func testAntimeridianWorldBbox() {
        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: -170.0))),
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 180.0))),
            Feature(Point(Coordinate3D(latitude: -5.0, longitude: 170.0))),
            Feature(Point(Coordinate3D(latitude: -5.0, longitude: -175.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox.world

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 4)

        for feature in result.features {
            let poly = feature.geometry as? Polygon
            #expect(poly != nil)
            #expect(poly?.coordinates[0].count ?? 0 >= 4)
        }
    }

    // Validates a Voronoi diagram with an antimeridian-crossing bounding box,
    // covering the region from lon=170 to lon=-170 (across the date line).
    @Test
    func testAntimeridianCrossingBbox() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: -170.0))

        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 175.0))),
            Feature(Point(Coordinate3D(latitude: -5.0, longitude: 175.0))),
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: -175.0))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = feature.geometry as? Polygon
            #expect(poly != nil)
        }
    }

    // MARK: - Projections

    // Validates that points in EPSG:3857 produce a valid Voronoi diagram.
    @Test
    func voronoi3857() throws {
        let points = [
            Feature(Point(Coordinate3D(x: 500.0, y: 500.0))),
            Feature(Point(Coordinate3D(x: 1500.0, y: 500.0))),
            Feature(Point(Coordinate3D(x: 1000.0, y: 1500.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0),
            northEast: Coordinate3D(x: 2000.0, y: 2000.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = try #require(feature.geometry as? Polygon)
            #expect(poly.coordinates[0].count >= 4)
            #expect(poly.projection == .epsg3857)
        }
    }

    // Validates that points in noSRID produce a valid Voronoi diagram.
    @Test
    func voronoiNoSRID() throws {
        let points = [
            Feature(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))),
            Feature(Point(Coordinate3D(x: 1500.0, y: 500.0, projection: .noSRID))),
            Feature(Point(Coordinate3D(x: 1000.0, y: 1500.0, projection: .noSRID))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            northEast: Coordinate3D(x: 2000.0, y: 2000.0, projection: .noSRID))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = try #require(feature.geometry as? Polygon)
            #expect(poly.coordinates[0].count >= 4)
            #expect(poly.projection == .noSRID)
        }
    }


    // Validates Voronoi in EPSG:4978.
    @Test
    func voronoi4978() throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(x: 6_378_000.0, y: 0.0, projection: .epsg4978),
            Coordinate3D(x: 6_378_100.0, y: 0.0, projection: .epsg4978),
            Coordinate3D(x: 6_378_050.0, y: 100.0, projection: .epsg4978),
        ]
        let points = coords.map { Feature(Point($0)) }
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 6_377_000.0, y: -100_000.0, projection: .epsg4978),
            northEast: Coordinate3D(x: 6_379_000.0, y: 100_000.0, projection: .epsg4978))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = try #require(feature.geometry as? Polygon)
            #expect(poly.coordinates[0].count >= 4)
            #expect(poly.projection == .epsg4978)
        }
    }

    // Validates a Voronoi diagram with points near the antimeridian and a
    // non-crossing bounding box covering longitudes 150 to 200 (normalized).
    @Test
    func testAntimeridianNonCrossingBbox() {
        // Longitude 200 normalizes to -160, so this bbox crosses the antimeridian
        // in normalized form: [-160, -20, 160, 20]
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -20.0, longitude: 160.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: -160.0))

        let points = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 165.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 170.0))),
            Feature(Point(Coordinate3D(latitude: -10.0, longitude: -170.0))),
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: -165.0))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 4)

        for feature in result.features {
            let poly = feature.geometry as? Polygon
            #expect(poly != nil)
        }
    }

}
