import Foundation
@testable import GISTools
import Testing

struct RandomTests {

    /// Tests that a random position within the world bounding box has valid coordinates.
    @Test
    func randomCoordinateInWorld() async throws {
        let pos = BoundingBox.randomCoordinate()
        #expect(pos.latitude >= -90.0 && pos.latitude <= 90.0)
        #expect(pos.longitude >= -180.0 && pos.longitude <= 180.0)
    }

    /// Tests that a random position within a custom bounding box falls inside it.
    @Test
    func randomCoordinateInBbox() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 40.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 50.0, longitude: 10.0))
        for _ in 0 ..< 10 {
            let pos = bbox.randomCoordinate()
            #expect(pos.latitude >= 40.0 && pos.latitude <= 50.0)
            #expect(pos.longitude >= -10.0 && pos.longitude <= 10.0)
        }
    }

    /// Tests that randomPoints() defaults to a single point.
    @Test
    func randomPointsDefaultCount() async throws {
        let points = BoundingBox.randomPoints()
        #expect(points.features.count == 1)
        #expect(points.features[0].geometry is Point)
    }

    /// Tests that randomPoints(count:) produces the requested number of points.
    @Test
    func randomPointsCustomCount() async throws {
        let points = BoundingBox.randomPoints(count: 5)
        #expect(points.features.count == 5)
        for feature in points.features {
            #expect(feature.geometry is Point)
        }
    }

    /// Tests that random points within a bounding box lie inside it.
    @Test
    func randomPointsInBbox() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let points = bbox.randomPoints(count: 5)
        #expect(points.features.count == 5)
        for feature in points.features {
            let point = try #require(feature.geometry as? Point)
            #expect(point.coordinate.latitude >= 0.0 && point.coordinate.latitude <= 10.0)
            #expect(point.coordinate.longitude >= 0.0 && point.coordinate.longitude <= 10.0)
        }
    }

    /// Tests that randomPolygons() produces valid polygons.
    @Test
    func randomPolygonsDefault() async throws {
        let polygons = BoundingBox.randomPolygons()
        #expect(polygons.features.count == 1)
        let polygon = try #require(polygons.features[0].geometry as? Polygon)
        #expect(polygon.isValid)
        #expect(polygon.outerRing?.coordinates.count ?? 0 >= 4)
    }

    /// Tests that randomPolygons(count:) produces the requested number of polygons.
    @Test
    func randomPolygonsCustomCount() async throws {
        let polygons = BoundingBox.randomPolygons(count: 3)
        #expect(polygons.features.count == 3)
        for feature in polygons.features {
            #expect(feature.geometry is Polygon)
        }
    }

    /// Tests that random polygons within a bounding box are valid.
    @Test
    func randomPolygonsInBbox() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))
        let polygons = bbox.randomPolygons(count: 5, numVertices: 6, maxRadialLength: 5.0)
        #expect(polygons.features.count == 5)
        for feature in polygons.features {
            let polygon = try #require(feature.geometry as? Polygon)
            #expect(polygon.isValid)
        }
    }

    /// Tests that maxRadialLength larger than the bounding box half-size is clamped.
    @Test
    func randomPolygonsMaxRadialLengthClamped() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 2.0, longitude: 2.0))
        let polygons = bbox.randomPolygons(count: 1, maxRadialLength: 100.0)
        #expect(polygons.features.count == 1)
    }

    /// Tests that randomLineStrings() produces valid line strings.
    @Test
    func randomLineStringsDefault() async throws {
        let lines = BoundingBox.randomLineStrings()
        #expect(lines.features.count == 1)
        let ls = try #require(lines.features[0].geometry as? LineString)
        #expect(ls.coordinates.count >= 2)
    }

    /// Tests that randomLineStrings(count:) produces the requested number of line strings.
    @Test
    func randomLineStringsCustomCount() async throws {
        let lines = BoundingBox.randomLineStrings(count: 3)
        #expect(lines.features.count == 3)
        for feature in lines.features {
            #expect(feature.geometry is LineString)
        }
    }

    /// Tests that random line strings within a bounding box have the expected vertex count.
    @Test
    func randomLineStringsInBbox() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let lines = bbox.randomLineStrings(count: 5, numVertices: 5, maxLength: 1.0)
        #expect(lines.features.count == 5)
        for feature in lines.features {
            let ls = try #require(feature.geometry as? LineString)
            #expect(ls.coordinates.count == 5)
        }
    }

    /// Tests that short random line segments are generated correctly.
    @Test
    func randomLineStringsShortSegment() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 1.0, longitude: 1.0))
        let lines = bbox.randomLineStrings(count: 1, numVertices: 3, maxLength: 0.5, maxRotation: .pi)
        #expect(lines.features.count == 1)
        let ls = try #require(lines.features[0].geometry as? LineString)
        #expect(ls.coordinates.count == 3)
    }
    // MARK: - EPSG:3857

    @Test
    func random3857() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0),
            northEast: Coordinate3D(x: 1_000_000.0, y: 1_000_000.0))
        let points = bbox.randomPoints(count: 5)
        #expect(points.features.count == 5)
        for feature in points.features {
            let point = try #require(feature.geometry as? Point)
            #expect(point.isValid)
        }
    }

}
