#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Swiss oblique Mercator (`somerc`) math, parameterized by ellipsoid and
/// projection origin.
///
/// Faithful port of the PROJ `somerc` implementation (the Swiss OB.
/// Mercator, Hotine-oblique-cylindrical chain with a Newton iteration in
/// the inverse; see PROJ's `src/projections/somerc.cpp`). Used by the
/// Swiss EPSG:2056 (LV95) and EPSG:21781 (LV03) projections, the published
/// published origin parameters from the EPSG
/// registry: lat0 = 46°57'08.66" N, lon0 = 7°26'22.5" E, scale factor 1,
/// false easting/northing per datum generation (2_600_000/1_200_000 for
/// LV95, 600_000/200_000 for LV03).
struct SwissObliqueMercatorMath: Sendable {

    /// The Bessel 1841 ellipsoid the projection is computed on.
    let ellipsoid: Ellipsoid

    /// The latitude of the projection's origin, in degrees.
    let latitudeOfOrigin: Double

    /// The longitude of the projection's origin, in degrees.
    let longitudeOfOrigin: Double

    /// The scale factor (1.0 for the Swiss grids).
    let scaleFactor: Double

    /// The false easting applied to x values, in meters.
    let falseEasting: Double

    /// The false northing applied to y values, in meters.
    let falseNorthing: Double

    // MARK: - Hoisted setup data (PROJ`s K, c, sinp0/cosp0/kR)

    private let halfE: Double
    private let cParameter: Double
    private let bigK: Double
    private let kR: Double
    private let sinP0: Double
    private let cosP0: Double
    /// The projection pole's conformal latitude (PROJ's `phip0`), needed
    /// for the K constant.
    private let phiP0: Double

    init(
        ellipsoid: Ellipsoid,
        latitudeOfOrigin: Double,
        longitudeOfOrigin: Double,
        scaleFactor: Double,
        falseEasting: Double,
        falseNorthing: Double
    ) {
        self.ellipsoid = ellipsoid
        self.latitudeOfOrigin = latitudeOfOrigin
        self.longitudeOfOrigin = longitudeOfOrigin
        self.scaleFactor = scaleFactor
        self.falseEasting = falseEasting
        self.falseNorthing = falseNorthing

        let e = sqrt(ellipsoid.eccentricitySquared)
        let phi0 = latitudeOfOrigin.degreesToRadians

        halfE = 0.5 * e

        let cosPhi0 = cos(phi0)
        let roneEs = 1.0 / (1.0 - ellipsoid.eccentricitySquared)
        cParameter = sqrt(1.0 + ellipsoid.eccentricitySquared * cosPhi0 * cosPhi0 * roneEs)

        let sinPhi0 = sin(phi0)
        sinP0 = sinPhi0 / cParameter
        phiP0 = asin(sinP0)
        cosP0 = cos(phiP0)

        let e3 = e * sinPhi0
        bigK = log(tan(.pi / 4.0 + 0.5 * phiP0))
            - cParameter * (
                log(tan(.pi / 4.0 + 0.5 * phi0))
                    - halfE * log((1.0 + e3) / (1.0 - e3))
            )
        // PROJ's bundled somerc stage: kR = k0·a/c (the classical Snyder
        // R' = a·√(1−e²)/(1−e²sin²φ₀) differs by ~0.15% on the Bessel
        // ellipsoid, which shifts Swiss grid coordinates by up to ~80 m).
        kR = scaleFactor * ellipsoid.semiMajorAxis / cParameter
    }

    // MARK: - Forward

    /// The PROJ somerc forward formulas (ellipsoidal): geodetic degrees
    /// into grid coordinates in meters.
    func forward(
        latitude: Double,
        longitude: Double
    ) -> (x: Double, y: Double) {
        let phi = latitude.degreesToRadians
        let lambda = longitude.degreesToRadians - longitudeOfOrigin.degreesToRadians

        let sp = sqrt(ellipsoid.eccentricitySquared) * sin(phi)
        let phiP = 2.0 * atan(
            exp(cParameter * (
                log(tan(.pi / 4.0 + 0.5 * phi))
                    - halfE * log((1.0 + sp) / (1.0 - sp))
            ) + bigK)
        ) - .pi / 2.0

        let lambdaP = cParameter * lambda
        let cosPhiP = cos(phiP)
        let phiPP = asin(cosP0 * sin(phiP) - sinP0 * cosPhiP * cos(lambdaP))
        let lambdaPP = asin(cosPhiP * sin(lambdaP) / cos(phiPP))

        let x = falseEasting + kR * lambdaPP
        let y = falseNorthing + kR * log(tan(.pi / 4.0 + 0.5 * phiPP))

        return (x, y)
    }

    // MARK: - Inverse

    /// The PROJ somerc inverse formulas (ellipsoidal): grid coordinates in
    /// meters into geodetic degrees. Newton-iterated (6 iterations as in
    /// the reference implementation, early-exit at a converged delta).
    func inverse(
        x: Double,
        y: Double
    ) -> (latitude: Double, longitude: Double) {
        let relativeX = x - falseEasting
        let relativeY = y - falseNorthing

        let phiPP = 2.0 * (atan(exp(relativeY / kR)) - .pi / 4.0)
        let lambdaPP = relativeX / kR
        let cosPhiPP = cos(phiPP)

        let phiP = asin(cosP0 * sin(phiPP) + sinP0 * cosPhiPP * cos(lambdaPP))
        let lambdaP = asin(cosPhiPP * sin(lambdaPP) / cos(phiP))

        let con = (bigK - log(tan(.pi / 4.0 + 0.5 * phiP))) / cParameter
        let e = sqrt(ellipsoid.eccentricitySquared)

        var currentPhi = phiP
        let epsilon = 0.0000000001
        for _ in 0 ..< 6 {
            let esp = e * sin(currentPhi)
            let deltaP = (con + log(tan(.pi / 4.0 + 0.5 * currentPhi))
                - halfE * log((1.0 + esp) / (1.0 - esp)))
                * (1.0 - esp * esp) * cos(currentPhi)
                / (1.0 - ellipsoid.eccentricitySquared)
            currentPhi -= deltaP
            if abs(deltaP) < epsilon {
                break
            }
        }

        let latitude = currentPhi * 180.0 / .pi
        let longitude = (lambdaP / cParameter) * 180.0 / .pi + longitudeOfOrigin

        return (latitude, longitude)
    }

}
