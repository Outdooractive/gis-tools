import Foundation
@testable import GISTools
import Testing

struct SnapToGridTests {

    // MARK: - Point

    // Tests point snaps to nearest grid intersection.
    @Test
    func pointSnapsToNearest() async throws {
        let point = Point(Coordinate3D(latitude: 1.3, longitude: 2.7))
        let snapped = point.snappedToGrid(tolerance: 1.0)

        #expect(snapped.coordinate.latitude == 1.0)
        #expect(snapped.coordinate.longitude == 3.0)
    }

    // Tests point already on grid stays unchanged.
    @Test
    func pointSnapNoChange() async throws {
        let point = Point(Coordinate3D(latitude: 2.0, longitude: 4.0))
        let snapped = point.snappedToGrid(tolerance: 2.0)

        #expect(snapped.coordinate.latitude == 2.0)
        #expect(snapped.coordinate.longitude == 4.0)
    }

    // MARK: - Projections

    // Tests point snapping in EPSG:3857 (Web Mercator).
    @Test
    func pointEPSG3857() async throws {
        let point = Point(Coordinate3D(x: 1500.0, y: 2700.0))
        let snapped = point.snappedToGrid(tolerance: 1000.0)

        #expect(snapped.coordinate.x == 2000.0)
        #expect(snapped.coordinate.y == 3000.0)
        #expect(snapped.coordinate.projection == .epsg3857)
    }

    // Tests point snapping in EPSG:4978 (ECEF Cartesian).
    @Test
    func pointEPSG4978() async throws {
        let point = Point(Coordinate3D(
            latitude: 0.0135, longitude: 0.0243).projected(to: .epsg4978))
        let snapped = point.snappedToGrid(tolerance: 0.009)
        #expect(snapped.coordinate.projection == .epsg4978)
    }

    // Tests point snapping with noSRID projection.
    @Test
    func pointNoSRID() async throws {
        let point = Point(Coordinate3D(x: 7.7, y: 3.3, projection: .noSRID))
        let snapped = point.snappedToGrid(tolerance: 5.0)
        #expect(snapped.coordinate.projection == .noSRID)

        #expect(snapped.coordinate.x == 10.0)
        #expect(snapped.coordinate.y == 5.0)
    }

    // MARK: - LineString

    // Tests LineString snapping to grid.
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

    // Tests LineString deduplicates coincident points after snapping.
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

    // Tests LineString collapses to original when tolerance exceeds extent.
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

    // Tests Polygon snapping to grid.
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

    // Tests polygon ring deduplicates points after snapping.
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

    // Tests polygon collapses to original when tolerance exceeds extent.
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

    // Tests MultiPolygon snapping to grid.
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

    // Tests Feature snaps its geometry to grid.
    @Test
    func featureFanout() async throws {
        let point = Point(Coordinate3D(latitude: 1.3, longitude: 2.7))
        let feature = Feature(point)
        let snapped = feature.snappedToGrid(tolerance: 1.0)

        let snappedPoint = try #require(snapped.geometry as? Point)
        #expect(snappedPoint.coordinate.latitude == 1.0)
        #expect(snappedPoint.coordinate.longitude == 3.0)
    }

    // Tests FeatureCollection snaps all feature geometries.
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

    // Tests zero tolerance preserves original coordinates.
    @Test
    func zeroTolerance() async throws {
        let point = Point(Coordinate3D(latitude: 1.3, longitude: 2.7))
        let snapped = point.snappedToGrid(tolerance: 0.0)

        #expect(snapped.coordinate.latitude == 1.3)
        #expect(snapped.coordinate.longitude == 2.7)
    }

    // MARK: - Antimeridian

    // Tests LineString snapping near the antimeridian.
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

    // MARK: - Coordinate3D

    // Tests Coordinate3D snappedToGrid returns snapped copy.
    @Test
    func coordinate3DSnappedToGrid() async throws {
        let coord = Coordinate3D(latitude: 1.3, longitude: 2.7)
        let snapped = coord.snappedToGrid(tolerance: 1.0)

        #expect(snapped.latitude == 1.0)
        #expect(snapped.longitude == 3.0)
    }

    // Tests Coordinate3D snapToGrid mutates in place.
    @Test
    func coordinate3DSnapToGridMutating() async throws {
        var coord = Coordinate3D(latitude: 1.3, longitude: 2.7)
        coord.snapToGrid(tolerance: 1.0)

        #expect(coord.latitude == 1.0)
        #expect(coord.longitude == 3.0)
    }

    // Tests Coordinate3D on grid stays unchanged.
    @Test
    func coordinate3DSnapToGridNoChange() async throws {
        let coord = Coordinate3D(latitude: 2.0, longitude: 4.0)
        let snapped = coord.snappedToGrid(tolerance: 2.0)

        #expect(snapped.latitude == 2.0)
        #expect(snapped.longitude == 4.0)
    }

    // Tests snapping preserves altitude value.
    @Test
    func coordinate3DSnapToGridPreservesAltitude() async throws {
        let coord = Coordinate3D(latitude: 1.3, longitude: 2.7, altitude: 42.0)
        let snapped = coord.snappedToGrid(tolerance: 1.0)

        #expect(snapped.altitude == 42.0)
    }

    // MARK: - Ring

    // Tests Ring snapping to grid.
    @Test
    func ringSnappedToGrid() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.1, longitude: 0.2),
            Coordinate3D(latitude: 1.7, longitude: 0.3),
            Coordinate3D(latitude: 1.8, longitude: 1.9),
            Coordinate3D(latitude: 0.2, longitude: 1.8),
            Coordinate3D(latitude: 0.1, longitude: 0.2),
        ]))
        let snapped = ring.snappedToGrid(tolerance: 1.0)

        let coords = snapped.coordinates
        #expect(coords[0] == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(coords[1] == Coordinate3D(latitude: 2.0, longitude: 0.0))
        #expect(coords[2] == Coordinate3D(latitude: 2.0, longitude: 2.0))
        #expect(coords[3] == Coordinate3D(latitude: 0.0, longitude: 2.0))
        #expect(coords[4] == Coordinate3D(latitude: 0.0, longitude: 0.0))
    }

    // Tests Ring snapToGrid mutates in place.
    @Test
    func ringSnapToGridMutating() async throws {
        var ring = try #require(Ring([
            Coordinate3D(latitude: 0.1, longitude: 0.2),
            Coordinate3D(latitude: 1.7, longitude: 0.3),
            Coordinate3D(latitude: 0.2, longitude: 1.8),
            Coordinate3D(latitude: 0.1, longitude: 0.2),
        ]))
        ring.snapToGrid(tolerance: 1.0)

        #expect(ring.coordinates[0] == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(ring.coordinates[1] == Coordinate3D(latitude: 2.0, longitude: 0.0))
        #expect(ring.coordinates[2] == Coordinate3D(latitude: 0.0, longitude: 2.0))
    }

    // MARK: - LineSegment

    // Tests LineSegment snapping to grid.
    @Test
    func lineSegmentSnappedToGrid() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.3, longitude: 0.2),
            second: Coordinate3D(latitude: 1.7, longitude: 1.9))
        let snapped = segment.snappedToGrid(tolerance: 1.0)

        #expect(snapped.first.latitude == 0.0)
        #expect(snapped.first.longitude == 0.0)
        #expect(snapped.second.latitude == 2.0)
        #expect(snapped.second.longitude == 2.0)
    }

    // Tests LineSegment snapToGrid mutates in place.
    @Test
    func lineSegmentSnapToGridMutating() async throws {
        var segment = LineSegment(
            first: Coordinate3D(latitude: 0.3, longitude: 0.2),
            second: Coordinate3D(latitude: 1.7, longitude: 1.9))
        segment.snapToGrid(tolerance: 1.0)

        #expect(segment.first.latitude == 0.0)
        #expect(segment.first.longitude == 0.0)
        #expect(segment.second.latitude == 2.0)
        #expect(segment.second.longitude == 2.0)
    }

    // Tests LineSegment snapping preserves index property.
    @Test
    func lineSegmentSnapPreservesIndex() async throws {
        let segment = LineSegment(
            first: Coordinate3D(latitude: 0.3, longitude: 0.2),
            second: Coordinate3D(latitude: 1.7, longitude: 1.9),
            index: 3)
        let snapped = segment.snappedToGrid(tolerance: 1.0)

        #expect(snapped.index == 3)
    }

    // MARK: - BoundingBox

    // Tests BoundingBox snapping to grid.
    @Test
    func boundingBoxSnappedToGrid() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 1.3, longitude: 2.7),
            northEast: Coordinate3D(latitude: 5.6, longitude: 8.4))
        let snapped = bbox.snappedToGrid(tolerance: 1.0)

        #expect(snapped.southWest.latitude == 1.0)
        #expect(snapped.southWest.longitude == 3.0)
        #expect(snapped.northEast.latitude == 6.0)
        #expect(snapped.northEast.longitude == 8.0)
    }

    // Tests BoundingBox snapToGrid mutates in place.
    @Test
    func boundingBoxSnapToGridMutating() async throws {
        var bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 1.3, longitude: 2.7),
            northEast: Coordinate3D(latitude: 5.6, longitude: 8.4))
        bbox.snapToGrid(tolerance: 1.0)

        #expect(bbox.southWest.latitude == 1.0)
        #expect(bbox.southWest.longitude == 3.0)
        #expect(bbox.northEast.latitude == 6.0)
        #expect(bbox.northEast.longitude == 8.0)
    }

}
