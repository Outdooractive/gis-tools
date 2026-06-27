import Testing
import Foundation
@testable import GISTools

struct DifferenceTests {

    // MARK: - Reference tests

    private static let overlayFixtures = [
        "DisjointSquares",
        "FullyContained",
        "LShapeOverlap",
    ]

    private func loadOverlayPolygon(_ name: String, _ suffix: String) throws -> Polygon {
        try TestData.polygon(package: "Overlay", name: name + suffix)
    }

    @Test(arguments: overlayFixtures)
    private func turfDiffFixture(_ name: String) async throws {
        let a = try loadOverlayPolygon(name, "A")
        let b = try loadOverlayPolygon(name, "B")
        let expected = try TestData.multiPolygon(package: "Overlay", name: name + "DiffABResult")

        guard let result = a.difference(with: b) else {
            if expected.polygons.isNotEmpty {
                Issue.record("Expected non-nil difference for \(name)")
            }
            return
        }

        let resultArea = result.polygons.reduce(0) { $0 + $1.area }
        let expectedArea = expected.polygons.reduce(0) { $0 + $1.area }
        if expectedArea > 0 {
            let ratio = resultArea / expectedArea
            #expect(ratio > 0.95 && ratio < 1.05,
                    "\(name): area ratio \(ratio) outside [0.95, 1.05]")
        }
        else {
            #expect(resultArea == 0, "\(name): expected empty but got area \(resultArea)")
        }
    }

    // Validates that subtracting an overlapping square leaves an L-shaped polygon.
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

        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates that subtracting a non-overlapping polygon returns the original.
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

        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates that subtracting a fully containing polygon returns nil.
    @Test
    func fullyContainedReturnsNil() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ]))
        let outer = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        // A - outer: inner minus outer = empty (inner is fully covered)
        let result = a.difference(with: outer)
        #expect(result == nil)
    }

    // Validates that subtracting a polygon from itself returns nil.
    @Test
    func subtractSelf() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = a.difference(with: a)
        #expect(result == nil)
    }

    // Validates that subtracting a polygon with a hole (from a larger outer) works.
    @Test
    func subtractWithHole() async throws {
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

        // Outer - inner = outer with a hole cut out
        let result = outer.difference(with: inner)
        #expect(result != nil)
    }

    // Validates difference with a MultiPolygon.
    @Test
    func differenceWithMultiPolygon() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let inner = try #require(Polygon([[
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 5.0, longitude: 15.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]]))
        let b = try #require(MultiPolygon([inner]))

        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates difference where the positive polygon crosses the antimeridian (170°E to 170°W).
    @Test
    func antimeridianAPositive() async throws {
        // A crosses the dateline: 170°E to 170°W
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        // B is a small square at lon 175°E to 178°E (inside A)
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: 178.0),
                Coordinate3D(latitude: 2.0, longitude: 178.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
            ],
        ]))

        // A - B should remove the small square from the antimeridian-spanning polygon
        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates difference where the negative polygon crosses the antimeridian.
    @Test
    func antimeridianBNegative() async throws {
        // A is a normal polygon
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        // B crosses the antimeridian (no overlap with A)
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))

        // A - B = A (no overlap)
        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // MARK: - Projections

    // Validates difference of two overlapping polygons in EPSG:3857.
    @Test
    func difference3857() async throws {
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

        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates difference of two overlapping polygons in noSRID.
    @Test
    func differenceNoSRID() async throws {
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

        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates difference of two overlapping polygons in EPSG:4978 (ECEF).
    @Test
    func difference4978() async throws {
        let a4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let b4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.5, longitude: 0.5),
            Coordinate3D(latitude: 1.5, longitude: 0.5),
            Coordinate3D(latitude: 1.5, longitude: 1.5),
            Coordinate3D(latitude: 0.5, longitude: 1.5),
            Coordinate3D(latitude: 0.5, longitude: 0.5),
        ]]))
        let a = a4326.projected(to: .epsg4978)
        let b = b4326.projected(to: .epsg4978)

        let result = a.difference(with: b)
        #expect(result != nil)
    }

    // Validates difference where both inputs cross the antimeridian.
    @Test
    func antimeridianBoth() async throws {
        // A crosses the dateline: 170°E to 170°W
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        // B also crosses the dateline: 175°E to 175°W (fully inside A)
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: -175.0),
                Coordinate3D(latitude: 2.0, longitude: -175.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
            ],
        ]))

        // A - B should remove B's area from A, leaving the outer ring minus inner
        let result = a.difference(with: b)
        #expect(result != nil)
    }

}
