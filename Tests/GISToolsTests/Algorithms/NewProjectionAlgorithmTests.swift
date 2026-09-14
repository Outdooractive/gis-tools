#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

// Smoke tests for the algorithms most affected by a new projection:
// distance (planar kind), bounding boxes, containment and antimeridian
// handling, exercised in EPSG:3395 and EPSG:32662.

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
        let line = try #require(LineString(unchecked: lineCoordinates))

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
        let plainLine = try #require(LineString(unchecked: plainLineCoordinates))
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

struct Epsg32662AlgorithmTests {

    // Validates that EPSG:32662 is treated as planar (Euclidean) by
    // distance, consistent with its kind.
    @Test
    func distance() async throws {
        let origin = Coordinate3D(x: 0.0, y: 0.0, projection: .epsg32662)
        let point = Coordinate3D(x: 3.0, y: 4.0, projection: .epsg32662)

        #expect(abs(origin.distance(from: point) - 5.0) < 0.000001)
    }

    // Validates bounding box calculation and containment in EPSG:32662.
    @Test
    func boundingBoxAndContains() async throws {
        let coordinates: [[Coordinate3D]] = [[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg32662),
            Coordinate3D(x: 10.0, y: 0.0, projection: .epsg32662),
            Coordinate3D(x: 10.0, y: 10.0, projection: .epsg32662),
            Coordinate3D(x: 0.0, y: 10.0, projection: .epsg32662),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg32662),
        ]]
        let polygon = try #require(Polygon(coordinates, calculateBoundingBox: true))

        #expect(polygon.projection == .epsg32662)

        let boundingBox = try #require(polygon.boundingBox)
        #expect(boundingBox.projection == .epsg32662)
        #expect(boundingBox.southWest.x == 0.0)
        #expect(boundingBox.northEast.y == 10.0)

        #expect(polygon.contains(Coordinate3D(x: 5.0, y: 5.0, projection: .epsg32662)))
        #expect(!polygon.contains(Coordinate3D(x: 15.0, y: 5.0, projection: .epsg32662)))
    }

    // Validates antimeridian detection and cutting in EPSG:32662, where the
    // wraparound axis is at ±180 degrees.
    @Test
    func antimeridian() async throws {
        let lineCoordinates: [Coordinate3D] = [
            Coordinate3D(x: 170.0, y: 45.0, projection: .epsg32662),
            Coordinate3D(x: -170.0, y: 45.0, projection: .epsg32662),
        ]
        let line = try #require(LineString(unchecked: lineCoordinates))

        #expect(line.crossesAntimeridian)

        let cut = line.cutAtAntimeridian()
        #expect(cut.features.count == 2)

        // Per RFC 7946 §3.1.9, the cut points are at ±180.
        let first = try #require((cut.features[0].geometry as? LineString)?.coordinates.last)
        let second = try #require((cut.features[1].geometry as? LineString)?.coordinates.first)
        #expect(abs(first.longitude) == 180.0)
        #expect(abs(second.longitude) == 180.0)

        // A line not crossing the axis stays untouched.
        let plainLineCoordinates: [Coordinate3D] = [
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg32662),
            Coordinate3D(x: 10.0, y: 10.0, projection: .epsg32662),
        ]
        let plainLine = try #require(LineString(unchecked: plainLineCoordinates))
        #expect(!plainLine.crossesAntimeridian)
        #expect(plainLine.cutAtAntimeridian().features.count == 1)
    }

    // Validates normalize/clamp behavior in EPSG:32662.
    @Test
    func normalizeAndClamp() async throws {
        let normalized = Coordinate3D(x: 190.0, y: 0.0, projection: .epsg32662).normalized()
        #expect(normalized.longitude == -170.0)

        let clamped = Coordinate3D(x: 190.0, y: 95.0, projection: .epsg32662).clamped()
        #expect(clamped.longitude == 180.0)
        #expect(clamped.latitude == 90.0)
    }

    // Validates WKB round trips in the new projections (the SRID is embedded
    // in the WKB data).
    @Test
    func wkbRoundTrip() async throws {
        for projection: Projection in [.epsg3395, .epsg32662] {
            let point = Point(Coordinate3D(x: 123.0, y: 456.0, projection: projection))

            let wkb = try #require(WKBCoder.encode(geometry: point, targetProjection: projection))
            let decoded = try #require(WKBCoder.decode(
                wkb: wkb,
                sourceSrid: nil,
                targetProjection: projection) as? Point)
            #expect(decoded.projection == projection)
            #expect(abs(decoded.coordinate.x - 123.0) < 0.0000000001)
            #expect(abs(decoded.coordinate.y - 456.0) < 0.0000000001)
        }
    }

}
