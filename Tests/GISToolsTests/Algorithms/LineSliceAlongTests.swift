@testable import GISTools
import Testing

struct LineSliceAlongTests {

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

}
