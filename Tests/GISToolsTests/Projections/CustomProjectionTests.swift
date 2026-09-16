#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing
import Synchronization

/// Tests for the custom projection registration API.
struct CustomProjectionTests {

    /// SRID pool for this suite: unique per test call, since registration is
    /// add-only and process-global.
    private static let sridCounter = Mutex(900_500)

    private static func nextSrid(_ count: Int = 1) -> Int {
        sridCounter.withLock { value -> Int in
            let start = value
            value += count
            return start
        }
    }

    /// A simple planar "scaled degrees" projection: degrees × 1_000,
    /// round-tripping exactly.
    private static func scaledDegrees(srid: Int) -> CustomProjection {
        CustomProjection(
            srid: srid,
            kind: .planar,
            wraparoundExtent: 180_000.0,
            validExtent: ProjectionExtent(
                minX: -180_000.0,
                minY: -90_000.0,
                maxX: 180_000.0,
                maxY: 90_000.0),
            worldBoundingBox: nil,
            wktMatchers: [["PROJCS", "Scaled Test Grid \(srid)"]],
            forward: { coordinate in
                Coordinate3D(
                    latitude: coordinate.latitude * 1_000.0,
                    longitude: coordinate.longitude * 1_000.0,
                    altitude: coordinate.altitude,
                    m: coordinate.m)
            },
            inverse: { coordinate in
                Coordinate3D(
                    latitude: coordinate.latitude / 1_000.0,
                    longitude: coordinate.longitude / 1_000.0,
                    altitude: coordinate.altitude,
                    m: coordinate.m)
            })
    }

    // Validates a basic registration and end-to-end projections.
    @Test
    func registrationAndRoundTrip() async throws {
        let srid = Self.nextSrid()
        let custom = Self.scaledDegrees(srid: srid)
        #expect(Projection.register(custom))
        #expect(Projection.register(custom) == false) // add-only

        let projection = try #require(Projection(srid: srid))
        #expect(projection.srid == srid)
        #expect(projection.kind == .planar)

        let original = Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 50.0, m: 3.0)
        let projected = original.projected(to: projection)
        #expect(projected.projection.srid == srid)
        #expect(abs(projected.longitude - -71_000.0) < 0.000001)
        #expect(abs(projected.latitude - 41_000.0) < 0.000001)
        #expect(projected.altitude == 50.0)
        #expect(projected.m == 3.0)

        let back = projected.projected(to: .epsg4326)
        #expect(abs(back.latitude - 41.0) < 0.000001)
        #expect(abs(back.longitude - -71.0) < 0.000001)

        // The next SRID without registration produces nil.
        #expect(Projection(srid: srid + 1) == nil)
    }

    // Validates that re-registering or illicit SRIDs are rejected.
    @Test
    func registrationRejections() async throws {
        let srid = Self.nextSrid()
        #expect(Projection.register(Self.scaledDegrees(srid: srid)))
        #expect(Projection.register(Self.scaledDegrees(srid: srid)) == false)
        #expect(Projection.register(Self.scaledDegrees(srid: 0)) == false)
        #expect(Projection.register(Self.scaledDegrees(srid: -1)) == false)

        // Built-in SRIDs cannot be shadowed.
        #expect(Projection.register(Self.scaledDegrees(srid: 4326)) == false)
        #expect(Projection.register(Self.scaledDegrees(srid: 32_619)) == false)
        #expect(Projection.epsg4326.kind == .geographic) // built-in intact
    }

    // Validates registry-driven capabilities: validity, clamping,
    // normalization via wraparoundExtent and kind-based dispatch.
    @Test
    func capabilities() async throws {
        let srid = Self.nextSrid()
        #expect(Projection.register(Self.scaledDegrees(srid: srid)))
        let projection = try #require(Projection(srid: srid))

        // Out-of-extent coordinates are invalid and clamp to the extent.
        let invalid = Coordinate3D(
            x: 0.0,
            y: 91_000.0,
            projection: projection)
        #expect(invalid.isValid == false)
        let clamped = invalid.clamped()
        #expect(clamped.isValid)
        #expect(clamped.latitude == 90_000.0)

        // wraparoundExtent-based normalization.
        let normalized = Coordinate3D(
            x: 180_500.0,
            y: 0.0,
            projection: projection).normalized()
        #expect(abs(normalized.longitude - -179_500.0) < 0.000001)
        #expect(projection.wraparoundExtent == 180_000.0)

        // Kind-based distance dispatch (planar => Euclidean).
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: projection)
        let point = Coordinate3D(x: 3_000.0, y: 4_000.0, projection: projection)
        #expect(abs(origin.distance(from: point) - 5_000.0) < 0.000001)
    }

    // Validates WKT matching for custom fragment sets.
    @Test
    func wktMatching() async throws {
        let srid = Self.nextSrid()
        #expect(Projection.register(Self.scaledDegrees(srid: srid)))

        let matched = Projection(wkt: "PROJCS[\"Scaled Test Grid \(srid)\"]")
        #expect(matched != nil)
        #expect(matched?.srid == srid)
        #expect(Projection(wkt: "PROJCS[\"Something Unrelated\"]") == nil)
    }

    // Validates Codable interplay: encoding emits the SRID; decoding an
    // unknown SRID throws and registered SRIDs round trip.
    @Test
    func codable() async throws {
        let srid = Self.nextSrid()
        #expect(Projection.register(Self.scaledDegrees(srid: srid)))
        let projection = try #require(Projection(srid: srid))

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(projection)
        #expect(String(data: data, encoding: .utf8) == String(srid))

        let decoded = try decoder.decode(Projection.self, from: data)
        #expect(decoded == projection)

        // Unknown SRIDs throw dataCorrupted on decode.
        do {
            _ = try decoder.decode(Projection.self, from: Data("899_999".utf8))
            Issue.record("Decoding an unregistered SRID should throw")
        }
        catch is DecodingError {}
    }

    // Concurrent registrations of distinct SRIDs all succeed; the registry
    // snapshot remains consistent afterwards.
    @Test
    func concurrentRegistration() async throws {
        let start = Self.nextSrid(8)
        let count = 8

        try await withThrowingTaskGroup(of: Int.self) { group in
            for i in 0 ..< count {
                group.addTask {
                    let srid = start + i
                    let registered = Projection.register(
                        CustomProjection(
                            srid: srid,
                            kind: .planar,
                            forward: { coordinate in
                                Coordinate3D(
                                    latitude: coordinate.latitude,
                                    longitude: coordinate.longitude,
                                    altitude: coordinate.altitude,
                                    m: coordinate.m)
                            },
                            inverse: { coordinate in
                                Coordinate3D(
                                    latitude: coordinate.latitude * 1_000.0,
                                    longitude: coordinate.longitude * 1_000.0,
                                    altitude: coordinate.altitude,
                                    m: coordinate.m)
                            }))
                    return registered ? srid : -1
                }
            }

            var results: Set<Int> = []
            for try await srid in group {
                if srid >= 0 {
                    results.insert(srid)
                }
            }
            #expect(results.count == count)
        }

        for i in 0 ..< count {
            #expect(Projection(srid: start + i) != nil)
        }
    }

}
