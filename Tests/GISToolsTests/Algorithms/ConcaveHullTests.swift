import Foundation
@testable import GISTools
import Testing

struct ConcaveHullTests {

    // MARK: - Reference tests

    private static let concaveFixtures: [(name: String, maxEdgeKm: Double)] = [
        ("LineWithNoise", 200.0),
    ]

    @Test(arguments: concaveFixtures)
    private func turfConcaveHullFixture(_ fixture: (name: String, maxEdgeKm: Double)) async throws {
        let mp = try TestData.multiPoint(package: "ConcaveHull", name: fixture.name)
        let maxEdge = GISTool.convertToMeters(fixture.maxEdgeKm, .kilometers)

        guard let result = mp.concaveHull(maxEdgeLength: maxEdge) else {
            Issue.record("Expected non-nil concave hull for \(fixture.name)")
            return
        }

        #expect(result.polygons.isNotEmpty, "\(fixture.name): hull has no polygons")
        for poly in result.polygons {
            #expect(poly.isStructurallyValid, "\(fixture.name): hull polygon is invalid")
        }
    }

    // Validates basic concave hull of points forming a rough circle.
    @Test
    func concaveHullBasic() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 0.5),
        ]))

        let maxEdge200km = GISTool.convertToMeters(200, .kilometers)

        let hull = try #require(mp.concaveHull(maxEdgeLength: maxEdge200km))
        #expect(hull.polygons.isNotEmpty)
    }

    // Validates that a large maxEdgeLength approximates the convex hull.
    @Test
    func concaveHullLargeMaxEdge() async throws {
        let maxEdge2000km = GISTool.convertToMeters(2000, .kilometers)

        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))

        let hull = try #require(mp.concaveHull(maxEdgeLength: maxEdge2000km))
        let coords = try #require(hull.polygons.first?.outerRing?.coordinates)
        #expect(coords.count >= 4) // at least the 4 corners
    }

    // Validates that insufficient points returns nil.
    @Test
    func concaveHullInsufficientPoints() async throws {
        let maxEdge100km = GISTool.convertToMeters(100, .kilometers)

        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        #expect(mp.concaveHull(maxEdgeLength: maxEdge100km) == nil)
    }

    // Validates that a very small maxEdgeLength returns nil (no triangles pass the filter).
    @Test
    func concaveHullTooSmallMaxEdge() async throws {
        let maxEdge1m = GISTool.convertToMeters(1, .meters)

        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))

        let hull = mp.concaveHull(maxEdgeLength: maxEdge1m)
        #expect(hull == nil)
    }

    // Validates concave hull from a LineString works.
    @Test
    func concaveHullLineString() async throws {
        let maxEdge200km = GISTool.convertToMeters(200, .kilometers)

        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))

        let hull = try #require(ls.concaveHull(maxEdgeLength: maxEdge200km))
        #expect(hull.polygons.isNotEmpty)
    }

    // Validates concave hull from a Feature works.
    @Test
    func concaveHullFeature() async throws {
        let maxEdge200km = GISTool.convertToMeters(200, .kilometers)

        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let feature = Feature(mp)
        let hull = try #require(feature.concaveHull(maxEdgeLength: maxEdge200km))
        #expect(hull.polygons.isNotEmpty)
    }

    // Validates concave hull of points straddling the antimeridian.
    @Test
    func concaveHullCrossingAntimeridian() async throws {
        let maxEdge3000km = GISTool.convertToMeters(3000, .kilometers)

        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 175.0),
            Coordinate3D(latitude: 10.0, longitude: -175.0),
            Coordinate3D(latitude: 5.0, longitude: 180.0),
        ]))

        let hull = try #require(mp.concaveHull(maxEdgeLength: maxEdge3000km))
        #expect(hull.polygons.isNotEmpty)
    }

    // Validates that the concave hull contains all input points.
    @Test
    func concaveHullContainsAllPoints() async throws {
        let maxEdge200km = GISTool.convertToMeters(200, .kilometers)

        let inputPoints = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]
        let mp = try #require(MultiPoint(inputPoints))

        let hull = try #require(mp.concaveHull(maxEdgeLength: maxEdge200km))
        let polygon = try #require(hull.polygons.first)

        for point in inputPoints {
            #expect(polygon.covers(point))
        }
    }

    // MARK: - Grid size

    // MARK: - Projections

    // Verifies concave hull of points in EPSG:3857.
    @Test
    func concaveHull3857() throws {
        guard let mp = MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1_000.0, projection: .epsg3857),
            Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857),
        ])
        else {
            Issue.record("Failed to create MultiPoint")
            return
        }
        guard let hull = mp.concaveHull(maxEdgeLength: 10_000.0)
        else {
            Issue.record("concaveHull returned nil")
            return
        }
        #expect(hull.polygons.count >= 1)
        #expect(hull.polygons[0].isStructurallyValid)
    }

    // Validates that `concaveHull(maxEdgeLength:gridSize:)` matches manual pre-snapping.
    @Test
    func concaveHullWithGridSize() async throws {
        let maxEdge200km = GISTool.convertToMeters(200, .kilometers)
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 1.0001),
            Coordinate3D(latitude: 1.0001, longitude: 1.0001),
            Coordinate3D(latitude: 1.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.5001, longitude: 0.5001),
        ]))
        let gridSize = 0.001

        let withParam = try #require(mp.concaveHull(maxEdgeLength: maxEdge200km, gridSize: gridSize))
        let snapped = mp.snappedToGrid(tolerance: gridSize)
        let manual = try #require(snapped.concaveHull(maxEdgeLength: maxEdge200km))
        #expect(withParam.polygons.count == manual.polygons.count)
        #expect(abs(withParam.area - manual.area) < 1.0)
    }


    // Validates concave hull in EPSG:4978 projection.
    @Test
    func concaveHull4978() async throws {
        // Three points on the Earth's surface — concaveHull returns the single
        // triangle directly (no union, so no 4978→3857 projection round-trip).
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let b = Coordinate3D(latitude: 1.0, longitude: 0.0).projected(to: .epsg4978)
        let c = Coordinate3D(latitude: 0.0, longitude: 1.0).projected(to: .epsg4978)
        let mp = try #require(MultiPoint([a, b, c]))
        let hull = try #require(mp.concaveHull(maxEdgeLength: GISTool.convertToMeters(500, .kilometers)))
        #expect(hull.polygons.isNotEmpty)
    }


    // Validates concave hull in noSRID projection.
    @Test
    func concaveHullNoSRID() throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 5.0, projection: .noSRID),
        ]))
        let hull = try #require(mp.concaveHull(maxEdgeLength: 100_000.0))
        #expect(hull.polygons.isNotEmpty)
    }

}

    // A larger mesh exercises the direct triangle-boundary assembly path.
    @Test
    func concaveHullLargeMesh() throws {
        struct Random {
            var state: UInt64 = 123

            mutating func next(in range: ClosedRange<Double>) -> Double {
                state = (state &* 6_364_136_223_846_793_005) &+ 1_442_695_040_888_963_407
                let value = Double(state >> 11) / Double(1 << 53)
                return range.lowerBound + value * (range.upperBound - range.lowerBound)
            }
        }

        var random = Random()
        let inputPoints = (0 ..< 1_000).map { _ in
            Coordinate3D(
                latitude: random.next(in: 0.0 ... 10.0),
                longitude: random.next(in: 0.0 ... 10.0))
        }
        let mp = try #require(MultiPoint(inputPoints))
        let hull = try #require(mp.concaveHull(maxEdgeLength: 2_000_000.0))

        #expect(hull.polygons.isNotEmpty)
        #expect(hull.polygons.allSatisfy { $0.isStructurallyValid })

        for point in inputPoints {
            #expect(hull.polygons.contains { $0.covers(point) })
        }
    }
