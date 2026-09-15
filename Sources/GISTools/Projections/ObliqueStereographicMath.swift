#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Oblique stereographic (`sterea`, EPSG method 9809 "Oblique
/// Stereographic") math, parameterized by ellipsoid and projection origin.
///
/// Faithful port of the PROJ `sterea` implementation plus the
/// Gaussian-conformal ellipsoid reduction it is built on (see PROJ's
/// `src/projections/sterea.cpp` and `src/gauss.cpp`). Used by the Dutch
/// EPSG:28992 (RD New) definition and available publicly through
/// ``CustomProjection/obliqueStereographic(datum:helmert:)``.
struct ObliqueStereographicMath: Sendable {

    /// The ellipsoid the projection is computed on.
    let ellipsoid: Ellipsoid

    /// The latitude of the projection's origin, in degrees.
    let latitudeOfOrigin: Double

    /// The longitude of the projection's origin, in degrees.
    let longitudeOfOrigin: Double

    /// The scale factor (0.9999079 for RD New).
    let scaleFactor: Double

    /// The false easting applied to x values, in meters.
    let falseEasting: Double

    /// The false northing applied to y values, in meters.
    let falseNorthing: Double

    // MARK: - Hoisted setup data (PROJ's gauss constants + sterea state)

    private let gaussC: Double
    private let gaussExp: Double
    private let gaussExpInverse: Double
    private let gaussK: Double
    private let gaussianLatitudeOfOrigin: Double
    private let gaussScale: Double
    private let sinC0: Double
    private let cosC0: Double
    private let doubleRadius: Double

    init(
        ellipsoid: Ellipsoid,
        latitudeOfOrigin: Double,
        longitudeOfOrigin: Double,
        scaleFactor: Double,
        falseEasting: Double = 0.0,
        falseNorthing: Double = 0.0
    ) {
        self.ellipsoid = ellipsoid
        self.latitudeOfOrigin = latitudeOfOrigin
        self.longitudeOfOrigin = longitudeOfOrigin
        self.scaleFactor = scaleFactor
        self.falseEasting = falseEasting
        self.falseNorthing = falseNorthing

        let es = ellipsoid.eccentricitySquared
        let e = sqrt(es)
        let phi0 = latitudeOfOrigin.degreesToRadians

        // pj_gauss_ini: the Gaussian ellipsoid parameters. Note PROJ's
        // `cphi` is squared *before* entering the C formula, so the
        // Gaussian conformal sphere constant carries cos^4(phi0).
        let sinPhi0 = sin(phi0)
        let cosPhi0Squared = cos(phi0) * cos(phi0)
        gaussScale = sqrt(1.0 - es) / (1.0 - es * sinPhi0 * sinPhi0)
        gaussC = sqrt(1.0 + es * cosPhi0Squared * cosPhi0Squared / (1.0 - es))
        gaussianLatitudeOfOrigin = asin(sinPhi0 / gaussC)
        gaussExp = 0.5 * gaussC * e
        gaussExpInverse = 1.0 / gaussC
        gaussK = tan(.pi / 4.0 + 0.5 * gaussianLatitudeOfOrigin)
            / (pow(tan(.pi / 4.0 + 0.5 * phi0), gaussC)
                * Self.srat(e * sinPhi0, gaussExp))

        sinC0 = sin(gaussianLatitudeOfOrigin)
        cosC0 = cos(gaussianLatitudeOfOrigin)
        doubleRadius = 2.0 * gaussScale
    }

    // MARK: - Forward

    /// PROJ sterea forward formulas: geodetic degrees into grid
    /// coordinates in meters.
    func forward(
        latitude: Double,
        longitude: Double
    ) -> (x: Double, y: Double) {
        let phi = latitude.degreesToRadians
        let lambda = longitude.degreesToRadians - longitudeOfOrigin.degreesToRadians

        // pj_gauss: onto the Gaussian-conformal sphere.
        let gaussianPhi = 2.0 * atan(
            gaussK * pow(tan(.pi / 4.0 + 0.5 * phi), gaussC)
                * Self.srat(sqrt(ellipsoid.eccentricitySquared) * sin(phi), gaussExp)
        ) - .pi / 2.0
        let gaussianLambda = gaussC * lambda

        let sinPhiG = sin(gaussianPhi)
        let cosPhiG = cos(gaussianPhi)
        let denominator = 1.0 + sinC0 * sinPhiG + cosC0 * cosPhiG * cos(gaussianLambda)

        let k = scaleFactor * doubleRadius / denominator
        let x = falseEasting + ellipsoid.semiMajorAxis * k * cosPhiG * sin(gaussianLambda)
        let y = falseNorthing + ellipsoid.semiMajorAxis * k * (
            cosC0 * sinPhiG - sinC0 * cosPhiG * cos(gaussianLambda))

        return (x, y)
    }

    // MARK: - Inverse

    /// PROJ sterea inverse formulas: grid coordinates in meters into
    /// geodetic degrees.
    func inverse(
        x: Double,
        y: Double
    ) -> (latitude: Double, longitude: Double) {
        let a = ellipsoid.semiMajorAxis
        let dx = (x - falseEasting) / (a * scaleFactor)
        let dy = (y - falseNorthing) / (a * scaleFactor)
        let rho = hypot(dx, dy)

        let gaussianPhi: Double
        let scaledLambda: Double
        if rho != 0.0 {
            let c = 2.0 * atan2(rho, doubleRadius)
            let sinC = sin(c)
            let cosC = cos(c)
            gaussianPhi = asin(cosC * sinC0 + dy * sinC * cosC0 / rho)
            scaledLambda = atan2(dx * sinC, rho * cosC0 * cosC - dy * sinC0 * sinC)
        }
        else {
            gaussianPhi = gaussianLatitudeOfOrigin
            scaledLambda = 0.0
        }

        // pj_inv_gauss: back from the Gaussian sphere, Newton-iterated.
        let lambdaPrime = scaledLambda * gaussExpInverse
        let compliantTan = pow(tan(.pi / 4.0 + 0.5 * gaussianPhi) / gaussK, gaussExpInverse)
        let e = sqrt(ellipsoid.eccentricitySquared)

        var iterations = 20
        var phi = gaussianPhi
        while iterations > 0 {
            let candidatePhi = 2.0 * atan(compliantTan * Self.srat(e * sin(phi), -0.5 * e)) - .pi / 2.0
            if abs(candidatePhi - phi) < 0.00000000000001 {
                phi = candidatePhi
                break
            }
            phi = candidatePhi
            iterations -= 1
        }

        return (
            phi * 180.0 / .pi,
            longitudeOfOrigin + lambdaPrime * 180.0 / .pi
        )
    }

    // MARK: - PROJ helper

    /// PROJ's `srat`: the ratio ((1 − esinp) / (1 + esinp))^(ratexp).
    private static func srat(_ esinPhi: Double, _ exponent: Double) -> Double {
        pow((1.0 - esinPhi) / (1.0 + esinPhi), exponent)
    }

}
