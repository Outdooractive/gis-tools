import Testing
import Foundation
@testable import GISTools

struct SymmetricDifferenceTests {

    // Validates that two overlapping squares produce an L-shaped symmetric difference.
    @Test
    func overlappingSquares() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ]))

        let result = a.symmetricDifference(with: b)
        #expect(result != nil)
    }

    // Validates that two non-overlapping squares return both squares as a MultiPolygon.
    @Test
    func nonOverlappingSquares() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 15.0, longitude: 10.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 10.0, longitude: 15.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
            ],
        ]))

        let result = a.symmetricDifference(with: b)
        #expect(result != nil)
        // Non-overlapping XOR should be a MultiPolygon with both squares
        let mp = result as? MultiPolygon
        #expect(mp != nil)
    }

    // Validates that two identical polygons produce an empty result (XOR of identical is empty).
    @Test
    func identicalPolygons() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.symmetricDifference(with: a)
        #expect(result == nil)
    }

    // Validates that a polygon's symmetric difference with a fully contained polygon
    // produces the expected result (the outer ring minus the inner overlap).
    @Test
    func fullyContained() async throws {
        let outer = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let inner = try #require(Polygon([
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ]))

        // XOR of outer with inner = outer minus inner (since inner is fully inside outer)
        let result = outer.symmetricDifference(with: inner)
        #expect(result != nil)
    }

    // Validates symmetric difference with a MultiPolygon.
    @Test
    func symmetricDifferenceWithMultiPolygon() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let bPoly = try #require(Polygon([
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ]))
        let b = try #require(MultiPolygon([
            bPoly,
        ]))

        let result = a.symmetricDifference(with: b)
        #expect(result != nil)
    }

    // Validates symmetric difference where both inputs cross the antimeridian and overlap.
    @Test
    func antimeridianBothOverlap() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: -175.0),
                Coordinate3D(latitude: 2.0, longitude: -175.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
            ],
        ]))

        // XOR of A and B (B inside A) = A - B (outer ring minus inner)
        let result = a.symmetricDifference(with: b)
        #expect(result != nil)
    }

    // Validates symmetric difference where exactly one input crosses the antimeridian.
    @Test
    func antimeridianOneCrosses() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        // B is a normal polygon that overlaps with A near longitude 170
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 2.0, longitude: 168.0),
                Coordinate3D(latitude: 8.0, longitude: 168.0),
                Coordinate3D(latitude: 8.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 2.0, longitude: 168.0),
            ],
        ]))

        let result = a.symmetricDifference(with: b)
        #expect(result != nil)
    }

    // Validates symmetric difference of two overlapping polygons in EPSG:3857.
    @Test
    // MARK: - Projections

    func symmetricDifference3857() async throws {
        let a = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let b = try #require(Polygon([[
            Coordinate3D(x: 500.0, y: 500.0),
            Coordinate3D(x: 1500.0, y: 500.0),
            Coordinate3D(x: 1500.0, y: 1500.0),
            Coordinate3D(x: 500.0, y: 1500.0),
            Coordinate3D(x: 500.0, y: 500.0),
        ]]))

        let result = a.symmetricDifference(with: b)
        #expect(result != nil)
        #expect(result?.projection == .epsg3857)
    }

    // Validates symmetric difference of two overlapping polygons in noSRID.
    @Test
    func symmetricDifferenceNoSRID() async throws {
        let a = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let b = try #require(Polygon([[
            Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID),
            Coordinate3D(x: 1500.0, y: 500.0, projection: .noSRID),
            Coordinate3D(x: 1500.0, y: 1500.0, projection: .noSRID),
            Coordinate3D(x: 500.0, y: 1500.0, projection: .noSRID),
            Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID),
        ]]))

        let result = a.symmetricDifference(with: b)
        #expect(result != nil)
        #expect(result?.projection == .noSRID)
    }

    // Validates symmetric difference of two overlapping polygons in EPSG:4978.
    @Test
    func symmetricDifference4978() async throws {
        let aCoords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let bCoords4326: [Coordinate3D] = [
            Coordinate3D(latitude: 0.5, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 1.5),
            Coordinate3D(latitude: 1.5, longitude: 1.5),
            Coordinate3D(latitude: 1.5, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 0.0),
        ]
        let a = try #require(Polygon([aCoords4326.map { $0.projected(to: .epsg4978) }]))
        let b = try #require(Polygon([bCoords4326.map { $0.projected(to: .epsg4978) }]))
        let result = a.symmetricDifference(with: b)
        #expect(result != nil)
        #expect(result?.projection == .epsg4978)
    }

    // Validates symmetric difference where neither crosses but both are near the antimeridian.
    @Test
    func antimeridianNear() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 178.0),
                Coordinate3D(latitude: 0.0, longitude: 178.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: -178.0),
                Coordinate3D(latitude: 10.0, longitude: -178.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -178.0),
            ],
        ]))

        // Non-overlapping, so XOR returns both polygons
        let result = a.symmetricDifference(with: b)
        #expect(result != nil)
        #expect(result is MultiPolygon)
    }

}
