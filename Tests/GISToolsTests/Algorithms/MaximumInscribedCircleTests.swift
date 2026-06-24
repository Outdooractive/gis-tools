import Foundation
@testable import GISTools
import Testing

struct MaximumInscribedCircleTests {

    // MARK: - Square

    // Tests the maximum inscribed circle for a square: center near (5,5), radius ~5° in meters.
    @Test
    func squareCircle() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let circle = try #require(polygon.maximumInscribedCircle())
        let radius = try #require(polygon.maximumInscribedRadius())

        #expect(radius > 0.0)
        // For a 10°×10° square the inscribed radius is ~5° ≈ 553 km
        #expect(radius > 500_000.0)
        #expect(radius < 600_000.0)
        #expect(circle.isValid)
        #expect(circle.projection == polygon.projection)
        #expect(circle.outerRing?.coordinates.count ?? 0 >= 4)
    }

    // Tests that the inscribed circle is fully contained inside the polygon.
    @Test
    func circleInsidePolygon() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let circle = try #require(polygon.maximumInscribedCircle())
        // Every vertex of the circle polygon should be inside the source polygon
        for coord in circle.outerRing?.coordinates ?? [] {
            #expect(polygon.contains(coord, ignoringBoundary: true) || polygon.covers(Point(coord)))
        }
    }

    // MARK: - Radius only

    @Test
    func radiusOnly() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let radius = try #require(polygon.maximumInscribedRadius())
        #expect(radius > 0.0)
    }

    // MARK: - L-shaped polygon

    // Tests the maximum inscribed circle for an L-shaped polygon is inside the polygon.
    @Test
    func lShapedCircle() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))

        let circle = try #require(polygon.maximumInscribedCircle())
        let radius = try #require(polygon.maximumInscribedRadius())

        #expect(radius > 0.0)
        #expect(circle.isValid)
        for coord in circle.outerRing?.coordinates ?? [] {
            #expect(polygon.contains(coord, ignoringBoundary: true) || polygon.covers(Point(coord)))
        }
    }

    // MARK: - Empty polygon

    @Test
    func emptyPolygon() {
        let polygon = Polygon()
        #expect(polygon.maximumInscribedCircle() == nil)
        #expect(polygon.maximumInscribedRadius() == nil)
    }

    // MARK: - Polygon with hole

    @Test
    func polygonWithHole() async throws {
        // Outer: 0-20, hole: 5-15 → inscribed circle radius ~5° in meters
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ]))

        let radius = try #require(polygon.maximumInscribedRadius())
        // The hole reduces the inscribed circle. Radius should be smaller than the no-hole case
        // but still positive.
        #expect(radius > 100_000.0)
        #expect(radius < 400_000.0)

        let circle = try #require(polygon.maximumInscribedCircle())
        #expect(circle.isValid)
    }

    // MARK: - gridSize

    @Test
    func circleWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))

        let gridSize = 0.001
        let snappedPolygon = polygon.snappedToGrid(tolerance: gridSize)
        // Both approaches should produce the same result
        let radiusWith = try #require(polygon.maximumInscribedRadius(gridSize: gridSize))
        let radiusManual = try #require(snappedPolygon.maximumInscribedRadius())
        #expect(abs(radiusWith - radiusManual) < 100.0)
    }

    // MARK: - MultiPolygon

    @Test
    func multiPolygon() async throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 25.0),
            Coordinate3D(latitude: 25.0, longitude: 25.0),
            Coordinate3D(latitude: 25.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]]))

        let multi = MultiPolygon(unchecked: [p1, p2])
        let circle = try #require(multi.maximumInscribedCircle())
        let radius = try #require(multi.maximumInscribedRadius())
        #expect(radius > 0.0)
        #expect(circle.isValid)
    }

    // MARK: - Projections

    @Test
    func circle3857() throws {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])

        let pole = try #require(polygon.poleOfInaccessibility())
        #expect(pole.coordinate.longitude.isFinite)
        #expect(pole.coordinate.latitude.isFinite)

        let segments = polygon.lineSegments
        #expect(segments.isNotEmpty)
        for seg in segments {
            let d = seg.distanceFrom(coordinate: pole.coordinate)
            #expect(d.isFinite, "NaN distance from segment \(seg.first) -> \(seg.second)")
        }

        let radius = try #require(polygon.maximumInscribedRadius())
        #expect(radius > 0.0)

        let circle = try #require(polygon.maximumInscribedCircle())
        #expect(circle.isValid)
    }

    @Test
    func circleNoSRID() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))

        let radius = try #require(polygon.maximumInscribedRadius())
        // noSRID distance is Euclidean in native units
        #expect(radius > 0.0)

        let circle = try #require(polygon.maximumInscribedCircle())
        #expect(circle.isValid)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        // Square crossing the antimeridian: 170° to -170° at equator
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: 170.0),
        ]]))

        let circle = try #require(polygon.maximumInscribedCircle())
        #expect(circle.isValid)
        #expect(circle.projection == polygon.projection)

        let radius = try #require(polygon.maximumInscribedRadius())
        #expect(radius > 0.0)
        // 20° of longitude at equator ≈ 10° inscribed radius ≈ 1100 km
        #expect(radius > 900_000.0)
        #expect(radius < 1_200_000.0)

        // Center should have a valid longitude (not NaN, not ±infinity)
        let center = try #require(polygon.poleOfInaccessibility())
        #expect(center.coordinate.longitude.isFinite)
    }

    @Test
    func antimeridian3857() throws {
        // Square crossing the antimeridian in EPSG:4326, projected to EPSG:3857
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: -10.0, longitude: 170.0),
        ]
        let coords3857 = coords4326.map { $0.projected(to: .epsg3857) }
        let polygon = try #require(Polygon([coords3857]))
        #expect(polygon.projection == .epsg3857)

        let circle = try #require(polygon.maximumInscribedCircle())
        #expect(circle.isValid)
        #expect(circle.projection == polygon.projection)

        let radius = try #require(polygon.maximumInscribedRadius())
        #expect(radius > 0.0)
    }

    @Test
    func antimeridian4978() throws {
        // Square crossing the antimeridian in EPSG:4326, projected to EPSG:4978.
        // Use a small shape and coarse precision so ECEF conversion overhead
        // does not slow down the polylabel search.
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: -1.0, longitude: 179.0),
            Coordinate3D(latitude: -1.0, longitude: -179.0),
            Coordinate3D(latitude: 1.0, longitude: -179.0),
            Coordinate3D(latitude: 1.0, longitude: 179.0),
            Coordinate3D(latitude: -1.0, longitude: 179.0),
        ]
        let coords4978 = coords4326.map { $0.projected(to: .epsg4978) }
        let polygon = Polygon(unchecked: [coords4978])
        #expect(polygon.projection == .epsg4978)

        // Pole of inaccessibility
        let pole = polygon.poleOfInaccessibility(precision: 10.0)
        #expect(pole != nil)
        #expect(pole?.coordinate.longitude.isFinite == true)
        #expect(pole?.coordinate.latitude.isFinite == true)

        // Maximum inscribed circle
        let circle = polygon.maximumInscribedCircle(precision: 10.0)
        #expect(circle != nil)
        #expect(circle?.projection == .epsg4978)

        let radius = polygon.maximumInscribedRadius(precision: 10.0)
        #expect(radius != nil)
        #expect(radius! > 0.0)
    }

    @Test
    func circle4978() async throws {
        let coords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let coords4978 = coords4326.map { $0.projected(to: .epsg4978) }
        let polygon = Polygon(unchecked: [coords4978])
        #expect(polygon.projection == .epsg4978)

        let circle = try #require(polygon.maximumInscribedCircle())
        #expect(circle.isValid)
        #expect(circle.projection == polygon.projection)

        let radius = try #require(polygon.maximumInscribedRadius())
        #expect(radius > 0.0)
    }

}
