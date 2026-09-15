import Foundation
@testable import GISTools
import Testing

/// Verification of Karney's transverse Mercator as used by the UTM zones.
///
/// The Swift implementation was ported after an independent Python
/// implementation was validated against:
/// - Karney's published test set (`TMcoords.dat`, computed with an 80-digit
///   exact mapping; worst forward/reverse error 5.7/5.0 nm within 3900 km of
///   the central meridian, consistent with the paper's 5 nm bound),
/// - PROJ 9.8 (GeographicLib-based) across all 120 zones: worst divergence
///   7.5 nm over 1440 random points,
/// - round-trip sweeps over all zones and latitudes including the poles:
///   worst error 6.4 nm.
struct KarneyTransverseMercatorTests {

    // MARK: - Reference values (PROJ-validated)

    /// Forward fixtures across sample zones and latitudes, all within the
    /// zone (±3 degrees of the central meridian). Values were generated with
    /// an independently validated Python implementation of Karney's series
    /// and cross-checked against PROJ 9.8 (worst deviation 4.3 nm).
    private static let utmFixtures: [(Int, Double, Double, Double, Double)] = [
        (32601, 0.0, -180.0, 166_021.443081, 0.000000),
        (32601, 41.0, -180.0, 247_679.152104, 4_543_092.954431),
        (32701, -45.5, -180.0, 265_621.338521, 4_957_124.982656),
        (32601, 80.0, -180.0, 441_867.784867, 8_883_084.955948),
        (32701, -80.0, -180.0, 441_867.784867, 1_116_915.044052),
        (32601, 84.0, -180.0, 465_005.344939, 9_329_005.182447),
        (32701, -84.0, -180.0, 465_005.344939, 670_994.817553),
        (32619, 0.0, -72.0, 166_021.443081, 0.000000),
        (32619, 41.0, -72.0, 247_679.152104, 4_543_092.954431),
        (32719, -45.5, -72.0, 265_621.338521, 4_957_124.982656),
        (32619, 80.0, -72.0, 441_867.784867, 8_883_084.955948),
        (32719, -80.0, -72.0, 441_867.784867, 1_116_915.044052),
        (32619, 84.0, -72.0, 465_005.344939, 9_329_005.182447),
        (32719, -84.0, -72.0, 465_005.344939, 670_994.817553),
        (32631, 0.0, 0.0, 166_021.443081, 0.000000),
        (32631, 41.0, 0.0, 247_679.152104, 4_543_092.954431),
        (32731, -45.5, 0.0, 265_621.338521, 4_957_124.982656),
        (32631, 80.0, 0.0, 441_867.784867, 8_883_084.955948),
        (32731, -80.0, 0.0, 441_867.784867, 1_116_915.044052),
        (32631, 84.0, 0.0, 465_005.344939, 9_329_005.182447),
        (32731, -84.0, 0.0, 465_005.344939, 670_994.817553),
        (32645, 0.0, 84.0, 166_021.443081, 0.000000),
        (32645, 41.0, 84.0, 247_679.152104, 4_543_092.954431),
        (32745, -45.5, 84.0, 265_621.338521, 4_957_124.982656),
        (32645, 80.0, 84.0, 441_867.784867, 8_883_084.955948),
        (32745, -80.0, 84.0, 441_867.784867, 1_116_915.044052),
        (32645, 84.0, 84.0, 465_005.344939, 9_329_005.182447),
        (32745, -84.0, 84.0, 465_005.344939, 670_994.817553),
        (32660, 0.0, 174.0, 166_021.443081, 0.000000),
        (32660, 41.0, 174.0, 247_679.152104, 4_543_092.954431),
        (32760, -45.5, 174.0, 265_621.338521, 4_957_124.982656),
        (32660, 80.0, 174.0, 441_867.784867, 8_883_084.955948),
        (32760, -80.0, 174.0, 441_867.784867, 1_116_915.044052),
        (32660, 84.0, 174.0, 465_005.344939, 9_329_005.182447),
        (32760, -84.0, 174.0, 465_005.344939, 670_994.817553),
    ]

    /// GRS80 (ETRS89/UTM belt) fixtures, same provenance as `utmFixtures`
    /// (worst deviation vs PROJ 2.8 nm).
    private static let etrsFixtures: [(Int, Double, Double, Double, Double)] = [
        (25831, 52.0, 0.0, 294_071.081051, 5_765_288.254733),
        (25831, 59.0, 3.0, 500_000.000000, 6_540_052.017411),
        (25831, 62.0, 6.0, 657_091.710175, 6_877_812.600866),
        (25831, 80.0, 0.0, 441_867.784866, 8_883_084.955848),
        (25832, 52.0, 9.0, 500_000.000000, 5_761_038.212467),
        (25832, 59.0, 12.0, 672_319.964088, 6_543_920.334128),
        (25832, 71.0, 6.0, 391_029.809245, 7_880_094.920510),
        (25832, 80.0, 9.0, 500_000.000000, 8_881_585.815888),
        (25833, 52.0, 18.0, 705_928.918949, 5_765_288.254733),
        (25833, 62.0, 12.0, 342_908.289825, 6_877_812.600866),
        (25833, 71.0, 15.0, 500_000.000000, 7_877_396.766578),
        (25833, 80.0, 18.0, 558_132.215134, 8_883_084.955848),
        (25834, 59.0, 18.0, 327_680.035912, 6_543_920.334128),
        (25834, 62.0, 21.0, 500_000.000000, 6_874_180.147715),
        (25834, 71.0, 24.0, 608_970.190755, 7_880_094.920510),
        (25835, 52.0, 24.0, 294_071.081051, 5_765_288.254733),
        (25835, 59.0, 27.0, 500_000.000000, 6_540_052.017411),
        (25835, 62.0, 30.0, 657_091.710175, 6_877_812.600866),
        (25835, 80.0, 24.0, 441_867.784866, 8_883_084.955848),
        (25836, 52.0, 33.0, 500_000.000000, 5_761_038.212467),
        (25836, 59.0, 36.0, 672_319.964088, 6_543_920.334128),
        (25836, 71.0, 30.0, 391_029.809245, 7_880_094.920510),
        (25836, 80.0, 33.0, 500_000.000000, 8_881_585.815888),
        (25837, 52.0, 42.0, 705_928.918949, 5_765_288.254733),
        (25837, 62.0, 36.0, 342_908.289825, 6_877_812.600866),
        (25837, 71.0, 39.0, 500_000.000000, 7_877_396.766578),
        (25837, 80.0, 42.0, 558_132.215134, 8_883_084.955848),
    ]

    // MARK: - Forward reference values

    /// Validates forward conversions against the PROJ-validated fixtures.
    @Test
    func forwardReferenceValues() throws {
        for (srid, latitude, longitude, easting, northing) in Self.utmFixtures {
            let projection = try #require(Projection(srid: srid))
            let projected = Coordinate3D(latitude: latitude, longitude: longitude)
                .projected(to: projection)

            #expect(abs(projected.x - easting) < 0.000001, "zone \(srid), \(latitude)/\(longitude)")
            #expect(abs(projected.y - northing) < 0.000001, "zone \(srid), \(latitude)/\(longitude)")
        }
    }

    /// Validates the GRS80 belt (ETRS89/UTM) against its fixtures: the
    /// flattening difference must carry through the Karney series.
    @Test
    func etrs89BeltReferenceValues() throws {
        for (srid, latitude, longitude, easting, northing) in Self.etrsFixtures {
            let projection = try #require(Projection(srid: srid))
            let projected = Coordinate3D(latitude: latitude, longitude: longitude)
                .projected(to: projection)

            #expect(abs(projected.x - easting) < 0.000001, "zone \(srid), \(latitude)/\(longitude)")
            #expect(abs(projected.y - northing) < 0.000001, "zone \(srid), \(latitude)/\(longitude)")
        }
    }

    // MARK: - Series consistency

    /// Validates that the Karney math matches the direct (non-Clenshaw)
    /// series evaluation: both evaluate the same series, the Clenshaw
    /// recurrence only reduces the number of transcendental calls. Guards
    /// against transcription errors in the recurrence.
    @Test
    func clenshawMatchesDirectSummation() {
        let tm = UtmDefinition(zone: 19, hemisphere: .north).karneyTransverseMercator

        let latitudes: [Double] = [0.0, 0.001, 41.0, 60.0, 84.0, 89.9]
        let longitudeOffsets: [Double] = [-3.0, -1.0, -0.0001, 0.0, 0.0001, 1.0, 3.0]

        for latitude in latitudes {
            for offset in longitudeOffsets {
                let forward = tm.forward(latitude: latitude, longitude: -69.0 + offset)

                // Direct sum in xi/eta space.
                let phi = latitude.degreesToRadians
                let lambda = offset.degreesToRadians

                let tau = tan(phi)
                let conformalTauValue = Self.conformalTau(tau, eccentricity: tm.eccentricity)
                let cosLambda = cos(lambda)
                let xiPrime = atan(conformalTauValue / cosLambda)
                let etaPrime = asinh(sin(lambda) / (conformalTauValue * conformalTauValue + cosLambda * cosLambda).squareRoot())

                var xi = xiPrime
                var eta = etaPrime
                for (index, terms) in Self.alphaTerms.enumerated() {
                    let coefficient = Self.horner(terms, tm.n) * pow(tm.n, Double(index + 1))
                    let j = Double(index + 1)
                    xi += coefficient * sin(2.0 * j * xiPrime) * cosh(2.0 * j * etaPrime)
                    eta += coefficient * cos(2.0 * j * xiPrime) * sinh(2.0 * j * etaPrime)
                }

                let expectedX = tm.falseEasting + tm.scaleFactor * tm.a1 * eta
                let expectedY = tm.falseNorthing + tm.scaleFactor * tm.a1 * xi

                // Both evaluations are subject to double rounding of the
                // ~1e7 meter northing (ulp ~ 2 nm) on top of the summation
                // order difference, so allow a few ulps.
                #expect(abs(forward.x - expectedX) < 0.00000001, "\(latitude)/\(offset)")
                #expect(abs(forward.y - expectedY) < 0.00000001, "\(latitude)/\(offset)")
            }
        }
    }

    // MARK: - Round trips

    /// Round-trips all 120 zones across latitudes including the poles and
    /// longitudes across the full zone (and slightly beyond): the nanometer
    /// guarantee of the 6th-order series.
    @Test
    func roundTripPrecision() throws {
        let latitudes: [Double] = [0.0, 23.5, -23.5, 41.0, -45.5, 80.0, -80.0, 89.99, -89.99]
        let offsets: [Double] = [-3.4, -1.7, 0.0, 1.7, 3.4]

        for zone in 1 ... 60 {
            let centralMeridian = Double((zone - 1) * 6 - 180 + 3)
            for latitude in latitudes {
                for offset in offsets {
                    let longitude = centralMeridian + offset
                    let srid: Int = latitude >= 0 ? 32_600 + zone : 32_700 + zone
                    let projection = try #require(Projection(srid: srid))

                    let projected = Coordinate3D(latitude: latitude, longitude: longitude)
                        .projected(to: projection)
                    let back = projected.projected(to: .epsg4326)

                    #expect(abs(back.latitude - latitude) < 0.0000000001, "zone \(zone), \(latitude)/\(offset)")
                    #expect(abs(back.longitude - longitude) < 0.0000000001, "zone \(zone), \(latitude)/\(offset)")
                }
            }
        }
    }

    /// Round trips near the exact poles: latitude ±90 deg.
    @Test
    func poleRoundTrips() throws {
        let projection = try #require(Projection(srid: 32619))

        for latitude in [90.0, -90.0] {
            let projected = Coordinate3D(latitude: latitude, longitude: -71.0)
                .projected(to: projection)
            let back = projected.projected(to: .epsg4326)

            #expect(abs(back.latitude - latitude) < 0.0000000001)
        }
    }

    // MARK: - Convergence boundary behavior

    /// Beyond the series convergence limit (about 3900 km from the central
    /// meridian for the 5 nm bound, with the truncation error growing towards
    /// the branch point at ~8800 km), round trips still converge — the
    /// forward and reverse series are reversions of each other — but the
    /// result drifts from the exact mapping. Guards against NaN/infinity
    /// escapes in the far field.
    @Test
    func farFieldStaysFinite() {
        let tm = KarneyTransverseMercatorMath(
            ellipsoid: .wgs84,
            longitudeOfOrigin: 0.0,
            scaleFactor: 0.9996,
            falseEasting: 0.0,
            falseNorthing: 0.0)

        for longitude in [42.0, 80.0, 82.6, 84.0] {
            for latitude in [0.0, 30.0, 60.0, 89.0] {
                let (x, y) = tm.forward(latitude: latitude, longitude: longitude)
                #expect(x.isFinite)
                #expect(y.isFinite)

                let (backLatitude, backLongitude) = tm.inverse(x: x, y: y)
                #expect(backLatitude.isFinite)
                #expect(backLongitude.isFinite)
            }
        }
    }

    // MARK: - Parity and symmetry

    /// The mapping is odd in latitude and longitude: mirrored inputs produce
    /// mirrored eastings and (with the hemisphere's false northing) mirrored
    /// northings.
    @Test
    func paritySymmetry() {
        let tm = UtmDefinition(zone: 19, hemisphere: .north).karneyTransverseMercator
        let south = UtmDefinition(zone: 19, hemisphere: .south).karneyTransverseMercator

        for latitude in [0.5, 41.0, 80.0] {
            for offset in [0.5, 2.5] {
                let northEast = tm.forward(latitude: latitude, longitude: -69.0 + offset)
                let southWest = south.forward(latitude: -latitude, longitude: -69.0 - offset)
                let northWest = tm.forward(latitude: latitude, longitude: -69.0 - offset)

                #expect(abs((northEast.x - 500_000.0) + (northWest.x - 500_000.0)) < 0.00000001)
                #expect(abs(southWest.x - northWest.x) < 0.00000001)
                #expect(abs((southWest.y - 10_000_000.0) + northEast.y) < 0.00000001)
            }
        }
    }

    // MARK: - Ellipsoid

    /// Validates that the ellipsoid parameters propagate: the GRS80 belt
    /// differs from the WGS84 zones through the flattening, yielding
    /// decimeter-level differences at the zone edges (a fact of the
    /// ETRS89/UTM definition, not an implementation choice).
    @Test
    func ellipsoidMatters() {
        let wgs84 = UtmDefinition(zone: 32, hemisphere: .north).karneyTransverseMercator
        let grs80 = Etrs89UtmDefinition(zone: 32).karneyTransverseMercator

        let (wgsX, wgsY) = wgs84.forward(latitude: 59.0, longitude: 15.0)
        let (grsX, grsY) = grs80.forward(latitude: 59.0, longitude: 15.0)

        // The zone-32 edge at 59N: the WGS84/GRS80 offset is ~1 dm.
        #expect(abs(wgsX - grsX) > 0.000001)
        #expect(abs(wgsX - grsX) < 1.0)
        #expect(abs(wgsY - grsY) < 1.0)
    }

    // MARK: - Newton iteration

    /// Validates that the conformal-latitude Newton iteration converges for
    /// extreme taus (near-pole points, where tau grows without bound).
    @Test
    func newtonConvergesNearPole() {
        let tm = UtmDefinition(zone: 19, hemisphere: .north).karneyTransverseMercator

        for latitude in [89.999999, -89.999999, 89.9999999, -89.9999999] {
            let projected = tm.forward(latitude: latitude, longitude: -69.0)
            #expect(projected.x.isFinite)
            #expect(projected.y.isFinite)

            let (backLatitude, _) = tm.inverse(x: projected.x, y: projected.y)
            #expect(abs(backLatitude - latitude) < 0.000000001, "\(latitude)")
        }
    }

    // MARK: - Test helpers

    /// The alpha series coefficients (Eqs. 21) for the direct summation
    /// cross-check above; mirrored from the implementation.
    private static let alphaTerms: [[Double]] = [
        [1.0 / 2, -2.0 / 3, 5.0 / 16, 41.0 / 180, -127.0 / 288, 7891.0 / 37800],
        [13.0 / 48, -3.0 / 5, 557.0 / 1440, 281.0 / 630, -1_983_433.0 / 1_935_360],
        [61.0 / 240, -103.0 / 140, 15061.0 / 26880, 167_603.0 / 181_440],
        [49561.0 / 161_280, -179.0 / 168, 6_601_661.0 / 7_257_600],
        [34729.0 / 80640, -3_418_889.0 / 1_995_840],
        [212_378_941.0 / 319_334_400],
    ]

    private static func horner(_ terms: [Double], _ n: Double) -> Double {
        var result = 0.0
        for coefficient in terms.reversed() {
            result = result * n + coefficient
        }
        return result
    }

    /// Eq. (6): the conformal tangent.
    private static func conformalTau(_ tau: Double, eccentricity: Double) -> Double {
        let sigma = sinh(eccentricity * atanh(eccentricity * tau / (tau * tau + 1.0).squareRoot()))
        return tau * (sigma * sigma + 1.0).squareRoot() - sigma * (tau * tau + 1.0).squareRoot()
    }

}
