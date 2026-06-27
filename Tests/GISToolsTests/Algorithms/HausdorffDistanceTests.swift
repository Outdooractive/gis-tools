import Testing
import Foundation
@testable import GISTools

struct HausdorffDistanceTests {

    // Validates that identical geometries have zero Hausdorff distance.
    @Test
    func identicalLines() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))

        let dist = a.hausdorffDistance(from: b)
        #expect(dist == 0.0)
    }

    // Validates that a line and its shifted version have the expected distance.
    @Test
    func parallelShifted() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 10.0),
            Coordinate3D(latitude: 1.0, longitude: 20.0),
        ]))

        let dist = a.hausdorffDistance(from: b)
        // Approx 111 km per degree of latitude at the equator
        #expect(dist > 100_000.0)
        #expect(dist < 120_000.0)
    }

    // Validates that far apart geometries have a large Hausdorff distance.
    @Test
    func farApart() async throws {
        let a = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let b = Point(Coordinate3D(latitude: 0.0, longitude: 10.0))

        let dist = a.hausdorffDistance(from: b)
        // Approx 111 km per degree of longitude at the equator
        #expect(dist > 1_100_000.0)
        #expect(dist < 1_200_000.0)
    }

    // Validates Hausdorff distance for lines 1° apart across the dateline.
    @Test
    func antimeridianOneDegreeApart() async throws {
        // Line A: lon 179.5°E (just east of the dateline)
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 179.5),
            Coordinate3D(latitude: 10.0, longitude: 179.5),
        ]))
        // Line B: lon 179.5°W (just west of the dateline, 1° away)
        let b = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: -179.5),
            Coordinate3D(latitude: 10.0, longitude: -179.5),
        ]))

        let dist = a.hausdorffDistance(from: b)
        // 1° of longitude at the equator ≈ 111 km
        #expect(dist > 100_000.0)
        #expect(dist < 120_000.0)
    }

    // Validates that two identical points have zero distance.
    @Test
    func identicalPoints() async throws {
        let a = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let b = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(a.hausdorffDistance(from: b) == 0.0)
    }

    // Validates that the Hausdorff distance works with MultiPoint.
    @Test
    func multiPoints() async throws {
        let a = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let b = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
        ]))

        let dist = a.hausdorffDistance(from: b)
        // The farthest point in A from B is (0,10) at ~5° from (0,5) ≈ 555 km
        #expect(dist > 500_000.0)
        #expect(dist < 600_000.0)
    }

    // Validates Euclidean distance mode.
    @Test
    func euclideanDistance() async throws {
        let a = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let b = Point(Coordinate3D(latitude: 3.0, longitude: 4.0))

        let dist = a.hausdorffDistance(from: b, distanceFunction: .euclidean)
        #expect(abs(dist - 5.0) < 0.001)
    }

    // Validates that empty geometries return zero.
    @Test
    func emptyGeometries() async throws {
        let a = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let b = FeatureCollection()
        #expect(a.hausdorffDistance(from: b) == 0.0)
    }

    // Validates Hausdorff distance across the antimeridian.
    @Test
    func antimeridianLineStrings() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 170.0),
            Coordinate3D(latitude: 1.0, longitude: -170.0),
        ]))

        let dist = a.hausdorffDistance(from: b)
        // 1° of latitude ≈ 111 km
        #expect(dist > 100_000.0)
        #expect(dist < 120_000.0)
    }

    // Validates Hausdorff distance with points on both sides of the antimeridian.
    @Test
    func antimeridianPoints() async throws {
        let a = Point(Coordinate3D(latitude: 0.0, longitude: 175.0))
        let b = Point(Coordinate3D(latitude: 0.0, longitude: -175.0))

        let dist = a.hausdorffDistance(from: b)
        // 10° of longitude at the equator ≈ 1113 km, but going the short way across
        // the dateline (175° to -175° = 10° of actual separation)
        #expect(dist > 1_000_000.0)
        #expect(dist < 1_200_000.0)
    }

    // Validates that the Hausdorff distance is symmetric.
    @Test
    func symmetric() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
        ]))

        let dAB = a.hausdorffDistance(from: b)
        let dBA = b.hausdorffDistance(from: a)
        #expect(abs(dAB - dBA) < 0.001)
    }

    // MARK: - Projections

    // Tests Hausdorff distance in EPSG:4978.
    @Test
    func hausdorff4978() async throws {
        let a = Point(Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978))
        let b = Point(Coordinate3D(latitude: 0.0, longitude: 0.01).projected(to: .epsg4978))
        let dist = a.hausdorffDistance(from: b)
        #expect(dist > 0.0)
    }

    // Tests Hausdorff distance in EPSG:3857.
    @Test
    func hausdorff3857() async throws {
        let a = Point(Coordinate3D(x: 0.0, y: 0.0))
        let b = Point(Coordinate3D(x: 0.0, y: 1000.0))
        let dist = a.hausdorffDistance(from: b)
        #expect(abs(dist - 1000.0) < 0.001)
    }

    // Tests Hausdorff distance with noSRID projection.
    @Test
    func hausdorffNoSRID() async throws {
        let a = Point(Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID))
        let b = Point(Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID))
        let dist = a.hausdorffDistance(from: b)
        #expect(abs(dist - 10.0) < 0.001)
    }

}
