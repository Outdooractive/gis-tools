#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Conversion tests for the Swiss/Irish CRS family.
///
/// Reference values computed independently with pyproj/PROJ (EPSG
/// transformations as documented below). Round trips were measured
/// accordingly (see per-suite notes).
struct SwissIrishCrsTests {

    /// Validates WGS84 → EPSG:2056 (LV95) against reference values
    /// (helmert "CH1903+ to WGS 84 (1)" + somerc on Bessel 1841).
    @Test
    func lv95ReferenceValues() async throws {
        let fixtures: [(lat: Double, lon: Double, expectE: Double, expectN: Double)] = [
            (47.0, 8.0, 2_642_695.4202, 1_205_590.5223),
            (46.5, 7.5, 2_604_710.3116, 1_149_856.0408),
            (46.95, 7.44, 2_600_104.1095, 1_199_879.6282),
            (47.5, 9.2, 2_732_704.4721, 1_262_516.4916),
            (46.0, 6.9, 2_558_268.7462, 1_094_415.2424),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(latitude: fixture.lat, longitude: fixture.lon)
                .projected(to: .epsg2056)
            #expect(abs(projected.longitude - fixture.expectE) < 0.001)
            #expect(abs(projected.latitude - fixture.expectN) < 0.001)
            #expect(projected.projection == .epsg2056)

            let back = projected.projected(to: .epsg4326)
            #expect(abs(back.latitude - fixture.lat) < 0.000001)
            #expect(abs(back.longitude - fixture.lon) < 0.000001)
        }
    }

    /// Validates WGS84 → EPSG:21781 (LV03) against reference values.
    @Test
    func lv03ReferenceValues() async throws {
        let fixtures: [(lat: Double, lon: Double, expectE: Double, expectN: Double)] = [
            (47.0, 8.0, 642_695.4202, 205_590.5223),
            (46.5, 7.5, 604_710.3116, 149_856.0408),
            (46.95, 7.44, 600_104.1095, 199_879.6282),
            (47.5, 9.2, 732_704.4721, 262_516.4916),
            (46.0, 6.9, 558_268.7462, 94_415.2424),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(latitude: fixture.lat, longitude: fixture.lon)
                .projected(to: .epsg21781)
            #expect(abs(projected.longitude - fixture.expectE) < 0.001)
            #expect(abs(projected.latitude - fixture.expectN) < 0.001)

            let back = projected.projected(to: .epsg4326)
            #expect(abs(back.latitude - fixture.lat) < 0.000001)
            #expect(abs(back.longitude - fixture.lon) < 0.000001)
        }
    }

    /// Validates WGS84 → EPSG:29902 (TM65 / Irish Grid) against reference
    /// values (helmert "TM65 to WGS 84 (2)" + TM on Modified Airy).
    @Test
    func irishGridTM65ReferenceValues() async throws {
        let fixtures: [(lat: Double, lon: Double, expectE: Double, expectN: Double)] = [
            (53.5, -8.0, 200_049.0167, 249_976.4461),
            (53.35, -6.3, 313_256.5237, 234_629.9200),
            (54.0, -10.0, 68_900.7224, 307_480.0178),
            (51.9, -10.2, 48_625.3838, 74_208.5905),
            (54.5, -6.0, 329_619.3459, 363_127.4645),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(latitude: fixture.lat, longitude: fixture.lon)
                .projected(to: .epsg29902)
            #expect(abs(projected.longitude - fixture.expectE) < 0.001)
            #expect(abs(projected.latitude - fixture.expectN) < 0.001)

            let back = projected.projected(to: .epsg4326)
            #expect(abs(back.latitude - fixture.lat) < 0.000001)
            #expect(abs(back.longitude - fixture.lon) < 0.000001)
        }
    }

    /// Validates WGS84 → EPSG:29903 (TM75 / Irish Grid) — the projected
    /// math coincides with 29902; the datum readjustment differences
    /// surface in the Helmert set (the same 7-param values are pinned by
    /// EPSG for both TM65 and TM75 datum frames at meter accuracy).
    @Test
    func irishGridTM75ReferenceValues() async throws {
        let projected = Coordinate3D(latitude: 53.5, longitude: -8.0)
            .projected(to: .epsg29903)
        #expect(abs(projected.longitude - 200_049.0167) < 0.001)
        #expect(abs(projected.latitude - 249_976.4461) < 0.001)

        let back = projected.projected(to: .epsg4326)
        #expect(abs(back.latitude - 53.5) < 0.000001)
        #expect(abs(back.longitude - -8.0) < 0.000001)
    }

    /// Validates WGS84 → EPSG:2157 (IRENET95 / ITM, identity to the
    /// WGS84 pivot) against reference values.
    @Test
    func irishMetricReferenceValues() async throws {
        let fixtures: [(lat: Double, lon: Double, expectE: Double, expectN: Double)] = [
            (53.5, -8.0, 600_000.0000, 750_000.0000),
            (53.35, -6.3, 713_183.0378, 734_656.1766),
            (54.0, -10.0, 468_880.2722, 807_491.8819),
            (51.9, -10.2, 448_608.0342, 574_270.8352),
            (54.5, -6.0, 729_543.0179, 863_125.9498),
        ]

        for fixture in fixtures {
            let projected = Coordinate3D(latitude: fixture.lat, longitude: fixture.lon)
                .projected(to: .epsg2157)
            #expect(abs(projected.longitude - fixture.expectE) < 0.001)
            #expect(abs(projected.latitude - fixture.expectN) < 0.001)

            let back = projected.projected(to: .epsg4326)
            #expect(abs(back.latitude - fixture.lat) < 0.00000001)
            #expect(abs(back.longitude - fixture.lon) < 0.000001)
        }
    }

    /// Validates datum pivot routing for the new CRSs.
    @Test
    func pivotRoundTrips() async throws {
        let fixtures: [(lat: Double, lon: Double)] = [
            (47.0, 8.0), (46.95, 7.44),
        ]

        for fixture in fixtures {
            let original = Coordinate3D(latitude: fixture.lat, longitude: fixture.lon)
            for target in [Projection.epsg2056, .epsg21781] {
                let projected = original.projected(to: target)
                let homeAgain = projected.projected(to: .epsg4326)
                #expect(abs(homeAgain.latitude - fixture.lat) < 0.000002)
                #expect(abs(homeAgain.longitude - fixture.lon) < 0.000002)
            }
        }

        for target in [Projection.epsg29902, .epsg29903, .epsg2157] {
            let projected = Coordinate3D(latitude: 53.35, longitude: -6.3)
                .projected(to: target)
            let homeAgain = projected.projected(to: .epsg4326)
            #expect(abs(homeAgain.latitude - 53.35) < 0.000002)
            #expect(abs(homeAgain.longitude - -6.3) < 0.000002)
        }
    }

    /// Validates algorithm smoke behavior across the new CRSs.
    @Test
    func algorithmSmokeTests() async throws {
        // Planar kind for all the projected grids (all unbounded extents,
        // therefore all coordinates within them are valid).
        for projection in [Projection.epsg2056, .epsg21781, .epsg29902, .epsg29903, .epsg2157] {
            #expect(projection.kind == .planar)
            #expect(projection.wraparoundExtent == nil)
            #expect(Coordinate3D(x: 1.0, y: 1.0, projection: projection).isValid)
        }

        // Euclidean distance in the Swiss grid.
        let origin = Coordinate3D(x: 2_600_000.0, y: 1_200_000.0, projection: .epsg2056)
        let point = Coordinate3D(x: 2_600_000.0, y: 1_201_000.0, projection: .epsg2056)
        #expect(abs(origin.distance(from: point) - 1_000.0) < 0.000001)
    }

    /// Validates WKT recognition for the Swiss/Irish projections.
    @Test
    func wktMatching() async throws {
        #expect(Projection(wkt: #"PROJCS["CH1903+ / LV95"]"#) == .epsg2056)
        #expect(Projection(wkt: #"PROJCS["CH1903 / LV03"]"#) == .epsg21781)
        #expect(Projection(wkt: #"PROJCS["TM65 / Irish Grid"]"#) == .epsg29902)
        #expect(Projection(wkt: #"PROJCS["TM75 / Irish Grid"]"#) == .epsg29903)
        #expect(Projection(wkt: #"PROJCS["IRENET95 / Irish Transverse Mercator"]"#) == .epsg2157)
        #expect(Projection(wkt: #"PROJCS["Unknown"]"#) == nil)
    }

    /// Validates batch conversion equivalence for the new CRSs: the batch
    /// path must equal the per-coordinate path output-for-output.
    @Test
    func batchEquivalence() async throws {
        for (projection, coordinates) in [
            (Projection.epsg2056, [
                Coordinate3D(latitude: 47.0, longitude: 8.0),
                Coordinate3D(latitude: 46.95, longitude: 7.44),
            ]),
            (Projection.epsg21781, [
                Coordinate3D(latitude: 47.0, longitude: 8.0),
            ]),
            (Projection.epsg29902, [
                Coordinate3D(latitude: 53.5, longitude: -8.0),
                Coordinate3D(latitude: 53.35, longitude: -6.3),
            ]),
            (Projection.epsg2157, [
                Coordinate3D(latitude: 53.5, longitude: -8.0),
                Coordinate3D(latitude: 53.35, longitude: -6.3),
            ]),
        ] {
            let batch = coordinates.projected(to: projection)
            let singles = coordinates.map { $0.projected(to: projection) }
            for (batchCoordinate, singleCoordinate) in zip(batch, singles) {
                #expect(batchCoordinate == singleCoordinate)
            }
        }
    }

    /// Validates WKB round trips with embedded SRIDs for the new CRSs.
    @Test
    func wkbRoundTrip() async throws {
        for projection: Projection in [.epsg2056, .epsg21781, .epsg29902, .epsg29903, .epsg2157] {
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
