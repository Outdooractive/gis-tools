#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Tests for the batch coordinate conversion API (`Array.projected(to:)`).
struct ArrayProjectionTests {

    /// Validates the empty and single-element edge cases.
    @Test
    func edgeCases() async throws {
        #expect([Coordinate3D]().projected(to: .epsg3857).isEmpty)

        let single = [Coordinate3D(latitude: 41.0, longitude: -71.0)]
        let result = single.projected(to: .epsg3857)
        #expect(result.count == 1)
        #expect(abs(result[0].longitude - single[0].projected(to: .epsg3857).longitude) < 0.0000000001)
    }

    /// Validates same-projection batches are verbatim copies.
    @Test
    func sameProjection() async throws {
        let coordinates = [
            Coordinate3D(latitude: 41.0, longitude: -71.0),
            Coordinate3D(latitude: 52.0, longitude: -1.0),
        ]
        let result = coordinates.projected(to: .epsg4326)
        #expect(result.count == 2)
        #expect(result[0] == coordinates[0])
        #expect(result[1] == coordinates[1])
    }

    /// Validates batch output equals the per-coordinate path for every
    /// projection family (this is the core equivalence contract).
    @Test
    func matchesSingleCoordinatePath() async throws {
        let base = Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 50.0, m: 3.0)
        let start = base.projected(to: .epsg32619) // test from a non-4326 start
        let batchCoordinates: [Coordinate3D] = [
            start,
            start.projected(to: .epsg4326).projected(to: .epsg32619),
            Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 50.0, m: 3.0).projected(to: .epsg32619),
        ]

        for target: Projection in [.epsg4326, .epsg3857, .epsg4978, .epsg3395, .epsg32662, .epsg4258, .epsg4267, .epsg4277, .epsg27700, .epsg32631] {
            let batch = batchCoordinates.projected(to: target)
            #expect(batch.count == batchCoordinates.count)

            for (batchCoordinate, viaSingle) in zip(batch, batchCoordinates.map { $0.projected(to: target) }) {
                #expect(batchCoordinate == viaSingle)
                #expect(batchCoordinate.projection == target)
            }
        }
    }

    /// Validates round trips through the batch API across the projection set.
    @Test
    func roundTrips() async throws {
        let base = Coordinate3D(latitude: 41.0, longitude: -71.0, altitude: 250.0, m: 7.0)
        let projections: [Projection] = [.epsg4326, .epsg3857, .epsg4978, .epsg3395, .epsg32662, .epsg4258]

        for projection in projections {
            // Uniform batch: the API asserts on mixed projections.
            let batch = [
                base.projected(to: projection),
                base.projected(to: projection),
            ]
            let there = batch.projected(to: .epsg3857)
            let back = there.projected(to: projection)

            #expect(abs(back[0].latitude - batch[0].latitude) < 0.000001)
            #expect(abs(back[0].longitude - batch[0].longitude) < 0.000001)
        }
    }

    /// Validates the noSRID verbatim semantics in batch context.
    @Test
    func noSridVerbatim() async throws {
        let coordinates: [Coordinate3D] = [
            Coordinate3D(x: -71.0, y: 41.0, z: 50.0, m: 2.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 20.0, projection: .noSRID),
        ]

        // Both directions: verbatim copy with the new label, no math.
        let projected = coordinates.projected(to: .epsg3857)
        #expect(projected[0].longitude == -71.0)
        #expect(projected[0].latitude == 41.0)

        // Dropping the SRID keeps the values verbatim - anything to noSRID
        // is a pure relabel.
        let viaSingle = coordinates[0].projected(to: .noSRID)
        let viaBatch = coordinates.projected(to: .noSRID)
        #expect(viaBatch[0] == viaSingle)

        // Whole-batch drop keeps the raw values.
        let dropped = coordinates.projected(to: .noSRID)
        #expect(dropped[1].longitude == 10.0)
        #expect(dropped[1].latitude == 20.0)
    }

    /// Validates the in-place `project(to:)` variant.
    @Test
    func mutatingVariant() async throws {
        var coordinates = [
            Coordinate3D(latitude: 41.0, longitude: -71.0),
            Coordinate3D(latitude: 52.0, longitude: -1.0),
        ]
        coordinates.project(to: .epsg3857)
        #expect(coordinates[0].projection == .epsg3857)

        let reference = Coordinate3D(latitude: 41.0, longitude: -71.0).projected(to: .epsg3857)
        #expect(abs(coordinates[0].longitude - reference.longitude) < 0.0000000001)
        #expect(abs(coordinates[0].latitude - reference.latitude) < 0.0000000001)
    }

}
