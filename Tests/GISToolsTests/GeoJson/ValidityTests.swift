import Foundation
@testable import GISTools
import Testing

/// Tests for the projection-extent validation API.
struct ValidityTests {

    // Validates EPSG:4326 validity bounds.
    @Test
    func coordinate4326() async throws {
        #expect(Coordinate3D(latitude: 41.0, longitude: -71.0).isValid)
        #expect(Coordinate3D(latitude: 90.0, longitude: 180.0).isValid)
        #expect(Coordinate3D(latitude: -90.0, longitude: -180.0).isValid)

        #expect(!Coordinate3D(latitude: 95.0, longitude: 0.0).isValid)
        #expect(!Coordinate3D(latitude: 41.0, longitude: 200.0).isValid)
        #expect(!Coordinate3D(latitude: -120.0, longitude: -71.0).isValid)
    }

    // Validates bounding box validity in EPSG:4326.
    @Test
    func boundingBox4326() async throws {
        #expect(BoundingBox.world.isValid)
        #expect(BoundingBox(southWest: Coordinate3D(latitude: 41.0, longitude: -71.0),
                            northEast: Coordinate3D(latitude: 47.0, longitude: -5.0)).isValid)

        #expect(!BoundingBox(southWest: Coordinate3D(latitude: 41.0, longitude: -190.0),
                             northEast: Coordinate3D(latitude: 47.0, longitude: -5.0)).isValid)
        #expect(!BoundingBox(southWest: Coordinate3D(latitude: 41.0, longitude: -71.0),
                             northEast: Coordinate3D(latitude: 95.0, longitude: -5.0)).isValid)
    }

    // Validates EPSG:3857 validity bounds.
    @Test
    func coordinate3857() async throws {
        let shift = GISTool.originShift
        #expect(Coordinate3D(x: 0.0, y: 0.0).isValid)
        #expect(Coordinate3D(x: shift, y: shift).isValid)
        #expect(!Coordinate3D(x: shift + 1.0, y: 0.0).isValid)
        #expect(!Coordinate3D(x: 0.0, y: -shift - 1.0).isValid)
    }

    // Validates EPSG:4978 (unbounded extent: always valid) and noSRID.
    @Test
    func coordinateUnbounded() async throws {
        let ecef = Coordinate3D(latitude: 41.0, longitude: -71.0).projected(to: .epsg4978)
        #expect(ecef.isValid)

        let ecefFar = Coordinate3D(
            x: 1_000_000_000.0,
            y: -1_000_000_000.0,
            z: 0.0,
            projection: .epsg4978)
        #expect(ecefFar.isValid)

        #expect(Coordinate3D(x: 12_345.0, y: -6_789.0, projection: .noSRID).isValid)
    }

    // Validates validity in UTM zone sectors.
    @Test
    func coordinateUtm() async throws {
        let inZone = Coordinate3D(x: 500_000.0, y: 4_000_000.0, projection: .epsg32619)
        #expect(inZone.isValid)

        let outsideSector = Coordinate3D(x: 50_000.0, y: 4_000_000.0, projection: .epsg32619)
        #expect(!outsideSector.isValid)

        let aboveExtent = Coordinate3D(x: 500_000.0, y: 10_500_000.0, projection: .epsg32619)
        #expect(!aboveExtent.isValid)
    }

    // Validates that projecting an out-of-extent coordinate re-enters the
    // valid extent via clamped().
    @Test
    func invalidThenClamp() async throws {
        let invalid = Coordinate3D(latitude: 95.0, longitude: 200.0)
        #expect(!invalid.isValid)
        #expect(invalid.clamped().isValid)
    }

}
