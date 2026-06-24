#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct LineChunkTests {

    private let lineString = LineString([
        Coordinate3D(latitude: 40.250184183819854, longitude: -86.28524780273438),
        Coordinate3D(latitude: 40.17887331434696, longitude: -85.98587036132812),
        Coordinate3D(latitude: 40.08857859823707, longitude: -85.97213745117188),
        Coordinate3D(latitude: 40.15578608609647, longitude: -85.77987670898438),
    ])!

    // Tests that chunking a line string into short segments produces the expected number and positions of chunks.
    @Test
    func lineChunkShort() async throws {
        let chunks = lineString.chunked(segmentLength: GISTool.convertToMeters(5, .miles)).lineStrings
        #expect(chunks.count == 7)

        let some = chunks[3]
        #expect(some.coordinates.count == 3)
        #expect(abs(some.coordinates[0].latitude - 40.18557) < 0.000001)
        #expect(abs(some.coordinates[0].longitude - -86.013822) < 0.000001)

        #expect(abs(some.coordinates[1].latitude - 40.178873) < 0.000001)
        #expect(abs(some.coordinates[1].longitude - -85.98587) < 0.000001)

        #expect(abs(some.coordinates[2].latitude - 40.129223) < 0.000001)
        #expect(abs(some.coordinates[2].longitude - -85.978314) < 0.000001)
    }

    // Tests that chunking a line string with segments longer than the line returns a single chunk equal to the original.
    @Test
    func lineChunkLong() async throws {
        let chunks = lineString.chunked(segmentLength: GISTool.convertToMeters(50, .miles)).lineStrings
        #expect(chunks.count == 1)
        #expect(chunks[0] == lineString)
    }

    // Tests that dropping intermediate coordinates during chunking produces simplified chunks with fewer vertices.
    @Test
    func lineChunkDropIntermediates() async throws {
        let chunks = lineString.chunked(segmentLength: lineString.length / 2).lineStrings
        #expect(chunks.count == 2)
        #expect(chunks[0].coordinates.count == 3)
        #expect(chunks[1].coordinates.count == 3)

        let chunksSimplified = lineString.chunked(segmentLength: lineString.length / 2, dropIntermediateCoordinates: true).lineStrings
        #expect(chunksSimplified.count == 2)
        #expect(chunksSimplified[0].coordinates.count == 2)
        #expect(chunksSimplified[1].coordinates.count == 2)
    }

    // Tests that evenly dividing a line produces coordinates at consistent intervals matching the segment length.
    @Test
    func evenlyDivided() async throws {
        let a = Coordinate3D.zero
        let b = a.destination(distance: 100.0, bearing: 90.0)
        let line = LineString(unchecked: [a, b])
        let dividedLine = line.evenlyDivided(segmentLength: 1.0)

        #expect(line.allCoordinates.count == 2)
        #expect(dividedLine.allCoordinates.count == 101)

        for (first, second, _) in dividedLine.allCoordinates.overlappingPairs() {
            guard let second else { break }
            #expect(abs(first.distance(from: second) - 1.0) < 0.0001)
        }
    }

    // MARK: - EPSG:3857

    @Test
    func lineChunk3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 500_000.0, y: 500_000.0),
            Coordinate3D(x: 1_000_000.0, y: 0.0),
        ]))
        let chunks = lineString.chunked(segmentLength: 200_000.0).lineStrings
        #expect(chunks.count > 1)
    }

    @Test
    func lineChunk4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 3.0, longitude: 3.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 6.0, longitude: 0.0).projected(to: .epsg4978),
        ]))
        let chunks = lineString.chunked(segmentLength: 200_000.0).lineStrings
        #expect(chunks.count > 1)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let chunks = lineString.chunked(segmentLength: 50000.0).lineStrings
        #expect(chunks.count > 0)
        for chunk in chunks {
            for coord in chunk.coordinates {
                #expect(abs(coord.longitude) > 150.0)
            }
        }
    }

}
