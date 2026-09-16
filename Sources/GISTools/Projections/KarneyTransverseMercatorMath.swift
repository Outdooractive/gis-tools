#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Karney's transverse Mercator (the Krüger series extended to 6th order).
///
/// Implements the series method of C. F. F. Karney, *Transverse Mercator
/// with an accuracy of a few nanometers* (arXiv:1002.1417), Eqs. (1)–(30):
/// the ellipsoid is mapped to the conformal sphere, the spherical transverse
/// Mercator (Gauss-Schreiber) coordinates are "rectified" through Krüger's
/// series, and the geographic latitude is recovered with a Newton iteration.
/// All series are evaluated with Clenshaw summation.
///
/// Within about 3900 km of the central meridian the truncation error stays
/// below ~5 nm (the paper's Fig. 2); the UTM zones (±334 km of the central
/// meridian) are covered with orders of magnitude to spare. The series
/// diverges beyond the branch cut at the equator, at a longitude of
/// (1 - e) * 90° from the central meridian (~82.64° for WGS84); results
/// beyond that boundary are not meaningful.
///
/// Compared to the Snyder formulas (``TransverseMercatorMath``), this
/// implementation is numerically accurate essentially anywhere inside the
/// convergence region instead of degrading with longitude difference; the
/// two agree within ~1 mm in-zone (both are valid UTM) and diverge beyond
/// the zone at the millimeter level.
///
/// Parameterization matches ``TransverseMercatorMath``: ellipsoid, origin,
/// central scale factor and false easting/northing.
struct KarneyTransverseMercatorMath: Sendable {

    // MARK: - Series coefficients

    /// The Krüger series coefficients alpha_j (forward) and beta_j (reverse),
    /// Eqs. (21) and (22) of Karney (2011), each listed with its terms of
    /// n^j, n^(j+1), ... Row j holds the terms of the j-th series.
    private static let alphaTerms: [[Double]] = [
        [1.0 / 2, -2.0 / 3, 5.0 / 16, 41.0 / 180, -127.0 / 288, 7891.0 / 37800],
        [13.0 / 48, -3.0 / 5, 557.0 / 1440, 281.0 / 630, -1_983_433.0 / 1_935_360],
        [61.0 / 240, -103.0 / 140, 15061.0 / 26880, 167_603.0 / 181_440],
        [49561.0 / 161_280, -179.0 / 168, 6_601_661.0 / 7_257_600],
        [34729.0 / 80640, -3_418_889.0 / 1_995_840],
        [212_378_941.0 / 319_334_400],
    ]

    private static let betaTerms: [[Double]] = [
        [1.0 / 2, -2.0 / 3, 37.0 / 96, -1.0 / 360, -81.0 / 512, 96199.0 / 604_800],
        [1.0 / 48, 1.0 / 15, -437.0 / 1440, 46.0 / 105, -1_118_711.0 / 3_870_720],
        [17.0 / 480, -37.0 / 840, -209.0 / 4480, 5569.0 / 90720],
        [4397.0 / 161_280, -11.0 / 504, -830_251.0 / 7_257_600],
        [4583.0 / 161_280, -108_847.0 / 3_991_680],
        [20_648_693.0 / 638_668_800],
    ]

    // MARK: - Stored parameterization

    /// The ellipsoid the projection is computed on.
    let ellipsoid: Ellipsoid

    /// The longitude of the projection's central meridian, in degrees.
    let longitudeOfOrigin: Double

    /// The central scale factor (e.g. 0.9996 for the UTM convention).
    let scaleFactor: Double

    /// The false easting applied to x values, in meters.
    let falseEasting: Double

    /// The false northing applied to y values, in meters.
    let falseNorthing: Double

    // MARK: - Derived constants (computed once at init)

    /// The third flattening n = f / (2 - f).
    let n: Double

    /// The eccentricity e = sqrt(f (2 - f)).
    let eccentricity: Double

    /// e² - 1 (negative of the polar radius of curvature factor).
    private let oneMinusE2: Double

    /// A = a / (1 + n) * (1 + n²/4 + n⁴/64), Eq. (25): the meridian
    /// circumference scale constant.
    let a1: Double

    /// The alpha_j series coefficients in Horner form.
    let alpha: [Double]

    /// The beta_j series coefficients in Horner form.
    let beta: [Double]

    init(
        ellipsoid: Ellipsoid,
        longitudeOfOrigin: Double,
        scaleFactor: Double,
        falseEasting: Double,
        falseNorthing: Double = 0.0
    ) {
        self.ellipsoid = ellipsoid
        self.longitudeOfOrigin = longitudeOfOrigin
        self.scaleFactor = scaleFactor
        self.falseEasting = falseEasting
        self.falseNorthing = falseNorthing

        let f = 1.0 / ellipsoid.inverseFlattening
        let n = f / (2.0 - f)
        self.n = n
        self.eccentricity = sqrt(f * (2.0 - f))
        self.oneMinusE2 = 1.0 - f * (2.0 - f)

        // Eq. (25): A = a/(1+n) * (1 + n^2/4 + n^4/64 + n^6/256 + ...)
        self.a1 = ellipsoid.semiMajorAxis / (1.0 + n)
            * (1.0 + n * n / 4.0 + pow(n, 4) / 64.0 + pow(n, 6) / 256.0)

        /// Each row j carries its leading n^j factor; the remaining terms
        /// are evaluated in Horner form (Eqs. 21-22).
        func hornerSeries(_ terms: [Double]) -> Double {
            var result = 0.0
            for coefficient in terms.reversed() {
                result = result * n + coefficient
            }
            return result
        }

        var alphaSeries: [Double] = []
        alphaSeries.reserveCapacity(Self.alphaTerms.count)
        for (index, terms) in Self.alphaTerms.enumerated() {
            alphaSeries.append(hornerSeries(terms) * pow(n, Double(index + 1)))
        }
        var betaSeries: [Double] = []
        betaSeries.reserveCapacity(Self.betaTerms.count)
        for (index, terms) in Self.betaTerms.enumerated() {
            betaSeries.append(hornerSeries(terms) * pow(n, Double(index + 1)))
        }
        self.alpha = alphaSeries
        self.beta = betaSeries
    }

    // MARK: - Conformal latitude

    /// The conformal tangent tau' = tan(phi'), Eq. (6):
    /// `tau' = tau sqrt(1 + sigma^2) - sigma sqrt(1 + tau^2)` with
    /// sigma = sinh(e atanh(e tau / sqrt(1 + tau^2))) (Eq. 7).
    private func conformalTau(_ tau: Double) -> Double {
        let sigma = sinh(eccentricity * atanh(eccentricity * tau / (tau * tau + 1.0).squareRoot()))
        return tau * (sigma * sigma + 1.0).squareRoot() - sigma * (tau * tau + 1.0).squareRoot()
    }

    /// Solves Eq. (6) for tau given tau' with Newton iteration, Eqs. (23)-(24).
    /// The iteration converges quadratically; two iterations suffice
    /// anywhere on the ellipsoid.
    ///
    /// For unbounded tau' (the pole) the initial guess from the lowest-order
    /// relation tau ~ tau' / (1 - e^2) is returned directly, matching the
    /// exact asymptotics at the pole within the double-precision limit.
    private func tau(fromConformalTau conformalTauValue: Double) -> Double {
        var tau = conformalTauValue / oneMinusE2
        for _ in 0 ..< 6 {
            let tauNormalized = (tau * tau + 1.0).squareRoot()
            let sigma = sinh(eccentricity * atanh(eccentricity * tau / tauNormalized))
            let conformal = tau * (sigma * sigma + 1.0).squareRoot() - sigma * tauNormalized
            // Eq. (23): dtau = (tau' - tau'_i) / sqrt(1 + tau'^2)
            //   * (1 + (1-e^2) tau^2) / ((1-e^2) sqrt(1 + tau^2))
            let delta = (conformalTauValue - conformal)
                / (conformal * conformal + 1.0).squareRoot()
                * (1.0 + oneMinusE2 * tau * tau)
                / (oneMinusE2 * tauNormalized)
            if !delta.isFinite {
                break
            }
            tau += delta
            if abs(delta) <= GISTool.equalityDelta * max(1.0, abs(tau)) {
                break
            }
        }
        return tau
    }

    // MARK: - Forward

    /// Karney forward mapping, Eqs. (8)-(9) and (18): geodetic degrees into
    /// grid coordinates in meters.
    ///
    /// - Parameters:
    ///   - latitude: The geodetic latitude, in degrees
    ///   - longitude: The geodetic longitude, in degrees
    /// - Returns: The grid easting and northing, in meters
    func forward(
        latitude: Double,
        longitude: Double
    ) -> (x: Double, y: Double) {
        let phi = latitude.degreesToRadians
        let lambda = (longitude - longitudeOfOrigin).degreesToRadians

        let tau = tan(phi)
        let conformalTau = self.conformalTau(tau)

        let sinLambda = sin(lambda)
        let cosLambda = cos(lambda)

        // Eq. (8): Gauss-Schreiber (spherical TM) coordinates.
        let xiPrime = atan(conformalTau / cosLambda)
        let etaPrime = asinh(sinLambda / (conformalTau * conformalTau + cosLambda * cosLambda).squareRoot())

        // Eq. (9): the Krüger series, evaluated with Clenshaw summation.
        let xiEta = Self.clenshawSummation(xiPrime, etaPrime, coefficients: alpha)
        let xi = xiPrime + xiEta.xi
        let eta = etaPrime + xiEta.eta

        // Eq. (18): scale and offset to grid coordinates.
        return (
            falseEasting + scaleFactor * a1 * eta,
            falseNorthing + scaleFactor * a1 * xi
        )
    }

    // MARK: - Inverse

    /// Karney reverse mapping, Eqs. (16)-(17) and (22)-(24): grid
    /// coordinates in meters into geodetic degrees.
    ///
    /// - Parameters:
    ///   - x: The grid easting, in meters
    ///   - y: The grid northing, in meters
    /// - Returns: The geodetic latitude and longitude, in degrees
    func inverse(
        x: Double,
        y: Double
    ) -> (latitude: Double, longitude: Double) {
        let xi = (y - falseNorthing) / (scaleFactor * a1)
        let eta = (x - falseEasting) / (scaleFactor * a1)

        // Eq. (17): the reverted Krüger series (Clenshaw summation).
        let xiEta = Self.clenshawSummation(xi, eta, coefficients: beta, negated: true)
        let xiPrime = xi + xiEta.xi
        let etaPrime = eta + xiEta.eta

        // Eq. (16): back to the conformal sphere.
        let sinhEtaPrime = sinh(etaPrime)
        let cosXiPrime = cos(xiPrime)
        let radius = (sinhEtaPrime * sinhEtaPrime + cosXiPrime * cosXiPrime).squareRoot()

        // radius == 0 identifies the pole (xi' = pi/2, eta' = 0), where
        // tau is unbounded and phi = atan(tau) = pi/2.
        let conformalTauValue = radius > 0.0 ? sin(xiPrime) / radius : Double.infinity
        let tau = self.tau(fromConformalTau: conformalTauValue)

        let phi = atan(tau)
        let lambda = atan2(sinhEtaPrime, cosXiPrime)

        return (
            phi.radiansToDegrees,
            longitudeOfOrigin + lambda.radiansToDegrees
        )
    }

    // MARK: - Clenshaw summation

    /// Clenshaw summation of the Krüger series, as laid out in Sec. 2 of
    /// Karney (2011) ("evaluate ... using Clenshaw summation which
    /// minimizes the number of evaluations of trigonometric and
    /// hyperbolic functions").
    ///
    /// For the forward direction this computes
    /// `sum alpha_j sin(2j zeta')` in split real/imaginary parts; the
    /// reverse uses the beta series (set `negated`).
    ///
    /// - Parameters:
    ///   - xiPrime: The real (meridian) Gauss-Schreiber component
    ///   - etaPrime: The imaginary (perpendicular) component
    ///   - coefficients: The series coefficients (alpha or beta)
    ///   - negated: Negate the series terms (the reverse series)
    /// - Returns: The series sum split into its xi and eta components
    private static func clenshawSummation(
        _ xiPrime: Double,
        _ etaPrime: Double,
        coefficients: [Double],
        negated: Bool = false
    ) -> (xi: Double, eta: Double) {
        // sin(2j zeta') = sin(2j xi') cosh(2j eta') + i cos(2j xi') sinh(2j eta')
        // With z = 2 zeta' the Clenshaw recurrence is
        //   b[j] = 2 cos(z) b[j+1] - b[j+2] + a[j]
        // evaluated over complex numbers:
        //   cos(z) = cos(2 xi') cosh(2 eta') - i sin(2 xi') sinh(2 eta')
        let twoXi = 2.0 * xiPrime
        let twoEta = 2.0 * etaPrime
        let cosTwoXi = cos(twoXi)
        let coshTwoEta = cosh(twoEta)
        let sinTwoXi = sin(twoXi)
        let sinhTwoEta = sinh(twoEta)

        // 2 cos(z) = cReal + i cImag.
        let cReal = 2.0 * cosTwoXi * coshTwoEta
        let cImag = -2.0 * sinTwoXi * sinhTwoEta

        let count = coefficients.count
        // The recurrence runs from the top index down to 1.
        var b1Real = 0.0
        var b1Imag = 0.0
        var b2Real = 0.0
        var b2Imag = 0.0

        var index = count
        while index >= 1 {
            let coefficient = negated ? -coefficients[index - 1] : coefficients[index - 1]
            // b0 = (cReal + i cImag) * (b1Real + i b1Imag) - (b2Real + i b2Imag) + a
            let b0Real = cReal * b1Real - cImag * b1Imag - b2Real + coefficient
            let b0Imag = cImag * b1Real + cReal * b1Imag - b2Imag
            b2Real = b1Real
            b2Imag = b1Imag
            b1Real = b0Real
            b1Imag = b0Imag
            index -= 1
        }

        // The sum: sin(2 zeta') = sReal + i sImag, series = (b1 + i b2) * sin(2 zeta').
        let sReal = sinTwoXi * coshTwoEta
        let sImag = cosTwoXi * sinhTwoEta
        let seriesReal = b1Real * sReal - b1Imag * sImag
        let seriesImag = b1Real * sImag + b1Imag * sReal

        return (seriesReal, seriesImag)
    }

}
