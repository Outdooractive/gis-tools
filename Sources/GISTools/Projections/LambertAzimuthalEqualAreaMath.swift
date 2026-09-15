#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Lambert azimuthal equal-area (`laea`) math, parameterized by ellipsoid
/// and projection origin.
///
/// Faithful port of the PROJ `laea` implementation (Snyder's ellipsoidal
/// equal-area formulas with the authalic latitude series; see PROJ's
/// `src/projections/laea.cpp`, `src/auth.cpp` and `src/qsfn.cpp`). Used by
/// the pan-European EPSG:3035 definition and available publicly through
/// ``CustomProjection/lambertAzimuthalEqualArea(datum:helmert:)``.
struct LambertAzimuthalEqualAreaMath: Sendable {

    // The mapping modes of PROJ's laea implementation, keyed by which of
    // the four domains the projection origin falls into.
    private enum Mode {
        case northPole
        case southPole
        case equatorial
        case oblique
    }

    /// The ellipsoid the projection is computed on.
    let ellipsoid: Ellipsoid

    /// The latitude of the projection's origin, in degrees.
    let latitudeOfOrigin: Double

    /// The longitude of the projection's origin, in degrees.
    let longitudeOfOrigin: Double

    /// The scale factor (1.0 for EPSG:3035).
    let scaleFactor: Double

    /// The false easting applied to x values, in meters.
    let falseEasting: Double

    /// The false northing applied to y values, in meters.
    let falseNorthing: Double

    // MARK: - Hoisted setup data

    private let mode: Mode
    private let qPole: Double
    private let authalicSeries: (Double, Double, Double)
    private let radiusQ: Double
    private let sinB1: Double
    private let cosB1: Double
    private let dD: Double
    private let xmf: Double
    private let ymf: Double

    init(
        ellipsoid: Ellipsoid,
        latitudeOfOrigin: Double,
        longitudeOfOrigin: Double,
        scaleFactor: Double = 1.0,
        falseEasting: Double = 0.0,
        falseNorthing: Double = 0.0
    ) {
        let phi0 = latitudeOfOrigin.degreesToRadians
        let es = ellipsoid.eccentricitySquared
        let e = sqrt(es)
        let oneEs = 1.0 - es

        self.ellipsoid = ellipsoid
        self.latitudeOfOrigin = latitudeOfOrigin
        self.longitudeOfOrigin = longitudeOfOrigin
        self.scaleFactor = scaleFactor
        self.falseEasting = falseEasting
        self.falseNorthing = falseNorthing

        // PROJ's mode selection guard (EPS10: ±90° origins are polar).
        if abs(abs(phi0) - Double.pi / 2.0) < 0.0000000001 {
            mode = phi0 < 0.0 ? .southPole : .northPole
        }
        else if abs(phi0) < 0.0000000001 {
            mode = .equatorial
        }
        else {
            mode = .oblique
        }

        qPole = Self.qsfn(1.0, e, oneEs)
        authalicSeries = Self.authSet(es)

        switch mode {
        case .northPole, .southPole:
            radiusQ = 0.0
            sinB1 = 0.0
            cosB1 = 0.0
            dD = 1.0
            xmf = 0.0
            ymf = 0.0
        case .equatorial:
            radiusQ = sqrt(0.5 * qPole)
            sinB1 = 0.0
            cosB1 = 0.0
            dD = 1.0 / radiusQ
            xmf = 1.0
            ymf = 0.5 * qPole
        case .oblique:
            radiusQ = sqrt(0.5 * qPole)
            sinB1 = Self.qsfn(sin(phi0), e, oneEs) / qPole
            cosB1 = sqrt(1.0 - sinB1 * sinB1)
            dD = cos(phi0) / (sqrt(1.0 - es * sin(phi0) * sin(phi0)) * radiusQ * cosB1)
            xmf = radiusQ * dD
            ymf = radiusQ / dD
        }
    }

    // MARK: - Forward

    /// PROJ laea forward formulas (ellipsoidal): geodetic degrees into
    /// grid coordinates in meters.
    func forward(
        latitude: Double,
        longitude: Double
    ) -> (x: Double, y: Double) {
        let e = sqrt(ellipsoid.eccentricitySquared)
        let oneEs = 1.0 - ellipsoid.eccentricitySquared

        let phi = latitude.degreesToRadians
        let lambda = longitude.degreesToRadians - longitudeOfOrigin.degreesToRadians

        let cosLambda = cos(lambda)
        let sinLambda = sin(lambda)
        let sinPhi = sin(phi)

        let q = Self.qsfn(sinPhi, e, oneEs)

        var sinB = 0.0
        var cosB = 0.0
        if mode == .oblique || mode == .equatorial {
            sinB = q / qPole
            let cosSquare = 1.0 - sinB * sinB
            cosB = cosSquare > 0.0 ? sqrt(cosSquare) : 0.0
        }

        let scalingOpt: Double?
        switch mode {
        case .oblique:
            let b = 1.0 + sinB1 * sinB + cosB1 * cosB * cosLambda
            scalingOpt = abs(b) < 0.0000000001 ? nil : b
        case .equatorial:
            let b = 1.0 + cosB * cosLambda
            scalingOpt = abs(b) < 0.0000000001 ? nil : 1.0 + cosB * cosLambda
        case .northPole:
            // PROJ rewrites q and only guards |b| for a real zero (which
            // cannot happen for the polar branches).
            scalingOpt = 1.0
        case .southPole:
            scalingOpt = 1.0
        }

        guard let _ = scalingOpt else {
            return (Double.nan, Double.nan)  // outside the projection domain
        }

        switch mode {
        case .oblique:
            let scaling = sqrt(2.0 / scalingOpt!)
            let x = ellipsoid.semiMajorAxis * scaleFactor * xmf * scaling * cosB * sinLambda
            let y = ellipsoid.semiMajorAxis * scaleFactor * ymf * scaling * (
                cosB1 * sinB - sinB1 * cosB * cosLambda)
            return (falseEasting + x, falseNorthing + y)

        case .equatorial:
            let scaling = sqrt(2.0 / (1.0 + cosB * cosLambda))
            let x = ellipsoid.semiMajorAxis * scaleFactor * xmf * scaling * cosB * sinLambda
            let y = ellipsoid.semiMajorAxis * scaleFactor * scaling * sinB * ymf
            return (falseEasting + x, falseNorthing + y)

        case .northPole, .southPole:
            let qPrime = mode == .northPole ? qPole - q : qPole + q
            // PROJ falls back to the projection center for a vanishing q.
            if qPrime < 1e-15 {
                return (falseEasting, falseNorthing)
            }
            let radius = scaleFactor * sqrt(qPrime)
            let x = falseEasting + radius * sinLambda
            let y = falseNorthing + radius * (mode == .southPole ? cosLambda : -cosLambda)
            return (x, y)
        }
    }

    // MARK: - Inverse

    /// PROJ laea inverse formulas: grid coordinates in meters into geodetic
    /// degrees.
    func inverse(
        x: Double,
        y: Double
    ) -> (latitude: Double, longitude: Double) {
        switch mode {
        case .oblique, .equatorial:
            var dx = (x - falseEasting) / (ellipsoid.semiMajorAxis * dD)
            let dy = (y - falseNorthing) * dD / ellipsoid.semiMajorAxis
            let rho = hypot(dx, dy)
            if rho < 0.0000000001 {
                return (latitudeOfOrigin, longitudeOfOrigin)
            }
            guard 0.5 * rho / radiusQ <= 1.0 else {
                return (Double.nan, Double.nan)   // outside the projection domain
            }
            let cAngle = 2.0 * asin(0.5 * rho / radiusQ)
            let cosC = cos(cAngle)
            let sinC = sin(cAngle)
            dx *= sinC
            let authalic: Double
            let meridian: Double
            if mode == .oblique {
                authalic = cosC * sinB1 + dy * sinC * cosB1 / rho
                meridian = rho * cosB1 * cosC - dy * sinB1 * sinC
            }
            else {
                authalic = dy * sinC / rho
                meridian = rho * cosC
            }
            let lambda = atan2(dx, meridian)
            let phi = authalicLatitude(asin(authalic))
            return (
                phi * 180.0 / .pi,
                longitudeOfOrigin + lambda * 180.0 / .pi
            )

        case .northPole, .southPole:
            let rawDy = (y - falseNorthing)
            let dy = (mode == .northPole ? -rawDy : rawDy) / ellipsoid.semiMajorAxis
            let dx = (x - falseEasting) / ellipsoid.semiMajorAxis
            let q = dx * dx + dy * dy
            if q == 0.0 {
                return (latitudeOfOrigin, longitudeOfOrigin)
            }
            let authalic = mode == .southPole
                ? -(1.0 - q / qPole)
                : 1.0 - q / qPole
            let lambda = atan2(dx, dy)
            let phi = authalicLatitude(asin(authalic))
            return (
                phi * 180.0 / .pi,
                longitudeOfOrigin + lambda * 180.0 / .pi
            )
        }
    }

    // MARK: - PROJ helpers

    /// PROJ's `qsfn`: Snyder's authalic sine (equations 3-11/3-12).
    private static func qsfn(_ sinPhi: Double, _ e: Double, _ oneEs: Double) -> Double {
        let con = e * sinPhi
        let div1 = 1.0 - con * con
        let div2 = 1.0 + con
        if div1 == 0.0 || div2 == 0.0 {
            return .infinity
        }
        return oneEs * (sinPhi / div1 - (0.5 / e) * log((1.0 - con) / div2))
    }

    /// PROJ's `pj_authset`: the three coefficient series for the authalic
    /// (equal-area) latitude transformation.
    private static func authSet(_ es: Double) -> (Double, Double, Double) {
        let p00 = 0.33333333333333333333
        let p01 = 0.17222222222222222222
        let p02 = 0.10257936507936507937
        let p10 = 0.06388888888888888888
        let p11 = 0.06640211640211640212
        let p20 = 0.01677689594356261023

        var first = es * p00
        var second = 0.0
        var t = es * es
        first += t * p01
        second += t * p10
        t *= es
        first += t * p02
        second += t * p11
        let third = t * p20

        return (first, second, third)
    }

    /// PROJ's `pj_authlat`: latitude from the authalic latitude `beta`.
    private func authalicLatitude(_ beta: Double) -> Double {
        let t = beta + beta
        return beta + authalicSeries.0 * sin(t)
            + authalicSeries.1 * sin(t + t)
            + authalicSeries.2 * sin(t + t + t)
    }

}
