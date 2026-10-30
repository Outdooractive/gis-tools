import Foundation
@testable import GISTools
import Testing

/// Direct tests for the internal overlay edge/ring assembly.
struct OverlayTests {

    private func square(_ minX: Double, _ maxX: Double) -> Polygon {
        Polygon(unchecked: [[
            Coordinate3D(x: minX, y: 0.0, projection: .noSRID),
            Coordinate3D(x: maxX, y: 0.0, projection: .noSRID),
            Coordinate3D(x: maxX, y: 10.0, projection: .noSRID),
            Coordinate3D(x: minX, y: 10.0, projection: .noSRID),
            Coordinate3D(x: minX, y: 0.0, projection: .noSRID),
        ]])
    }

    @Test
    func polygonsFromBoundaryEdgesAssemblesClosedRing() {
        let coordinates = [
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]
        let edges = zip(coordinates, coordinates.dropFirst()).map {
            (start: $0.0, end: $0.1)
        }
        let polygons = Overlay.polygons(fromBoundaryEdges: edges)

        #expect(polygons.count == 1)
        #expect(abs(polygons[0].area - 100.0) < 0.000001)
        #expect(polygons[0].isValid)
    }

    @Test
    func openBoundaryEdgesDoNotAssemblePolygon() {
        let a = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let b = Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID)
        let c = Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID)
        let polygons = Overlay.polygons(fromBoundaryEdges: [
            (start: a, end: b),
            (start: b, end: c),
        ])
        #expect(polygons.isEmpty)
    }

    @Test
    func overlayPolygonsWithUnionBoundaryTestMatchesUnionArea() throws {
        let first = square(0.0, 10.0)
        let second = square(5.0, 15.0)
        let expected = try #require(first.union(with: second))
        let boundaryTest = Overlay.makeBoundaryTest { point, polygons in
            polygons.contains(point, in: 0 ..< polygons.polygons.count)
        }
        let result = try #require(Overlay.overlayPolygons(
            [first, second],
            boundaryTest: boundaryTest))

        #expect(result.polygons.count == expected.polygons.count)
        #expect(abs(result.area - expected.area) < 0.000001)
        #expect(result.isValid)
    }

    // MARK: - Non-finite input

    /// The overlay grid must never trap on a non-finite bound.
    ///
    /// A latitude of −90° projects to `-infinity` in EPSG:3857, which used to
    /// make the grid's cell size NaN and trap on the `Int` conversion. The
    /// index is built directly here so the guard is exercised without running
    /// the full overlay on a pathological polygon.
    @Test
    func polygonIndexWithInfiniteBoundsDoesNotTrap() {
        let infinite = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: .infinity, projection: .noSRID),
            Coordinate3D(x: 0.0, y: .infinity, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]])
        let index = Overlay.PolygonIndex([infinite])

        // Must return without trapping.
        _ = index.contains(Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID))
        _ = index.contains(Coordinate3D(x: 5.0, y: .infinity, projection: .noSRID))
        _ = index.contains(Coordinate3D(x: .nan, y: .nan, projection: .noSRID))
    }

    /// The overlay grid must never trap on a NaN bound either.
    @Test
    func polygonIndexWithNaNBoundsDoesNotTrap() {
        let nan = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: .nan, projection: .noSRID),
            Coordinate3D(x: 0.0, y: .nan, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]])
        let index = Overlay.PolygonIndex([nan])

        _ = index.contains(Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID))
        _ = index.contains(Coordinate3D(x: .nan, y: .nan, projection: .noSRID))
    }

    /// A non-finite coordinate in an overlay input is replaced with the Web
    /// Mercator limit, so the overlay math never sees infinities or NaN.
    @Test
    func overlaySanitizesNonFiniteCoordinates() {
        let finite = square(0.0, 10.0)
        let infinite = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: .infinity, projection: .noSRID),
            Coordinate3D(x: 0.0, y: .infinity, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]])

        let sanitized = Overlay.sanitizedForOverlay([finite, infinite])
        #expect(sanitized.count == 2)
        // The finite polygon is returned unchanged.
        #expect(sanitized[0].coordinates == finite.coordinates)
        // The infinite coordinate is clamped to the Mercator limit.
        // swiftformat:disable:next preferKeyPath
        #expect(sanitized[1].allCoordinates.allSatisfy({ $0.y.isFinite }))
        #expect(sanitized[1].allCoordinates.contains { abs($0.y - GISTool.originShift) < 0.000001 })
    }

}
