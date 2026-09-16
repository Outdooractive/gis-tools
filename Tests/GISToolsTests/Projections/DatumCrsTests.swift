#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Algorithm round trips and smoke tests for EPSG:4267 (NAD27 geodetic).
struct Nad27CrsTests {

    /// Validates forward conversions against reference values computed
    /// independently with pyproj/PROJ (via the Helmert-only
    /// "NAD27 to WGS 84 (4)" transformation).
    @Test
    func referenceValues() async throws {
        let fixtures: [(lat: Double, lon: Double, expectLat: Double, expectLon: Double)] = [
            (40.0, -100.0, 39.999990516, -99.999582393),
            (35.0, -105.0, 34.999924993, -104.999461737),
            (45.0, -68.0, 45.000057988, -68.000666074),
            (61.0, -149.0, 61.000455150, -148.997389203),
            (25.0, -80.0, 24.999595268, -80.000197174),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(latitude: fixture.lat, longitude: fixture.lon)
                .projected(to: .epsg4267)
            #expect(abs(projected.latitude - fixture.expectLat) < 0.000000001)
            #expect(abs(projected.longitude - fixture.expectLon) < 0.000000001)
        }
    }

    /// Validates round trips through all projections with the datum pivot.
    @Test
    func roundTrips() async throws {
        let fixtures: [(lat: Double, lon: Double)] = [
            (40.0, -100.0), (35.0, -105.0), (45.0, -68.0), (61.0, -149.0), (25.0, -80.0),
        ]

        for fixture in fixtures {
            let original = Coordinate3D(latitude: fixture.lat, longitude: fixture.lon, altitude: 300.0, m: 3.0)

            let nad27 = original.projected(to: .epsg4267)
            #expect(nad27.projection == .epsg4267)
            #expect(Projection.epsg4267.datum == Datum.nad27)

            let back = nad27.projected(to: .epsg4326)
            #expect(abs(back.latitude - fixture.lat) < 0.000002)
            #expect(abs(back.longitude - fixture.lon) < 0.000002)

            // Through the WGS84 pivot into the other datum-capable CRSs.
            for target in [Projection.epsg4326, .epsg4258] {
                let projected = original.projected(to: target)
                let homeAgain = projected.projected(to: .epsg4326)
                #expect(abs(homeAgain.latitude - fixture.lat) < 0.000002)
                #expect(abs(homeAgain.longitude - fixture.lon) < 0.000002)
            }
        }

        // Round trips through the British National Grid (in-domain points:
        // the TM series is only valid on British territory, like any
        // transverse Mercator-based CRS beyond its zone).
        for fixture in [
            (lat: 52.0, lon: -1.0), (lat: 55.5, lon: -3.0), (lat: 58.5, lon: -5.0),
        ] {
            let original = Coordinate3D(latitude: fixture.lat, longitude: fixture.lon)
            let target = original.projected(to: .epsg27700)
            #expect(target.projection == .epsg27700)
            let homeAgain = target.projected(to: .epsg4326)
            #expect(abs(homeAgain.latitude - fixture.lat) < 0.000002)
            #expect(abs(homeAgain.longitude - fixture.lon) < 0.000002)
        }
    }

    /// Validates BNG (27700) E/N coordinates against reference values
    /// computed independently with pyproj/PROJ.
    @Test
    func britishNationalGrid() async throws {
        let fixtures: [(lat: Double, lon: Double, expectE: Double, expectN: Double)] = [
            (52.0, -1.0, 468_748.5557, 233_978.3388),
            (55.5, -3.0, 336_926.9327, 623_367.5946),
            (49.95, -6.3, 91_648.8496, 14_401.7063),
            (58.5, -5.0, 225_281.6028, 960_772.9988),
            (50.5, 0.8, 598_665.9800, 70_433.2732),
            (59.0, -2.0, 400_099.7506, 1_012_543.3994),
        ]

        for fixture in fixtures {
            let bng = Coordinate3D(latitude: fixture.lat, longitude: fixture.lon)
                .projected(to: .epsg27700)
            #expect(abs(bng.longitude - fixture.expectE) < 0.001)
            #expect(abs(bng.latitude - fixture.expectN) < 0.001)
        }

        // Southwest grid values are valid (EPSG:27700 is unbounded, so
        // even out-of-sector coordinates like the far southwest stay valid
        // instead of being clamped away).
        let scilly = Coordinate3D(latitude: 49.95, longitude: -6.3).projected(to: .epsg27700)
        #expect(abs(scilly.longitude - 91_648.8496) < 0.001)
        #expect(abs(scilly.latitude - 14_401.7063) < 0.001)
        #expect(scilly.isValid)
        let back = scilly.projected(to: .epsg4326)
        #expect(abs(back.latitude - 49.95) < 0.000002)
        #expect(abs(back.longitude - -6.3) < 0.000002)
    }

    /// Validates algorithm behavior in the geographic datum CRSs
    /// (kind-based dispatch: Haversine distance, antimeridian handling).
    @Test
    func algorithmSmokeTests() async throws {
        // Geographic kind: haversine distance between London/Paris areas.
        let london = Coordinate3D(x: -0.12, y: 51.5, projection: .epsg4267)
        let paris = Coordinate3D(x: 2.35, y: 48.85, projection: .epsg4267)
        let distance = london.distance(from: paris)
        #expect(distance > 300_000.0)
        #expect(distance < 400_000.0)

        // Planar kind for BNG.
        let bng1 = Coordinate3D(x: 468_748.5557, y: 233_978.3388, projection: .epsg27700)
        let bng2 = Coordinate3D(x: 468_748.5557, y: 234_978.3388, projection: .epsg27700)
        #expect(abs(bng1.distance(from: bng2) - 1_000.0) < 0.000001)

        // Antimeridian handling in the datum geographic CRSs (wrap at ±180°).
        #expect(Projection.epsg4267.wraparoundExtent == 180.0)
        #expect(Projection.epsg27700.wraparoundExtent == nil)

        let normalized = Coordinate3D(
            x: -100.0,
            y: 40.0,
            projection: .epsg4267).normalized()
        #expect(abs(normalized.longitude - -100.0) < 0.00000001)
    }

    /// Validates WKB round trips with embedded SRIDs for the new projections.
    @Test
    func wkbRoundTrip() async throws {
        for (projection, x, y) in [
            (Projection.epsg4267, -99.999582393, 39.999990516),
            (Projection.epsg4258, 2.35, 48.85),
            (Projection.epsg4277, -0.998473603, 51.999560347),
            (Projection.epsg27700, 468_748.5557, 233_978.3388),
        ] {
            let point = Point(Coordinate3D(x: x, y: y, projection: projection))
            let wkb = try #require(WKBCoder.encode(geometry: point, targetProjection: projection))
            let decoded = try #require(WKBCoder.decode(
                wkb: wkb,
                sourceSrid: nil,
                targetProjection: projection) as? Point)

            #expect(decoded.projection == projection)
            #expect(abs(decoded.coordinate.x - x) < 0.000001)
            #expect(abs(decoded.coordinate.y - y) < 0.000001)
        }
    }

    /// Validates WKT recognition for the new datum-capable projections.
    @Test
    func wktMatching() async throws {
        #expect(Projection(wkt: #"GEOGCS["NAD 1927"]"#) == .epsg4267)
        #expect(Projection(wkt: #"GEOGCS["GCS_North_American_1927"]"#) == .epsg4267)
        #expect(Projection(wkt: #"GEOGCS["ETRS 1989"]"#) == .epsg4258)
        #expect(Projection(wkt: #"GEOGCS["OSGB_1936"]"#) == .epsg4277)
        #expect(Projection(wkt: #"PROJCS["OSGB 1936 / British National Grid",...Transverse_Mercator...]"#) == .epsg27700)
    }

}
