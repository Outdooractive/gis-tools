@testable import GISTools
import Testing

struct CleanTests {

    /// Removing consecutive duplicates from a coordinate array.
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

    /// Removing collinear points from a coordinate array.
    @Test
    func removeCollinear() {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 0.0),  // collinear
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]
        let cleaned = coords.cleaned(removeDuplicates: true, removeCollinear: true)
        #expect(cleaned.count == 3)
        #expect(cleaned[1] == Coordinate3D(latitude: 1.0, longitude: 0.0))
    }

    /// Closing a ring.
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

    /// Opening a ring.
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

    /// Cleaning a LineString.
    @Test
    func cleanLineString() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.5, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
        ])
        let cleaned = line.cleaned(removeDuplicates: true, removeCollinear: true)
        #expect(cleaned.coordinates.count == 2)
    }

    /// Cleaning a Polygon removes duplicate vertices in rings.
    @Test
    func cleanPolygon() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        let cleaned = polygon.cleaned(removeDuplicates: true)
        // Should have 5 coordinates: 4 unique + closing
        #expect(cleaned.coordinates[0].count == 5)
    }

    /// Cleaning a LineString with duplicates in EPSG:3857 removes duplicate points.
    @Test
    func clean3857() {
        let line = LineString(unchecked: [
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 200_000.0, y: 0.0),
        ])
        let cleaned = line.cleaned(removeDuplicates: true, removeCollinear: true)
        #expect(cleaned.coordinates.count == 2)
    }

}
