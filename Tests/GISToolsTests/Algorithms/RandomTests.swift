import Foundation
@testable import GISTools
import Testing

struct RandomTests {

    @Test
    func randomPositionInWorld() {
        let pos = BoundingBox.randomCoordinate()
        #expect(pos.latitude >= -90.0 && pos.latitude <= 90.0)
        #expect(pos.longitude >= -180.0 && pos.longitude <= 180.0)
    }

    @Test
    func randomPositionInBbox() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 40.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 50.0, longitude: 10.0))
        for _ in 0 ..< 10 {
            let pos = bbox.randomCoordinate()
            #expect(pos.latitude >= 40.0 && pos.latitude <= 50.0)
            #expect(pos.longitude >= -10.0 && pos.longitude <= 10.0)
        }
    }

    @Test
    func randomPointsDefaultCount() {
        let points = BoundingBox.randomPoints()
        #expect(points.features.count == 1)
        #expect(points.features[0].geometry is Point)
    }

    @Test
    func randomPointsCustomCount() {
        let points = BoundingBox.randomPoints(count: 5)
        #expect(points.features.count == 5)
        for feature in points.features {
            #expect(feature.geometry is Point)
        }
    }

    @Test
    func randomPointsInBbox() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let points = bbox.randomPoints(count: 5)
        #expect(points.features.count == 5)
        for feature in points.features {
            let point = try! #require(feature.geometry as? Point)
            #expect(point.coordinate.latitude >= 0.0 && point.coordinate.latitude <= 10.0)
            #expect(point.coordinate.longitude >= 0.0 && point.coordinate.longitude <= 10.0)
        }
    }

    @Test
    func randomPolygonsDefault() {
        let polygons = BoundingBox.randomPolygons()
        #expect(polygons.features.count == 1)
        let polygon = try! #require(polygons.features[0].geometry as? Polygon)
        #expect(polygon.isValid)
        #expect(polygon.outerRing?.coordinates.count ?? 0 >= 4)
    }

    @Test
    func randomPolygonsCustomCount() {
        let polygons = BoundingBox.randomPolygons(count: 3)
        #expect(polygons.features.count == 3)
        for feature in polygons.features {
            #expect(feature.geometry is Polygon)
        }
    }

    @Test
    func randomPolygonsInBbox() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))
        let polygons = bbox.randomPolygons(count: 5, numVertices: 6, maxRadialLength: 5.0)
        #expect(polygons.features.count == 5)
        for feature in polygons.features {
            let polygon = try! #require(feature.geometry as? Polygon)
            #expect(polygon.isValid)
        }
    }

    @Test
    func randomPolygonsMaxRadialLengthClamped() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 2.0, longitude: 2.0))
        // maxRadialLength=100 should be clamped to bbox half-width (1.0)
        let polygons = bbox.randomPolygons(count: 1, maxRadialLength: 100.0)
        #expect(polygons.features.count == 1)
    }

    @Test
    func randomLineStringsDefault() {
        let lines = BoundingBox.randomLineStrings()
        #expect(lines.features.count == 1)
        let ls = try! #require(lines.features[0].geometry as? LineString)
        #expect(ls.coordinates.count >= 2)
    }

    @Test
    func randomLineStringsCustomCount() {
        let lines = BoundingBox.randomLineStrings(count: 3)
        #expect(lines.features.count == 3)
        for feature in lines.features {
            #expect(feature.geometry is LineString)
        }
    }

    @Test
    func randomLineStringsInBbox() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let lines = bbox.randomLineStrings(count: 5, numVertices: 5, maxLength: 1.0)
        #expect(lines.features.count == 5)
        for feature in lines.features {
            let ls = try! #require(feature.geometry as? LineString)
            #expect(ls.coordinates.count == 5)
        }
    }

    @Test
    func randomLineStringsShortSegment() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 1.0, longitude: 1.0))
        let lines = bbox.randomLineStrings(count: 1, numVertices: 3, maxLength: 0.5, maxRotation: .pi)
        #expect(lines.features.count == 1)
        let ls = try! #require(lines.features[0].geometry as? LineString)
        #expect(ls.coordinates.count == 3)
    }

}
