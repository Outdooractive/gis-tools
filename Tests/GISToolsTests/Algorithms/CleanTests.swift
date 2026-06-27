@testable import GISTools
import Testing

struct CleanTests {

    // Removing consecutive duplicates from a coordinate array.
    @Test
    func deduplicateArray() {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]
        let cleaned = coords.cleaned(removeDuplicates: true, removeCollinear: false)
        #expect(cleaned.count == 2)
        #expect(cleaned[0] == Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(cleaned[1] == Coordinate3D(latitude: 1.0, longitude: 0.0))
    }

    // Removing collinear points from a coordinate array.
    @Test
    func removeCollinear() {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]
        let cleaned = coords.cleaned(removeDuplicates: true, removeCollinear: true)
        #expect(cleaned.count == 3)
        #expect(cleaned[1] == Coordinate3D(latitude: 1.0, longitude: 0.0))
    }

    // Closing an open ring.
    @Test
    func closeRing() {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]
        let cleaned = coords.cleaned(closeRing: true)
        #expect(cleaned.count == 5)
        #expect(cleaned.last == Coordinate3D(latitude: 0.0, longitude: 0.0))
    }

    // Opening a closed ring.
    @Test
    func openRing() {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        let cleaned = coords.cleaned(openRing: true)
        #expect(cleaned.count == 4)
    }

    // Cleaning a LineString removes duplicates.
    @Test
    func cleanLineString() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ]))
        let cleaned = line.cleaned(removeDuplicates: true, removeCollinear: true)
        #expect(cleaned.coordinates.count == 2)
    }

    // Cleaning a Polygon removes duplicate vertices.
    @Test
    func cleanPolygon() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let cleaned = polygon.cleaned(removeDuplicates: true)
        #expect(cleaned.coordinates[0].count == 5)
    }

    // MARK: - Projections

    // Cleaning in EPSG:3857 removes duplicate points.
    @Test
    func clean3857() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 200_000.0, y: 0.0),
        ]))
        let cleaned = line.cleaned(removeDuplicates: true, removeCollinear: true)
        #expect(cleaned.coordinates.count == 2)
    }

    // Cleaning in EPSG:4978 removes duplicates and collinear points.
    @Test
    func clean4978() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 200_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let cleaned = line.cleaned(removeDuplicates: true, removeCollinear: true)
        #expect(cleaned.coordinates.count == 2)
    }

    // Cleaning in noSRID removes duplicates and collinear points.
    @Test
    func cleanNoSRID() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 200.0, y: 0.0, projection: .noSRID),
        ]))
        let cleaned = line.cleaned(removeDuplicates: true, removeCollinear: true)
        #expect(cleaned.coordinates.count == 2)
    }

}
