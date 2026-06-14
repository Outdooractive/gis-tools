@testable import GISTools
import Testing

struct LineSliceAlongTests {

    // Verifies that slicing a line between two valid distances returns the correct start and end coordinates.
    @Test
    func slice() async throws {
        let lineString = try TestData.lineString(package: "LineSliceAlong", name: "LineSliceAlong")

        let start: Double = try #require(GISTool.convert(length: 500.0, from: .miles, to: .meters))
        let startCoordinate: Coordinate3D = lineString.coordinateAlong(distance: start)

        let end: Double = try #require(GISTool.convert(length: 750.0, from: .miles, to: .meters))
        let endCoordinate: Coordinate3D = lineString.coordinateAlong(distance: end)

        let sliced = try #require(lineString.sliceAlong(startDistance: start, stopDistance: end))
        #expect(sliced.coordinates[0] == startCoordinate)
        #expect(sliced.coordinates[sliced.coordinates.count - 1] == endCoordinate)
    }

    // Verifies that slicing when the stop distance exceeds the line length still returns valid start and end coordinates.
    @Test
    func sliceOvershoot() async throws {
        let lineString = try TestData.lineString(package: "LineSliceAlong", name: "LineSliceAlong")

        let start: Double = try #require(GISTool.convert(length: 500.0, from: .miles, to: .meters))
        let startCoordinate: Coordinate3D = lineString.coordinateAlong(distance: start)

        let end: Double = try #require(GISTool.convert(length: 1500.0, from: .miles, to: .meters))
        let endCoordinate: Coordinate3D = lineString.coordinateAlong(distance: end)

        let sliced = try #require(lineString.sliceAlong(startDistance: start, stopDistance: end))
        #expect(sliced.coordinates[0] == startCoordinate)
        #expect(sliced.coordinates[sliced.coordinates.count - 1] == endCoordinate)
    }

    // Verifies that slicing at the very start of the line produces a valid zero-length segment.
    @Test
    func sliceStartAtZero() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 22.466878364528448, longitude: -97.88131713867188),
            Coordinate3D(latitude: 22.17596, longitude: -97.820892),
        ]))

        let sliced = try #require(lineString.sliceAlong(startDistance: 0.0, stopDistance: 0.0))
        #expect(sliced.coordinates.count >= 2)
        #expect(sliced.coordinates[0] == sliced.coordinates[1])
    }

    // Verifies that slicing exactly at a vertex (start boundary) returns a valid LineString.
    @Test
    func sliceStartAtFirstVertex() async throws {
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let b = Coordinate3D(latitude: 1.0, longitude: 0.0)
        let c = Coordinate3D(latitude: 2.0, longitude: 0.0)
        let lineString = try #require(LineString([a, b, c]))

        // Distance from (0,0) to (1,0) ≈ 111,319.5 m.
        // Slicing from exactly that distance should hit the start-at-vertex branch.
        let vertexDistance = a.distance(from: b)
        let sliced = try #require(lineString.sliceAlong(startDistance: vertexDistance, stopDistance: 200_000.0))
        #expect(sliced.coordinates.count >= 2)
        #expect(sliced.coordinates[0] == b)
    }

    // Verifies that slicing to the end of the line returns the last segment.
    @Test
    func sliceStopAtEnd() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))

        let sliced = try #require(lineString.sliceAlong(startDistance: 50_000.0, stopDistance: .greatestFiniteMagnitude))
        #expect(sliced.coordinates.count >= 2)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
        ]))
        let sliced = try #require(lineString.sliceAlong(startDistance: 0.0, stopDistance: 50000.0))
        #expect(sliced.coordinates.count >= 2)
        for coord in sliced.coordinates {
            #expect(abs(coord.latitude) <= 15.0)
            #expect(abs(coord.longitude) > 150.0)
        }
    }

}
