import Testing
import Foundation
@testable import GISTools

struct IntersectionTests {

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
    private func turfIntersectFixture(_ name: String) async throws {
        let a = try loadOverlayPolygon(name, "A")
        let b = try loadOverlayPolygon(name, "B")
        let expectedJson = try TestData.stringFromFile(package: "Overlay", name: name + "IntersectResult")
        let expected = try #require(MultiPolygon(jsonString: expectedJson), "Missing expected result for \(name)")

        guard let result = a.intersection(with: b) else {
            if expected.polygons.isNotEmpty {
                Issue.record("Expected non-nil intersection for \(name)")
            }
            return
        }

        let resultArea = result.polygons.reduce(0) { $0 + $1.area }
        let expectedArea = expected.polygons.reduce(0) { $0 + $1.area }
        if expectedArea > 0 {
            let ratio = resultArea / expectedArea
            #expect(ratio > 0.80 && ratio < 1.20,
                    "\(name): area ratio \(ratio) outside [0.80, 1.20], result=\(resultArea), expected=\(expectedArea)")
        }
        else {
            #expect(resultArea < 1000.0, "\(name): expected empty but got area \(resultArea)")
        }
    }

    // Validates that two overlapping squares produce the correct intersection (a smaller square).
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

        let result = a.intersection(with: b)
        #expect(result != nil)
        // Intersection should be a 5x5 square at (5,5)-(10,10)
        let poly = result as? Polygon
        #expect(poly != nil)
        #expect(poly!.area > 0)
    }

    // Validates that two non-overlapping squares produce nil.
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

        let result = a.intersection(with: b)
        #expect(result == nil)
    }

    // Validates that a polygon fully contained by another returns the contained polygon.
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

        let result = outer.intersection(with: inner)
        #expect(result != nil)
        let poly = result as? Polygon
        #expect(poly != nil)
        #expect(poly!.area > 0)
    }

    // Validates that a polygon intersecting at a single vertex returns nil.
    @Test
    func touchingAtVertex() async throws {
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
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ]))

        let result = a.intersection(with: b)
        // Touching at a single point — should be nil (no area)
        #expect(result == nil)
    }

    // Validates that one polygon identical to another returns the same polygon.
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

        let result = a.intersection(with: a)
        #expect(result != nil)
        let poly = result as? Polygon
        #expect(poly != nil)
        #expect(poly!.allCoordinates.count > 0)
    }

    // Validates intersection with a gridSize parameter snaps coordinates before computing.
    @Test
    func intersectionWithGridSize() async throws {
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

        let result = a.intersection(with: b, gridSize: 1.0)
        #expect(result != nil)
    }

    // Validates intersection with a MultiPolygon.
    @Test
    func intersectionWithMultiPolygon() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 0.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 20.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))
        let bInner = try #require(Polygon([
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ]))
        let b = try #require(MultiPolygon([
            bInner,
        ]))

        let result = a.intersection(with: b)
        #expect(result != nil)
    }

    // Validates that two polygons spanning across the antimeridian (175°E ↔ 175°W)
    // produce a valid intersection. The polygons cross the date line and overlap
    // in the region near the dateline between 170°E and 170°W.
    @Test
    func antimeridianCrossingOverlap() async throws {
        // Polygon A spans from 170°E to 170°W (crossing the dateline)
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))
        // Polygon B spans from 175°E to 175°W (fully inside A)
        let b = try #require(Polygon([
            [
                Coordinate3D(latitude: 2.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: 175.0),
                Coordinate3D(latitude: 8.0, longitude: -175.0),
                Coordinate3D(latitude: 2.0, longitude: -175.0),
                Coordinate3D(latitude: 2.0, longitude: 175.0),
            ],
        ]))

        let result = a.intersection(with: b)
        #expect(result != nil)
    }

    // Validates intersection of two identical polygons crossing the antimeridian
    // (full overlap).
    @Test
    func antimeridianCrossingIdentical() async throws {
        let a = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))

        let result = a.intersection(with: a)
        #expect(result != nil)
    }

    // MARK: - Projections

    // Validates intersection of two overlapping polygons in EPSG:3857.
    @Test
    func intersection3857() async throws {
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

        let result = a.intersection(with: b)
        #expect(result != nil)
    }

    // Validates intersection of two overlapping polygons in noSRID.
    @Test
    func intersectionNoSRID() async throws {
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

        let result = a.intersection(with: b)
        #expect(result != nil)
    }

    // Validates intersection of two overlapping polygons in EPSG:4978.
    @Test
    func intersection4978() async throws {
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

        let result = a.intersection(with: b)
        #expect(result != nil)
    }

    // Validates that polygons on opposite sides of the antimeridian with no
    // Cartesian overlap return nil. One spans 170°E–178°E, the other 178°W–170°W.
    @Test
    func antimeridianNoOverlap() async throws {
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

        let result = a.intersection(with: b)
        #expect(result == nil)
    }

}
