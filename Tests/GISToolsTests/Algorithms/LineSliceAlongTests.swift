@testable import GISTools
import Testing

struct LineSliceAlongTests {

    private static let inputLineString = LineString(unchecked: [
        Coordinate3D(latitude: 22.350075806124867, longitude: 113.99414062499999),
        Coordinate3D(latitude: 23.241346102386135, longitude: 116.76269531249999),
        Coordinate3D(latitude: 24.367113562651276, longitude: 117.7734375),
        Coordinate3D(latitude: 25.20494115356912, longitude: 118.828125),
        Coordinate3D(latitude: 26.78484736105119, longitude: 119.794921875),
        Coordinate3D(latitude: 28.110748760633534, longitude: 120.80566406250001),
        Coordinate3D(latitude: 29.49698759653577, longitude: 121.59667968749999),
        Coordinate3D(latitude: 31.12819929911196, longitude: 121.59667968749999),
        Coordinate3D(latitude: 32.84267363195431, longitude: 120.84960937499999),
        Coordinate3D(latitude: 34.125447565116126, longitude: 119.83886718750001),
        Coordinate3D(latitude: 35.31736632923788, longitude: 118.69628906249999),
        Coordinate3D(latitude: 36.80928470205937, longitude: 121.4208984375),
        Coordinate3D(latitude: 37.37015718405753, longitude: 122.82714843749999),
    ])

    // Verifies that slicing a line between two valid distances returns the correct start and end coordinates.
    @Test
    func slice() async throws {
        let lineString = Self.inputLineString

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
        let lineString = Self.inputLineString

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

    // MARK: - Projections

    // Tests line slicing along in EPSG:3857 projection.
    @Test
    func lineSliceAlong3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000_000.0, y: 0.0),
        ]))
        let sliced = try #require(lineString.sliceAlong(startDistance: 100_000.0, stopDistance: 500_000.0))
        #expect(sliced.coordinates.count >= 2)
    }

    // Tests line slicing along in EPSG:4978 projection.
    @Test
    func lineSliceAlong4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 9.0).projected(to: .epsg4978),
        ]))
        let sliced = try #require(lineString.sliceAlong(startDistance: 100_000.0, stopDistance: 500_000.0))
        #expect(sliced.coordinates.count >= 2)
    }

    // Tests line slicing along in noSRID projection.
    @Test
    func lineSliceAlongNoSRID() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
        ]))
        let sliced = try #require(lineString.sliceAlong(startDistance: 10.0, stopDistance: 50.0))
        #expect(sliced.coordinates.count >= 2)
    }

    // Tests that slicing preserves altitude values.
    @Test
    func lineSliceAlongPreservesAltitude() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0, altitude: 500.0),
        ]))
        let sliced = try #require(lineString.sliceAlong(startDistance: 0.0, stopDistance: lineString.length / 2.0))
        #expect(sliced.coordinates.allSatisfy({ $0.altitude != nil }))
        if let mid = sliced.coordinates.last?.altitude {
            #expect(abs(mid - 300.0) < 5.0)
        }
    }

    // MARK: - Antimeridian

    // Tests line slicing along across the antimeridian.
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
