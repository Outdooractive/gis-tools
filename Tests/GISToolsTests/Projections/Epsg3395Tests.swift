#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

// Algorithm smoke tests in EPSG:3395 (WGS 84 / World Mercator).
struct Epsg3395AlgorithmTests {

    // Validates Euclidean distance in EPSG:3395 (planar kind).
    @Test
    func distance() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3395)
        let point = Coordinate3D(x: 300_000.0, y: 400_000.0, projection: .epsg3395)

        #expect(abs(origin.distance(from: point) - 500_000.0) < 0.000001)
    }

    // Validates bounding box calculation and containment in EPSG:3395.
    @Test
    func boundingBoxAndContains() async throws {
        let coordinates: [[Coordinate3D]] = [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3395),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3395),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3395),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3395),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3395),
        ]]
        let polygon = try #require(Polygon(coordinates, calculateBoundingBox: true))

        #expect(polygon.projection == .epsg3395)

        let boundingBox = try #require(polygon.boundingBox)
        #expect(boundingBox.projection == .epsg3395)
        #expect(boundingBox.southWest.x == 0.0)
        #expect(boundingBox.northEast.y == 1000.0)

        #expect(polygon.contains(Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3395)))
        #expect(!polygon.contains(Coordinate3D(x: 1500.0, y: 500.0, projection: .epsg3395)))
    }

    // Validates antimeridian detection and cutting in EPSG:3395, where the
    // wraparound axis is at ±originShift meters.
    @Test
    func antimeridian() async throws {
        // A line crossing the wraparound axis: near x = +originShift to
        // near x = -originShift.
        let shift = GISTool.originShift
        let lineCoordinates: [Coordinate3D] = [
            Coordinate3D(x: shift - 100_000.0, y: 1_000_000.0, projection: .epsg3395),
            Coordinate3D(x: -shift + 100_000.0, y: 1_100_000.0, projection: .epsg3395),
        ]
        let line = LineString(unchecked: lineCoordinates)

        #expect(line.crossesAntimeridian)

        let cut = line.cutAtAntimeridian()
        #expect(cut.features.count == 2)

        for feature in cut.features {
            let lineString = try #require(feature.geometry as? LineString)
            for coordinate in lineString.coordinates {
                #expect(abs(coordinate.longitude) <= shift)
            }
        }

        // A line not crossing the axis stays untouched.
        let plainLineCoordinates: [Coordinate3D] = [
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3395),
            Coordinate3D(x: 100_000.0, y: 100_000.0, projection: .epsg3395),
        ]
        let plainLine = LineString(unchecked: plainLineCoordinates)
        #expect(!plainLine.crossesAntimeridian)
        #expect(plainLine.cutAtAntimeridian().features.count == 1)
    }

    // Validates normalize/clamp behavior in EPSG:3395.
    @Test
    func normalizeAndClamp() async throws {
        let shift = GISTool.originShift

        let normalized = Coordinate3D(x: shift + 100.0, y: 0.0, projection: .epsg3395).normalized()
        #expect(abs(normalized.longitude - (-shift + 100.0)) < 0.0000000001)

        let clamped = Coordinate3D(x: shift + 100.0, y: 0.0, projection: .epsg3395).clamped()
        #expect(clamped.longitude == shift)
    }

    // Validates geodesic operations via the EPSG:4326 pivot.
    @Test
    func destinationAndBearing() async throws {
        // 1_000_000 meters north from the equator stays at the same x.
        let start = Coordinate3D(x: 1_000_000.0, y: 0.0, projection: .epsg3395)
        let destination = start.destination(distance: 1_000_000.0, bearing: 0.0)
        #expect(destination.projection == .epsg3395)
        #expect(abs(destination.longitude - 1_000_000.0) < 0.000001)
        #expect(destination.latitude > 0.0)

        // East-west bearing along the equator.
        let bearing = start.bearing(to: Coordinate3D(x: 2_000_000.0, y: 0.0, projection: .epsg3395))
        #expect(abs(bearing - 90.0) < 0.000001)
    }

}
