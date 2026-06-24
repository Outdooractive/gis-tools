#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Foundation
import Testing

struct FrechetDistanceTests {

    // Validates Frechet distance between two arcs in EPSG:4326 using haversine and rhumb line distance functions.
    @Test
    func frechetDistance4326() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let lineArc1 = try #require(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        let lineArc2 = try #require(point.lineArc(radius: 6000.0, bearing1: 20.0, bearing2: 60.0))

        let distanceHaversine = lineArc1.frechetDistance(from: lineArc2, distanceFunction: .haversine)
        let distanceRhumbLine = lineArc1.frechetDistance(from: lineArc2, distanceFunction: .rhumbLine)

        #expect(abs(distanceHaversine - 1000.0) < 0.0001)
        #expect(abs(distanceRhumbLine - 1000.0) < 0.0001)
    }

    // Validates Frechet distance between two arcs in EPSG:3857 using the Euclidean distance function.
    @Test
    func frechetDistance3857() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0)).projected(to: .epsg3857)
        let lineArc1 = try #require(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        let lineArc2 = try #require(point.lineArc(radius: 6000.0, bearing1: 20.0, bearing2: 60.0))

        let distanceEucliden = lineArc1.frechetDistance(from: lineArc2, distanceFunction: .euclidean)
        #expect(abs(distanceEucliden - 1000.0) < 2.0)
    }

    // Validates Frechet distance with unequal-length coordinate arrays.
    @Test
    func frechetDistanceUnequalLengths() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.5),
            Coordinate3D(latitude: 2.0, longitude: 0.5),
        ]))

        let distance = line1.frechetDistance(from: line2, distanceFunction: .haversine)
        #expect(distance > 0.0)
        #expect(distance < 200_000.0)
    }

    // Validates Frechet distance with a custom distance function.
    @Test
    func frechetDistanceCustomFunction() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let distance = line1.frechetDistance(
            from: line2,
            distanceFunction: .other({ a, b in
                hypot(a.longitude - b.longitude, a.latitude - b.latitude)
            })
        )
        #expect(distance == 0.0)
    }

    // Validates Frechet distance with segmentLength producing different intermediate point counts.
    @Test
    func frechetDistanceWithSegmentLength() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.5),
        ]))

        let distance = line1.frechetDistance(from: line2, distanceFunction: .haversine, segmentLength: 10_000.0)
        #expect(distance > 0.0)
    }

    // Fréchet distance of a line with itself is zero.
    @Test
    func frechetDistanceSelf() async throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let distance = line.frechetDistance(from: line, distanceFunction: .haversine)
        #expect(distance == 0.0)
    }

    // Fréchet distance between two parallel lines equals their separation.
    @Test
    func frechetDistanceParallelLines() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))

        let distance = line1.frechetDistance(from: line2, distanceFunction: .euclidean)
        #expect(abs(distance - 1.0) < 0.0001)
    }

    // MARK: - Antimeridian

    // Validates Frechet distance for lines 1° apart across the dateline.
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

        let dist = a.frechetDistance(from: b, distanceFunction: .haversine)
        // 1° of longitude at the equator ≈ 111 km
        #expect(dist > 100_000.0)
        #expect(dist < 120_000.0)
    }

    @Test
    func antimeridian() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: 170.0),
            Coordinate3D(latitude: 1.0, longitude: -170.0),
        ]))
        let distance = line1.frechetDistance(from: line2, distanceFunction: .haversine)
        #expect(distance > 0.0 && distance < 5_000_000.0)
    }

    // MARK: - Projection: noSRID

    @Test
    func frechetDistanceNoSRID() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 15.0, y: 0.0, projection: .noSRID),
        ]))
        let distance = line1.frechetDistance(from: line2, distanceFunction: .euclidean)
        #expect(abs(distance - 5.0) < 0.0001)
    }

    @Test
    func frechetDistance4978() async throws {
        let line1 = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(x: 50.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 150.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let distance = line1.frechetDistance(from: line2, distanceFunction: .euclidean)
        #expect(abs(distance - 50.0) < 0.0001)
    }

}
