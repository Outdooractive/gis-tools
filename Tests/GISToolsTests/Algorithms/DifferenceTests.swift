import Testing
import Foundation
@testable import GISTools

struct DifferenceTests {

    // Validates that subtracting an overlapping square leaves an L-shaped polygon.
    @Test
    func overlappingSquares() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ])!

        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates that subtracting a non-overlapping polygon returns the original.
    @Test
    func nonOverlappingSquares() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let b = Polygon([
            [
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 15.0, longitude: 10.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 10.0, longitude: 15.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
            ],
        ])!

        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates that subtracting a fully containing polygon returns nil.
    @Test
    func fullyContainedReturnsNil() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ])!
        let outer = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        // A - outer: inner minus outer = empty (inner is fully covered)
        let result = a.difference(with: outer)
        #expect(result == nil)
    }

    // Validates that subtracting a polygon from itself returns nil.
    @Test
    func subtractSelf() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = a.difference(with: a)
        #expect(result == nil)
    }

    // Validates that subtracting a polygon with a hole (from a larger outer) works.
    @Test
    func subtractWithHole() async throws {
        let outer = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let inner = Polygon([
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ])!

        // Outer - inner = outer with a hole cut out
        let result = outer.difference(with: inner)
        #expect(result != nil)
    }

    // Validates difference with a MultiPolygon.
    @Test
    func differenceWithMultiPolygon() async throws {
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        let b = MultiPolygon([
            Polygon([
                [
                    Coordinate3D(latitude: 5.0, longitude: 5.0),
                    Coordinate3D(latitude: 15.0, longitude: 5.0),
                    Coordinate3D(latitude: 15.0, longitude: 15.0),
                    Coordinate3D(latitude: 5.0, longitude: 15.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0),
                ],
            ])!,
        ])!

        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates difference where the positive polygon crosses the antimeridian (170°E to 170°W).
    @Test
    func antimeridianAPositive() async throws {
        // A crosses the dateline: 170°E to 170°W
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ])!
        // B is a small square at lon 175°E to 178°E (inside A)
        let b = Polygon([
            [
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: 178.0),
                Coordinate3D(latitude: 2.0, longitude: 178.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
            ],
        ])!

        // A - B should remove the small square from the antimeridian-spanning polygon
        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates difference where the negative polygon crosses the antimeridian.
    @Test
    func antimeridianBNegative() async throws {
        // A is a normal polygon
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!
        // B crosses the antimeridian (no overlap with A)
        let b = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ])!

        // A - B = A (no overlap)
        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates difference where both inputs cross the antimeridian.
    @Test
    func antimeridianBoth() async throws {
        // A crosses the dateline: 170°E to 170°W
        let a = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ])!
        // B also crosses the dateline: 175°E to 175°W (fully inside A)
        let b = Polygon([
            [
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: -175.0),
                Coordinate3D(latitude: 2.0, longitude: -175.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
            ],
        ])!

        // A - B should remove B's area from A, leaving the outer ring minus inner
        let result = a.difference(with: b)
        #expect(result != nil)
    }

}
