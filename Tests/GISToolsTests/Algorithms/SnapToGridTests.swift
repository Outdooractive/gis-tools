import Foundation
@testable import GISTools
import Testing

struct SnapToGridTests {

    // MARK: - Point

    @Test
    func pointSnapsToNearest() async throws {
        let point = Point(Coordinate3D(latitude: 1.3, longitude: 2.7))
        let snapped = point.snappedToGrid(tolerance: 1.0)

        #expect(snapped.coordinate.latitude == 1.0)
        #expect(snapped.coordinate.longitude == 3.0)
    }

    @Test
    func pointSnapNoChange() async throws {
        let point = Point(Coordinate3D(latitude: 2.0, longitude: 4.0))
        let snapped = point.snappedToGrid(tolerance: 2.0)

        #expect(snapped.coordinate.latitude == 2.0)
        #expect(snapped.coordinate.longitude == 4.0)
    }

    @Test
    func pointEPSG3857() async throws {
        let point = Point(Coordinate3D(x: 1500.0, y: 2700.0, projection: .epsg3857))
        let snapped = point.snappedToGrid(tolerance: 1000.0)

        #expect(snapped.coordinate.x == 2000.0)
        #expect(snapped.coordinate.y == 3000.0)
    }

    @Test
    func pointNoSRID() async throws {
        let point = Point(Coordinate3D(x: 7.7, y: 3.3, projection: .noSRID))
        let snapped = point.snappedToGrid(tolerance: 5.0)

        #expect(snapped.coordinate.x == 10.0)
        #expect(snapped.coordinate.y == 5.0)
    }

    // MARK: - LineString

    @Test
    func lineStringSnap() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.3, longitude: 0.2),
            Coordinate3D(latitude: 1.7, longitude: 1.9),
            Coordinate3D(latitude: 3.4, longitude: 3.6),
        ]))
        let snapped = line.snappedToGrid(tolerance: 1.0)

        let coords = snapped.coordinates
        #expect(coords[0].latitude == 0.0)
        #expect(coords[0].longitude == 0.0)
        #expect(coords[1].latitude == 2.0)
        #expect(coords[1].longitude == 2.0)
        #expect(coords[2].latitude == 3.0)
        #expect(coords[2].longitude == 4.0)
    }

    @Test
    func lineStringDedup() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.1, longitude: 0.2),
            Coordinate3D(latitude: 0.4, longitude: 0.3),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]))
        let snapped = line.snappedToGrid(tolerance: 1.0)

        #expect(snapped.coordinates.count == 2)
        #expect(snapped.coordinates[0] == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(snapped.coordinates[1] == Coordinate3D(latitude: 2.0, longitude: 2.0))
    }

    @Test
    func lineStringCollapse() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.1, longitude: 0.2),
            Coordinate3D(latitude: 0.4, longitude: 0.3),
        ]))
        let snapped = line.snappedToGrid(tolerance: 10.0)

        #expect(snapped.coordinates == line.coordinates)
    }

    // MARK: - Polygon

    @Test
    func polygonSnap() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.1, longitude: 0.2),
            Coordinate3D(latitude: 1.7, longitude: 0.3),
            Coordinate3D(latitude: 1.8, longitude: 1.9),
            Coordinate3D(latitude: 0.2, longitude: 1.8),
            Coordinate3D(latitude: 0.1, longitude: 0.2),
        ]]))
        let snapped = polygon.snappedToGrid(tolerance: 1.0)

        let ring = try #require(snapped.outerRing)
        let coords = ring.coordinates
        #expect(coords[0] == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(coords[1] == Coordinate3D(latitude: 2.0, longitude: 0.0))
        #expect(coords[2] == Coordinate3D(latitude: 2.0, longitude: 2.0))
        #expect(coords[3] == Coordinate3D(latitude: 0.0, longitude: 2.0))
        #expect(coords[4] == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(snapped.isValid)
    }

    @Test
    func polygonRingDedup() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.1, longitude: 0.2),
            Coordinate3D(latitude: 0.3, longitude: 0.4),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.1, longitude: 0.2),
        ]]))
        let snapped = polygon.snappedToGrid(tolerance: 1.0)

        #expect(snapped.outerRing?.coordinates.count == 4)
    }

    @Test
    func polygonCollapse() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.1, longitude: 0.2),
            Coordinate3D(latitude: 0.3, longitude: 0.4),
            Coordinate3D(latitude: 0.6, longitude: 0.5),
            Coordinate3D(latitude: 0.1, longitude: 0.2),
        ]]))
        let snapped = polygon.snappedToGrid(tolerance: 10.0)

        #expect(snapped.outerRing?.coordinates == polygon.outerRing?.coordinates)
    }

    // MARK: - Multi geometries

    @Test
    func multiPolygonSnap() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.1, longitude: 0.2),
            Coordinate3D(latitude: 1.7, longitude: 0.3),
            Coordinate3D(latitude: 0.2, longitude: 1.8),
            Coordinate3D(latitude: 0.1, longitude: 0.2),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 4.1, longitude: 4.2),
            Coordinate3D(latitude: 5.7, longitude: 4.3),
            Coordinate3D(latitude: 4.2, longitude: 5.8),
            Coordinate3D(latitude: 4.1, longitude: 4.2),
        ]]))
        let mp = try #require(MultiPolygon([poly1, poly2]))
        let snapped = mp.snappedToGrid(tolerance: 1.0)

        #expect(snapped.polygons.count == 2)
        for polygon in snapped.polygons {
            for coord in polygon.allCoordinates {
                #expect(coord.latitude.truncatingRemainder(dividingBy: 1.0) == 0.0)
                #expect(coord.longitude.truncatingRemainder(dividingBy: 1.0) == 0.0)
            }
        }
    }

    // MARK: - Feature / FeatureCollection

    @Test
    func featureFanout() async throws {
        let point = Point(Coordinate3D(latitude: 1.3, longitude: 2.7))
        let feature = Feature(point)
        let snapped = feature.snappedToGrid(tolerance: 1.0)

        let snappedPoint = try #require(snapped.geometry as? Point)
        #expect(snappedPoint.coordinate.latitude == 1.0)
        #expect(snappedPoint.coordinate.longitude == 3.0)
    }

    @Test
    func featureCollectionFanout() async throws {
        let point1 = Point(Coordinate3D(latitude: 1.3, longitude: 2.7))
        let point2 = Point(Coordinate3D(latitude: 4.6, longitude: 5.2))
        let fc = FeatureCollection([point1, point2])
        let snapped = fc.snappedToGrid(tolerance: 1.0)

        let snapped1 = try #require(snapped.features[0].geometry as? Point)
        let snapped2 = try #require(snapped.features[1].geometry as? Point)
        #expect(snapped1.coordinate.latitude == 1.0)
        #expect(snapped1.coordinate.longitude == 3.0)
        #expect(snapped2.coordinate.latitude == 5.0)
        #expect(snapped2.coordinate.longitude == 5.0)
    }

    // MARK: - Zero tolerance

    @Test
    func zeroTolerance() async throws {
        let point = Point(Coordinate3D(latitude: 1.3, longitude: 2.7))
        let snapped = point.snappedToGrid(tolerance: 0.0)

        #expect(snapped.coordinate.latitude == 1.3)
        #expect(snapped.coordinate.longitude == 2.7)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.3, longitude: 177.7),
            Coordinate3D(latitude: 9.8, longitude: -174.2),
        ]))
        let snapped = line.snappedToGrid(tolerance: 1.0)

        #expect(snapped.coordinates[0].latitude == 0.0)
        #expect(snapped.coordinates[0].longitude == 178.0)
        #expect(snapped.coordinates[1].latitude == 10.0)
        #expect(snapped.coordinates[1].longitude == -174.0)
    }

}
