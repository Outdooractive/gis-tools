import Foundation
@testable import GISTools
import Testing

/// Overlay operations on polygons that cross the antimeridian.
struct OverlayAntimeridianTests {

    private func crossingPolygon(
        latitude: ClosedRange<Double>,
        westLongitude: Double = 170.0,
        eastLongitude: Double = -170.0
    ) throws -> Polygon {
        try #require(Polygon([[
            Coordinate3D(latitude: latitude.lowerBound, longitude: westLongitude),
            Coordinate3D(latitude: latitude.lowerBound, longitude: eastLongitude),
            Coordinate3D(latitude: latitude.upperBound, longitude: eastLongitude),
            Coordinate3D(latitude: latitude.upperBound, longitude: westLongitude),
            Coordinate3D(latitude: latitude.lowerBound, longitude: westLongitude),
        ]]))
    }

    private func crossingPolygonWithHole() throws -> Polygon {
        try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 20.0, longitude: -170.0),
                Coordinate3D(latitude: 20.0, longitude: 170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 175.0),
                Coordinate3D(latitude: 5.0, longitude: -175.0),
                Coordinate3D(latitude: 15.0, longitude: -175.0),
                Coordinate3D(latitude: 15.0, longitude: 175.0),
                Coordinate3D(latitude: 5.0, longitude: 175.0),
            ],
        ]))
    }

    // Intersecting a crossing polygon with itself returns the original area.
    @Test
    func intersectionIdentical() throws {
        let polygon = try crossingPolygon(latitude: 0.0 ... 10.0)
        let result = try #require(polygon.intersection(with: polygon))

        #expect(result.coversCoordinate(Coordinate3D(latitude: 5.0, longitude: 180.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 5.0, longitude: 172.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 20.0, longitude: 180.0)) == false)
    }

    // Intersection across the seam keeps only the overlapping area.
    @Test
    func intersectionOverlap() throws {
        let a = try crossingPolygon(latitude: 0.0 ... 10.0)
        let b = try crossingPolygon(latitude: 5.0 ... 15.0)
        let result = try #require(a.intersection(with: b))

        #expect(result.coversCoordinate(Coordinate3D(latitude: 7.0, longitude: 180.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 2.0, longitude: 175.0)) == false)
        #expect(result.coversCoordinate(Coordinate3D(latitude: 12.0, longitude: 175.0)) == false)
    }

    // A polygon inside the antimeridian-crossing hole does not intersect.
    @Test
    func intersectionInsideCrossingHole() throws {
        let polygon = try crossingPolygonWithHole()
        let inHole = try crossingPolygon(
            latitude: 6.0 ... 14.0,
            westLongitude: 176.0,
            eastLongitude: -176.0)

        #expect(polygon.intersection(with: inHole) == nil)
    }

    // Union across the seam covers both inputs.
    @Test
    func unionOverlap() throws {
        let a = try crossingPolygon(latitude: 0.0 ... 10.0)
        let b = try crossingPolygon(latitude: 5.0 ... 15.0)
        let result = try #require(a.union(with: b))

        #expect(result.coversCoordinate(Coordinate3D(latitude: 2.0, longitude: 172.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 12.0, longitude: 172.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 8.0, longitude: 180.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 20.0, longitude: 180.0)) == false)
    }

    // Union fills a hole that crosses the antimeridian.
    @Test
    func unionFillsCrossingHole() throws {
        let polygon = try crossingPolygonWithHole()
        let hole = try crossingPolygon(
            latitude: 5.0 ... 15.0,
            westLongitude: 175.0,
            eastLongitude: -175.0)
        let result = try #require(polygon.union(with: hole))

        #expect(result.coversCoordinate(Coordinate3D(latitude: 10.0, longitude: 180.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 2.0, longitude: 180.0)))
    }

    // Difference removes a crossing polygon from the crossing polygon.
    @Test
    func differenceInner() throws {
        let a = try crossingPolygon(latitude: 0.0 ... 10.0)
        let b = try crossingPolygon(latitude: 2.0 ... 8.0, westLongitude: 175.0, eastLongitude: -175.0)
        let result = try #require(a.difference(with: b))

        #expect(result.coversCoordinate(Coordinate3D(latitude: 1.0, longitude: 172.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 5.0, longitude: 180.0)) == false)
        #expect(result.coversCoordinate(Coordinate3D(latitude: 20.0, longitude: 180.0)) == false)
    }

    // Symmetric difference keeps the non-overlapping parts.
    @Test
    func symmetricDifferenceOverlap() throws {
        let a = try crossingPolygon(latitude: 0.0 ... 10.0)
        let b = try crossingPolygon(latitude: 5.0 ... 15.0)
        let result = try #require(a.symmetricDifference(with: b))

        #expect(result.coversCoordinate(Coordinate3D(latitude: 2.0, longitude: 172.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 12.0, longitude: 172.0)))
        #expect(result.coversCoordinate(Coordinate3D(latitude: 8.0, longitude: 180.0)) == false)
    }

    // Overlay works in EPSG:3857 without reprojecting the inputs.
    @Test
    func intersection3857Crossing() throws {
        let a = try crossingPolygon(latitude: 0.0 ... 10.0).projected(to: .epsg3857)
        let b = try crossingPolygon(latitude: 5.0 ... 15.0).projected(to: .epsg3857)
        let result = try #require(a.intersection(with: b))
        let probe = Coordinate3D(latitude: 7.0, longitude: 180.0).projected(to: .epsg3857)

        #expect(result.coversCoordinate(probe))
    }

}

private extension PolygonGeometry {

    func coversCoordinate(_ coordinate: Coordinate3D) -> Bool {
        covers(coordinate, gridSize: nil)
    }

}
