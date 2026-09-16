#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Lambert azimuthal equal-area (`laea`) math, parameterized by ellipsoid
/// and projection origin.
///
/// Faithful port of the PROJ `laea` implementation (Snyder's ellipsoidal
/// equal-area formulas; see PROJ's `src/projections/laea.cpp` and
/// `src/qsfn.cpp`). Used by the pan-European EPSG:3035 definition and
/// available publicly through
/// ``CustomProjection/lambertAzimuthalEqualArea(datum:helmert:)``.
///
/// The inverse converts the authalic latitude through PROJ 9's auxlat
/// series (C. F. F. Karney, *On auxiliary latitudes*, Survey Review 2024,
/// arXiv:2212.05818; coefficients generated from PROJ's
/// `pj_auxlat_coeffs` for `AUTHALIC` → `GEOGRAPHIC`), evaluated with
/// Clenshaw summation — full double precision for |f| ≤ 1/150, versus the
/// legacy 3-term Snyder series' ~1 mm loss at large distances from the
/// projection origin.
struct LambertAzimuthalEqualAreaMath: Sendable {

    /// The mapping modes of PROJ's laea implementation, keyed by which of
    /// the four domains the projection origin falls into.
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
    private let authalicLatitude: AuthalicLatitude
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
            self.mode = phi0 < 0.0 ? .southPole : .northPole
        }
        else if abs(phi0) < 0.0000000001 {
            self.mode = .equatorial
        }
        else {
            self.mode = .oblique
        }

        self.qPole = Self.qsfn(1.0, e, oneEs)
        self.authalicLatitude = AuthalicLatitude(ellipsoid: ellipsoid)

        switch mode {
        case .northPole, .southPole:
            self.radiusQ = 0.0
            self.sinB1 = 0.0
            self.cosB1 = 0.0
            self.dD = 1.0
            self.xmf = 0.0
            self.ymf = 0.0

        case .equatorial:
            self.radiusQ = sqrt(0.5 * qPole)
            self.sinB1 = 0.0
            self.cosB1 = 0.0
            self.dD = 1.0 / radiusQ
            self.xmf = 1.0
            self.ymf = 0.5 * qPole

        case .oblique:
            self.radiusQ = sqrt(0.5 * qPole)
            self.sinB1 = Self.qsfn(sin(phi0), e, oneEs) / qPole
            self.cosB1 = sqrt(1.0 - sinB1 * sinB1)
            self.dD = cos(phi0) / (sqrt(1.0 - es * sin(phi0) * sin(phi0)) * radiusQ * cosB1)
            self.xmf = radiusQ * dD
            self.ymf = radiusQ / dD
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
            return (Double.nan, Double.nan) // outside the projection domain
        }

        switch mode {
        case .oblique:
            let scaling = sqrt(2.0 / scalingOpt!)
            let x = ellipsoid.semiMajorAxis * scaleFactor * xmf * scaling * cosB * sinLambda
            let y = ellipsoid.semiMajorAxis * scaleFactor * ymf * scaling * (
                cosB1 * sinB - sinB1 * cosB * cosLambda
            )
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
        case .equatorial, .oblique:
            var dx = (x - falseEasting) / (ellipsoid.semiMajorAxis * dD)
            let dy = (y - falseNorthing) * dD / ellipsoid.semiMajorAxis
            let rho = hypot(dx, dy)
            if rho < 0.0000000001 {
                return (latitudeOfOrigin, longitudeOfOrigin)
            }
            guard 0.5 * rho / radiusQ <= 1.0 else {
                return (Double.nan, Double.nan) // outside the projection domain
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
            let phi = authalicLatitude.geographicLatitude(fromAuthalic: asin(authalic))
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
            let phi = authalicLatitude.geographicLatitude(fromAuthalic: asin(authalic))
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

}
