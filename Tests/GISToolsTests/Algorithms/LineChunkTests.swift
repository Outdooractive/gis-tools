#if !os(Linux)
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

    @Test
    func lineChunkShort() async throws {
        let chunks = lineString.chunked(segmentLength: 5.miles).lineStrings
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

    @Test
    func lineChunkLong() async throws {
        let chunks = lineString.chunked(segmentLength: 50.miles).lineStrings
        #expect(chunks.count == 1)
        #expect(chunks[0] == lineString)
    }

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

}
