#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// The authalic (equal-area) latitude conversion via the Karney auxlat
/// series (PROJ 9's `pj_auxlat_coeffs` for `AuxLat::AUTHALIC` →
/// `AuxLat::GEOGRAPHIC`).
///
/// A Fourier series in the authalic latitude whose coefficients are Taylor
/// polynomials in the third flattening n, truncated at order 6. This
/// conversion reaches full double precision (Karney 2024, *On auxiliary
/// latitudes*, Table 5: relative error < 2⁻⁵³ for |f| ≤ 1/150); the legacy
/// 3-term Snyder series loses about a millimeter at large distances.
///
/// Shared by the projections whose inverse or forward needs the conversion:
/// laea (``LambertAzimuthalEqualAreaMath``) and albers
/// (``AlbersEqualAreaMath``).
struct AuthalicLatitude: Sendable {

    /// The series coefficients for the ellipsoid, evaluated once.
    private let series: [Double]

    init(ellipsoid: Ellipsoid) {
        let f = 1.0 - sqrt(1.0 - ellipsoid.eccentricitySquared)
        let n = f / (2.0 - f)

        // The constant-matrix rows from PROJ's generated table, in
        // ascending power order per row (rows have 6, 5, 4, 3, 2, 1 terms).
        let rows: [[Double]] = [
            [
                4.0 / 3,
                4.0 / 45,
                -16.0 / 35,
                -2582.0 / 14175,
                60136.0 / 467_775,
                28_112_932.0 / 212_837_625,
            ],
            [
                46.0 / 45,
                152.0 / 945,
                -11966.0 / 14175,
                -21016.0 / 51975,
                251_310_128.0 / 638_512_875,
            ],
            [
                3044.0 / 2835,
                3802.0 / 14175,
                -94388.0 / 66825,
                -8_797_648.0 / 10_945_935,
            ],
            [
                6059.0 / 4725,
                41072.0 / 93555,
                -1_472_637_812.0 / 638_512_875,
            ],
            [
                768_272.0 / 467_775,
                455_935_736.0 / 638_512_875,
            ],
            [
                4_210_684_958.0 / 1_915_538_625,
            ],
        ]

        var coefficients: [Double] = []
        coefficients.reserveCapacity(rows.count)
        var factor = n
        for row in rows {
            // PROJ's pj_polyval: ascending coefficients, Horner evaluation.
            var polynomial = 0.0
            for coefficient in row.reversed() {
                polynomial = polynomial * n + coefficient
            }
            coefficients.append(factor * polynomial)
            factor *= n
        }
        self.series = coefficients
    }

    /// PROJ's `pj_auxlat_convert` for the authalic → geographic direction:
    /// `phi = xi + sum F[l] sin((2l+2) xi)`, evaluated with the Clenshaw
    /// recurrence over the Chebyshev argument 2 cos(2 xi).
    func geographicLatitude(fromAuthalic xi: Double) -> Double {
        let sinXi = sin(xi)
        let cosXi = cos(xi)

        // The Clenshaw argument X = 2 cos(2 xi).
        let argument = 2.0 * (cosXi - sinXi) * (cosXi + sinXi)

        var u0 = 0.0
        var u1 = 0.0
        for coefficient in series.reversed() {
            let next = argument * u0 - u1 + coefficient
            u1 = u0
            u0 = next
        }

        // sin(2 xi) * u0.
        return xi + 2.0 * sinXi * cosXi * u0
    }

    /// Snyder's authalic sine q (formulas 3-11/3-12, PROJ's
    /// `pj_authalic_lat_q` with the `atanh` form).
    ///
    /// - Parameter phi: The geodetic latitude, in radians
    /// - Returns: The authalic sine of the latitude
    static func q(_ phi: Double, eccentricity e: Double) -> Double {
        let oneEs = 1.0 - e * e
        let sinPhi = sin(phi)
        return oneEs * (sinPhi / (1.0 - e * e * sinPhi * sinPhi) + atanh(e * sinPhi) / e)
    }

}
