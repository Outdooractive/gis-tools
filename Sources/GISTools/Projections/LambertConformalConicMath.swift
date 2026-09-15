#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Lambert conformal conic (`lcc`) math, parameterized by ellipsoid,
/// projection origin and the two standard parallels.
///
/// Faithful port of the PROJ `lcc` implementation (Snyder formulas 15-1
/// through 15-4; see PROJ's `src/projections/lcc.cpp`; the inverse
/// latitude recovery is the conformal `tsfn`/`phi2` Newton iteration from
/// PROJ's `src/phi2.cpp` — GeographicLib's `tauf` method). Used by the
/// pan-European EPSG:3034 and the French EPSG:2154 definitions and
/// available publicly through
/// ``CustomProjection/lambertConformalConic(datum:helmert:)``.
struct LambertConformalConicMath: Sendable {

    /// The ellipsoid the projection is computed on.
    let ellipsoid: Ellipsoid

    /// The latitude of the projection's origin, in degrees.
    let latitudeOfOrigin: Double

    /// The longitude of the projection's origin (central meridian),
    /// in degrees.
    let longitudeOfOrigin: Double

    /// The latitude of the first standard parallel, in degrees.
    let latitudeOfFirstParallel: Double

    /// The latitude of the second standard parallel, in degrees (equal
    /// to the first for a tangent cone).
    let latitudeOfSecondParallel: Double

    /// The central scale factor.
    let scaleFactor: Double

    /// The false easting applied to x values, in meters.
    let falseEasting: Double

    /// The false northing applied to y values, in meters.
    let falseNorthing: Double

    // MARK: - Hoisted setup data (PROJ's n, c, rho0)

    private let coneConstant: Double
    private let cParameter: Double
    private let northingOfOrigin: Double

    init(
        ellipsoid: Ellipsoid,
        latitudeOfOrigin: Double,
        longitudeOfOrigin: Double,
        latitudeOfFirstParallel: Double,
        latitudeOfSecondParallel: Double,
        scaleFactor: Double = 1.0,
        falseEasting: Double = 0.0,
        falseNorthing: Double = 0.0
    ) {
        // PROJ's EPS10 domain guards: the mirror symmetry across the
        // equator degenerates for |lat1 + lat2| < 1e-10, and the msfn / t
        // series diverge at the poles.
        precondition(
            abs(latitudeOfFirstParallel + latitudeOfSecondParallel) >= 0.0000000001,
            "Invalid choice of standard parallels: the sum should be larger than epsilon")
        precondition(
            abs(latitudeOfFirstParallel) < 90.0 && abs(latitudeOfSecondParallel) < 90.0,
            "The standard parallels should keep |latitude| < 90 degrees")

        self.ellipsoid = ellipsoid
        self.latitudeOfOrigin = latitudeOfOrigin
        self.longitudeOfOrigin = longitudeOfOrigin
        self.latitudeOfFirstParallel = latitudeOfFirstParallel
        self.latitudeOfSecondParallel = latitudeOfSecondParallel
        self.scaleFactor = scaleFactor
        self.falseEasting = falseEasting
        self.falseNorthing = falseNorthing

        let phi1 = latitudeOfFirstParallel.degreesToRadians
        let phi2 = latitudeOfSecondParallel.degreesToRadians
        let phi0 = latitudeOfOrigin.degreesToRadians
        let es = ellipsoid.eccentricitySquared
        let e = sqrt(es)

        let secant = abs(phi1 - phi2) >= 0.0000000001

        let m1 = Self.msfn(sin(phi1), cos(phi1), es)
        let t1 = Self.tsfn(phi1, sin(phi1), e)

        if secant {
            let m2 = Self.msfn(sin(phi2), cos(phi2), es)
            let t2 = Self.tsfn(phi2, sin(phi2), e)
            coneConstant = log(m1 / m2) / log(t1 / t2)
        }
        else {
            coneConstant = sin(phi1)
        }

        cParameter = m1 * pow(t1, -coneConstant) / coneConstant
        northingOfOrigin = cParameter * pow(Self.tsfn(phi0, sin(phi0), e), coneConstant)
    }

    // MARK: - Forward

    /// PROJ lcc forward formulas (ellipsoidal): geodetic degrees into
    /// grid coordinates in meters.
    func forward(
        latitude: Double,
        longitude: Double
    ) -> (x: Double, y: Double) {
        let e = sqrt(ellipsoid.eccentricitySquared)
        let phi = latitude.degreesToRadians
        let lambda = longitude.degreesToRadians - longitudeOfOrigin.degreesToRadians

        let rho = cParameter * pow(Self.tsfn(phi, sin(phi), e), coneConstant)
        let lambdaN = lambda * coneConstant

        let x = falseEasting + ellipsoid.semiMajorAxis * scaleFactor * rho * sin(lambdaN)
        let y = falseNorthing + ellipsoid.semiMajorAxis * scaleFactor * (
            northingOfOrigin - rho * cos(lambdaN))

        return (x, y)
    }

    // MARK: - Inverse

    /// PROJ lcc inverse formulas: grid coordinates in meters into geodetic
    /// degrees.
    func inverse(
        x: Double,
        y: Double
    ) -> (latitude: Double, longitude: Double) {
        let e = sqrt(ellipsoid.eccentricitySquared)

        let a = ellipsoid.semiMajorAxis
        let dx = (x - falseEasting) / (a * scaleFactor)
        let dy = northingOfOrigin - (y - falseNorthing) / (a * scaleFactor)

        let rho = hypot(dx, dy)
        if rho == 0.0 {
            let pole = coneConstant > 0.0 ? 90.0 : -90.0
            return (pole, longitudeOfOrigin)
        }

        // PROJ mirrors rho and the direction coordinates through the cone
        // axis for a negative cone constant (southern cones).
        let rhoAbs = coneConstant < 0.0 ? -rho : rho
        let easting = coneConstant < 0.0 ? -dx : dx
        let northing = coneConstant < 0.0 ? -dy : dy

        let phi = Self.phi2(pow(rhoAbs / cParameter, 1.0 / coneConstant), e) * 180.0 / .pi
        let lambda = atan2(easting, northing) / coneConstant * 180.0 / .pi
        return (phi, longitudeOfOrigin + lambda)
    }

    // MARK: - Snyder tsfn/msfn/phi2 helpers

    /// Snyder's t function (equation 7-10): the isometric latitude
    /// exponent of `phi` in radians.
    private static func tsfn(_ phi: Double, _ sinPhi: Double, _ e: Double) -> Double {
        exp(e * atanh(e * sinPhi)) * (
            sinPhi > 0.0 ? cos(phi) / (1.0 + sinPhi) : (1.0 - sinPhi) / cos(phi)
        )
    }

    /// Snyder's m function (equation 7-2): the ellipsoidal distance
    /// scaling at the given latitude.
    private static func msfn(_ sinPhi: Double, _ cosPhi: Double, _ es: Double) -> Double {
        cosPhi / sqrt(1.0 - es * sinPhi * sinPhi)
    }

    /// PROJ's `pj_phi2`: latitude from the isometric latitude exponent
    /// `ts` (GeographicLib's `tauf` Newton iteration, PROJ's
    /// `src/phi2.cpp`).
    private static func phi2(_ ts: Double, _ e: Double) -> Double {
        let tauPrime = (1.0 / ts - ts) / 2.0
        let tau = sinhPsi2TanPhi(tauPrime, e)
        return atan(tau)
    }

    /// GeographicLib's `tauf`: converts tan(conformal latitude) into
    /// tan(latitude) (PROJ's `pj_sinhpsi2tanphi`, `src/phi2.cpp`).
    private static func sinhPsi2TanPhi(_ tauPrime: Double, _ e: Double) -> Double {
        let iterations = 5
        let rootEpsilon = sqrt(.ulpOfOne)   // ≈ 1.49e-8
        let tolerance = rootEpsilon / 10.0
        let tauMax = 2.0 / rootEpsilon
        let eSquaredMinusOne = 1.0 - e * e
        let scaleTolerance = tolerance * max(1.0, abs(tauPrime))

        var tau = abs(tauPrime) > 70.0
            ? tauPrime * exp(e * atanh(e))
            : tauPrime / eSquaredMinusOne
        guard abs(tau) < tauMax else { return tau }

        let maximum = iterations
        for _ in 0 ..< maximum {
            let tauNormalized = sqrt(1.0 + tau * tau)
            let sigma = sinh(e * atanh(e * tau / tauNormalized))
            let tauPrimeHyp = sqrt(1.0 + sigma * sigma) * tau - sigma * tauNormalized
            let delta = (tauPrime - tauPrimeHyp) * (
                (1.0 + eSquaredMinusOne * tau * tau) / (eSquaredMinusOne
                    * tauNormalized * sqrt(1.0 + tauPrimeHyp * tauPrimeHyp))
            )
            tau += delta
            if abs(delta) < scaleTolerance {
                break
            }
        }
        return tau
    }

}
