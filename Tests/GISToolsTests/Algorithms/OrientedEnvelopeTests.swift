import Foundation
@testable import GISTools
import Testing

struct OrientedEnvelopeTests {

    /// A vertical line: the oriented envelope should be a tall, narrow rectangle.
    @Test
    func verticalLine() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let envelope = line.orientedEnvelope()
        #expect(envelope != nil)
        if let envelope {
            // Should be roughly 10 units tall and very narrow
            let h = envelope.allCoordinates.map(\.latitude).max()! - envelope.allCoordinates.map(\.latitude).min()!
            let w = envelope.allCoordinates.map(\.longitude).max()! - envelope.allCoordinates.map(\.longitude).min()!
            #expect(h > 9.0)
            #expect(w < 1.0)
        }
    }

    /// A horizontal line: the oriented envelope should be a wide, short rectangle.
    @Test
    func horizontalLine() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let envelope = line.orientedEnvelope()
        #expect(envelope != nil)
        if let envelope {
            let h = envelope.allCoordinates.map(\.latitude).max()! - envelope.allCoordinates.map(\.latitude).min()!
            let w = envelope.allCoordinates.map(\.longitude).max()! - envelope.allCoordinates.map(\.longitude).min()!
            #expect(w > 9.0)
            #expect(h < 1.0)
        }
    }

    /// A diagonal line at 45°: the oriented envelope should align with the line.
    @Test
    func diagonalLine() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let envelope = line.orientedEnvelope()
        #expect(envelope != nil)
        if let envelope {
            // The envelope should be much longer than wide
            let coords = envelope.allCoordinates
            var minDist = Double.infinity
            var maxDist = -Double.infinity
            for c in coords {
                let d = c.latitude // project onto y-axis as a simple check
                minDist = min(minDist, d)
                maxDist = max(maxDist, d)
            }
            #expect(maxDist - minDist > 7.0)
        }
    }

    /// A square: the oriented envelope should match the axis-aligned bounding box.
    @Test
    func square() throws {
        let square = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let envelope = square.orientedEnvelope()
        #expect(envelope != nil)
        if let envelope {
            let lons = envelope.allCoordinates.map(\.longitude)
            let lats = envelope.allCoordinates.map(\.latitude)
            let w = (lons.max() ?? 0) - (lons.min() ?? 0)
            let h = (lats.max() ?? 0) - (lats.min() ?? 0)
            #expect(w > 9.0)
            #expect(h > 9.0)
            #expect(w < 11.0)
            #expect(h < 11.0)
        }
    }

    /// An empty geometry returns nil.
    @Test
    func empty() {
        let mp = MultiPoint()
        #expect(mp.orientedEnvelope() == nil)
    }

    /// A single point returns nil.
    @Test
    func singlePoint() {
        let pt = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        #expect(pt.orientedEnvelope() == nil)
    }

    // MARK: - Projections

    /// A polygon in EPSG:3857 produces a valid oriented envelope.
    @Test
    func orientedEnvelope3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 0.0),
            Coordinate3D(x: 1000.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 1000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let envelope = polygon.orientedEnvelope()
        #expect(envelope != nil)
        #expect(envelope?.projection == .epsg3857)
        if let envelope {
            let coords = envelope.allCoordinates
            #expect(coords.count >= 4)
        }
    }

    /// A polygon in noSRID produces a valid oriented envelope.
    @Test
    func orientedEnvelopeNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let envelope = polygon.orientedEnvelope()
        #expect(envelope != nil)
        #expect(envelope?.projection == .noSRID)
        if let envelope {
            let coords = envelope.allCoordinates
            #expect(coords.count >= 4)
        }
    }


    @Test
    func orientedEnvelope4978() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 1.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
        ]]))
        let envelope = polygon.orientedEnvelope()
        #expect(envelope != nil)
        #expect(envelope?.projection == .epsg4978)
        if let envelope {
            let coords = envelope.allCoordinates
            #expect(coords.count >= 4)
        }
    }

    // MARK: - Antimeridian

    /// A square crossing the antimeridian should still produce a valid envelope.
    @Test
    func antimeridianSquare() throws {
        let square = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 10.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
        ]]))
        let envelope = square.orientedEnvelope()
        #expect(envelope != nil)
        if let envelope {
            let lats = envelope.allCoordinates.map(\.latitude)
            let h = (lats.max() ?? 0) - (lats.min() ?? 0)
            #expect(h > 9.0)
            #expect(h < 11.0)
        }
    }

    /// A diagonal line crossing the antimeridian.
    @Test
    func antimeridianLine() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 10.0, longitude: -179.0),
        ]))
        let envelope = line.orientedEnvelope()
        #expect(envelope != nil)
    }

}
