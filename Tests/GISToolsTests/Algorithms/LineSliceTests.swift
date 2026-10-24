@testable import GISTools
import Testing

struct LineSliceTests {

    // Tests that slicing a line string between two points returns the expected sub-line.
    @Test
    func slice() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 22.466878364528448, longitude: -97.88131713867188),
            Coordinate3D(latitude: 22.17596, longitude: -97.820892),
            Coordinate3D(latitude: 21.8704201873689, longitude: -97.6190185546875),
        ]))
        let start = Coordinate3D(latitude: 22.254624, longitude: -97.796173)
        let end = Coordinate3D(latitude: 22.057641, longitude: -97.727508)

        let result = try #require(LineString([
            Coordinate3D(latitude: 22.24644876941306, longitude: -97.835532855256758),
            Coordinate3D(latitude: 22.17596, longitude: -97.820892),
            Coordinate3D(latitude: 22.050645720798983, longitude: -97.738095505915268),
        ]))

        let slice = lineString.slice(start: start, end: end)
        #expect(slice == result)
    }

    // MARK: - Projections

    // Tests line slicing in EPSG:3857 projection.
    @Test
    func lineSlice3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, projection: .epsg3857),
        ]))
        let start = Coordinate3D(x: 250_000.0, y: 250_000.0, projection: .epsg3857)
        let end = Coordinate3D(x: 750_000.0, y: 750_000.0, projection: .epsg3857)
        let slice = lineString.slice(start: start, end: end)
        #expect(slice != nil)
    }

    // Tests line slicing in EPSG:4978 projection.
    @Test
    func lineSlice4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978),
        ]))
        let start = Coordinate3D(latitude: 0.25, longitude: 0.25).projected(to: .epsg4978)
        let end = Coordinate3D(latitude: 0.75, longitude: 0.75).projected(to: .epsg4978)
        let slice = lineString.slice(start: start, end: end)
        #expect(slice != nil)
    }

    // Tests line slicing in noSRID projection.
    @Test
    func lineSliceNoSRID() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
        ]))
        let start = Coordinate3D(x: 25.0, y: 25.0, projection: .noSRID)
        let end = Coordinate3D(x: 75.0, y: 75.0, projection: .noSRID)
        let slice = lineString.slice(start: start, end: end)
        #expect(slice != nil)
    }

    // MARK: - Grid size

    // Validates that `slice(start:end:gridSize:)` matches manual pre-snapping.
    @Test
    func sliceWithGridSize() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
        ]))
        let start = Coordinate3D(latitude: 2.0001, longitude: 2.0001)
        let end = Coordinate3D(latitude: 8.0001, longitude: 8.0001)
        let gridSize = 0.001

        let withParam = lineString.slice(start: start, end: end, gridSize: gridSize)
        let snappedLine = lineString.snappedToGrid(tolerance: gridSize)
        let snappedStart = Point(start).snappedToGrid(tolerance: gridSize).coordinate
        let snappedEnd = Point(end).snappedToGrid(tolerance: gridSize).coordinate
        let manual = snappedLine.slice(start: snappedStart, end: snappedEnd)
        #expect(withParam == manual)
    }

    // MARK: - Antimeridian

    // Tests line slicing across the antimeridian.
    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: 174.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let start = Coordinate3D(latitude: 2.0, longitude: 172.0)
        let stop = Coordinate3D(latitude: 8.0, longitude: 177.0)
        let slice = lineString.slice(start: start, end: stop)
        #expect(slice != nil)
    }

    // Tests that slicing preserves altitude values.
    @Test
    func slicePreservesAltitude() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 500.0),
        ]))
        let start = Coordinate3D(latitude: 2.0, longitude: 2.0)
        let end = Coordinate3D(latitude: 8.0, longitude: 8.0)
        let slice = try #require(lineString.slice(start: start, end: end))
        #expect(slice.coordinates.allSatisfy({ $0.altitude != nil }))
        // Start altitude ≈ 100 + 0.2 * (500-100) = 180
        // End altitude   ≈ 100 + 0.8 * (500-100) = 420
        let startAlt = try #require(slice.coordinates.first?.altitude)
        let endAlt = try #require(slice.coordinates.last?.altitude)
        #expect(abs(startAlt - 180.0) < 5.0)
        #expect(abs(endAlt - 420.0) < 5.0)
    }

}

// MARK: - Audit regressions

extension LineSliceTests {

    @Test
    func sliceStartingAtInteriorVertexHasNoDuplicate() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
        ]))
        let slice = try #require(line.slice(
            start: Coordinate3D(latitude: 0.0, longitude: 1.0),
            end: Coordinate3D(latitude: 0.0, longitude: 2.0)))

        #expect(slice.coordinates.count == 2)
        #expect(slice.coordinates[0] != slice.coordinates[1])
    }


    // MARK: - Audit coverage

    // MARK: - Open-ended slices

    @Test
    func openEndedSlices() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))

        let full = try #require(line.slice())
        #expect(full.coordinates.map(\.longitude) == [0.0, 5.0, 10.0])

        let fromStart = try #require(line.slice(start: Coordinate3D(latitude: 0.0, longitude: 3.0)))
        #expect(fromStart.coordinates.map(\.longitude) == [3.0, 5.0, 10.0])

        let toEnd = try #require(line.slice(end: Coordinate3D(latitude: 0.0, longitude: 7.0)))
        #expect(toEnd.coordinates.map(\.longitude) == [0.0, 5.0, 7.0])

        // Reversed endpoints on different segments are ordered by line order.
        let reversed = try #require(line.slice(
            start: Coordinate3D(latitude: 0.0, longitude: 7.0),
            end: Coordinate3D(latitude: 0.0, longitude: 3.0)))
        #expect(reversed.coordinates.map(\.longitude) == [3.0, 5.0, 7.0])
    }

    @Test
    func reversedEndpointsOnSameSegment() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let result = try #require(line.slice(
            start: Coordinate3D(latitude: 0.0, longitude: 7.0),
            end: Coordinate3D(latitude: 0.0, longitude: 3.0)))
        #expect(result.coordinates.map(\.longitude) == [3.0, 7.0])
    }

    @Test
    func openEndedSlices3857() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 5.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 10.0, y: 0.0, projection: .epsg3857),
        ]))

        let fromStart = try #require(line.slice(
            start: Coordinate3D(x: 3.0, y: 0.0, projection: .epsg3857)))
        #expect(fromStart.coordinates.map(\.x) == [3.0, 5.0, 10.0])

        let toEnd = try #require(line.slice(
            end: Coordinate3D(x: 7.0, y: 0.0, projection: .epsg3857)))
        #expect(toEnd.coordinates.map(\.x) == [0.0, 5.0, 7.0])

        let reversed = try #require(line.slice(
            start: Coordinate3D(x: 7.0, y: 0.0, projection: .epsg3857),
            end: Coordinate3D(x: 3.0, y: 0.0, projection: .epsg3857)))
        #expect(reversed.coordinates.map(\.x) == [3.0, 5.0, 7.0])

        let shortLine = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 10.0, y: 0.0, projection: .epsg3857),
        ]))
        let sameSegment = try #require(shortLine.slice(
            start: Coordinate3D(x: 7.0, y: 0.0, projection: .epsg3857),
            end: Coordinate3D(x: 3.0, y: 0.0, projection: .epsg3857)))
        #expect(sameSegment.coordinates.map(\.x) == [3.0, 7.0])
    }

    @Test
    func openEndedSlices4978() throws {
        let first = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let last = Coordinate3D(latitude: 0.0, longitude: 10.0).projected(to: .epsg4978)
        let firstZ = try #require(first.z)
        let lastZ = try #require(last.z)
        let middle = Coordinate3D(
            x: (first.x + last.x) / 2.0,
            y: (first.y + last.y) / 2.0,
            z: (firstZ + lastZ) / 2.0,
            projection: .epsg4978)
        let line = try #require(LineString([first, last]))

        let full = try #require(line.slice())
        #expect(full.coordinates.count == 2)
        #expect(abs(full.coordinates[0].x - first.x) < 0.000001)
        #expect(abs(full.coordinates[1].x - last.x) < 0.000001)

        let fromStart = try #require(line.slice(start: middle))
        #expect(fromStart.coordinates.count == 2)
        #expect(abs(fromStart.coordinates[0].x - middle.x) < 0.000001)
        #expect(abs(fromStart.coordinates[1].x - last.x) < 0.000001)

        let toEnd = try #require(line.slice(end: middle))
        #expect(toEnd.coordinates.count == 2)
        #expect(abs(toEnd.coordinates[0].x - first.x) < 0.000001)
        #expect(abs(toEnd.coordinates[1].x - middle.x) < 0.000001)

        func interpolated(_ fraction: Double) -> Coordinate3D {
            Coordinate3D(
                x: first.x + fraction * (last.x - first.x),
                y: first.y + fraction * (last.y - first.y),
                z: firstZ + fraction * (lastZ - firstZ),
                projection: .epsg4978)
        }
        let low = interpolated(0.3)
        let high = interpolated(0.7)
        let reversed = try #require(line.slice(start: high, end: low))
        #expect(reversed.coordinates.count == 2)
        #expect(abs(reversed.coordinates[0].x - low.x) < 0.000001)
        #expect(abs(reversed.coordinates[0].y - low.y) < 0.000001)
        #expect(abs(reversed.coordinates[1].x - high.x) < 0.000001)
        #expect(abs(reversed.coordinates[1].y - high.y) < 0.000001)
    }

    @Test
    func openEndedSliceAcrossAntimeridian() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
        ]))

        let toEnd = try #require(line.slice(
            end: Coordinate3D(latitude: 0.0, longitude: -179.5)))
        #expect(toEnd.coordinates.map(\.longitude) == [179.0, -179.5])

        let fromStart = try #require(line.slice(
            start: Coordinate3D(latitude: 0.0, longitude: 179.5)))
        #expect(fromStart.coordinates.map(\.longitude) == [179.5, -179.0])

        let reversed = try #require(line.slice(
            start: Coordinate3D(latitude: 0.0, longitude: -179.5),
            end: Coordinate3D(latitude: 0.0, longitude: 179.5)))
        #expect(reversed.coordinates.map(\.longitude) == [179.5, -179.5])
    }

    @Test
    func openEndedSlicesPreserveAltitude() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 500.0),
        ]))

        let toEnd = try #require(line.slice(
            end: Coordinate3D(latitude: 2.0, longitude: 2.0)))
        #expect(toEnd.coordinates.map(\.longitude) == [0.0, 2.0])
        let endAltitude = try #require(toEnd.coordinates.last?.altitude)
        #expect(abs(endAltitude - 180.0) < 5.0)

        let fromStart = try #require(line.slice(
            start: Coordinate3D(latitude: 8.0, longitude: 8.0)))
        #expect(fromStart.coordinates.map(\.longitude) == [8.0, 10.0])
        let startAltitude = try #require(fromStart.coordinates.first?.altitude)
        #expect(abs(startAltitude - 420.0) < 5.0)
    }

    @Test
    func openEndedFeatureSlices() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
        ]))
        let feature = Feature(
            line,
            id: .string("route"),
            properties: ["name": "R"],
            calculateBoundingBox: true)

        let full = try #require(feature.slice())
        #expect((full.geometry as? LineString)?.coordinates.map(\.x) == [0.0, 5.0, 10.0])

        let fromStart = try #require(feature.slice(
            start: Coordinate3D(x: 3.0, y: 0.0, projection: .noSRID)))
        #expect(fromStart.id == .string("route"))
        #expect(fromStart.property(for: "name") as String? == "R")
        #expect(fromStart.boundingBox != nil)
        #expect((fromStart.geometry as? LineString)?.coordinates.map(\.x) == [3.0, 5.0, 10.0])

        let toEnd = try #require(feature.slice(
            end: Coordinate3D(x: 7.0, y: 0.0, projection: .noSRID)))
        #expect(toEnd.id == .string("route"))
        #expect(toEnd.property(for: "name") as String? == "R")
        #expect(toEnd.boundingBox != nil)
        #expect((toEnd.geometry as? LineString)?.coordinates.map(\.x) == [0.0, 5.0, 7.0])
    }

    @Test
    func oneSidedSlicesAndFeatureVariant() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 5.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
        ]))
        let end = Coordinate3D(x: 7.0, y: 0.0, projection: .noSRID)
        let start = Coordinate3D(x: 3.0, y: 0.0, projection: .noSRID)

        let fromStart = try #require(line.slice(end: end))
        #expect(fromStart.coordinates.map(\.x) == [0.0, 5.0, 7.0])

        let toEnd = try #require(line.slice(start: start))
        #expect(toEnd.coordinates.map(\.x) == [3.0, 5.0, 10.0])

        let feature = Feature(
            line,
            id: .string("route"),
            properties: ["name": "R"],
            calculateBoundingBox: true)
        let sliced = try #require(feature.slice(start: start, end: end))
        #expect(sliced.id == .string("route"))
        #expect(sliced.boundingBox != nil)
        #expect((sliced.geometry as? LineString)?.coordinates.map(\.x) == [3.0, 5.0, 7.0])
    }


}
