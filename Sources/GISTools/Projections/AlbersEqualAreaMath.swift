#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Albers equal-area (`aea`) math, parameterized by ellipsoid and
/// projection origin/standard parallels.
///
/// Faithful port of the Snyder formulas (*Map Projections: A Working
/// Manual*, USGS PP 1395, formulas 14-1 through 14-14) in the shape of
/// PROJ's `aea` implementation (`src/projections/aea.cpp`). The inverse
/// converts the authalic latitude through the shared Karney auxlat series
/// (``AuthalicLatitude``), matching PROJ 9.8 to nanometers.
///
/// Used by the CONUS-wide EPSG:5070 and British Columbia's EPSG:3005
/// definitions, and available publicly through
/// ``CustomProjection/albersEqualArea(datum:helmert:)``.
struct AlbersEqualAreaMath: Sendable {

    /// The ellipsoid the projection is computed on.
    let ellipsoid: Ellipsoid

    /// The latitude of the projection's origin, in degrees.
    let latitudeOfOrigin: Double

    /// The longitude of the projection's origin, in degrees.
    let longitudeOfOrigin: Double

    /// The first standard parallel, in degrees.
    let latitudeOfFirstParallel: Double

    /// The second standard parallel, in degrees.
    let latitudeOfSecondParallel: Double

    /// The false easting applied to x values, in meters.
    let falseEasting: Double

    /// The false northing applied to y values, in meters.
    let falseNorthing: Double

    // MARK: - Hoisted setup data

    /// Snyder 14-3: the cone constant.
    private let n: Double

    /// Snyder 14-2: C = m₁² + n·q(φ₁).
    private let c: Double

    /// Snyder 14-1: the radius from the projection origin's pole.
    private let rho0: Double

    private let authalicLatitude: AuthalicLatitude
    private let eccentricity: Double

    init(
        ellipsoid: Ellipsoid,
        latitudeOfOrigin: Double,
        longitudeOfOrigin: Double,
        latitudeOfFirstParallel: Double,
        latitudeOfSecondParallel: Double,
        falseEasting: Double = 0.0,
        falseNorthing: Double = 0.0
    ) {
        self.ellipsoid = ellipsoid
        self.latitudeOfOrigin = latitudeOfOrigin
        self.longitudeOfOrigin = longitudeOfOrigin
        self.latitudeOfFirstParallel = latitudeOfFirstParallel
        self.latitudeOfSecondParallel = latitudeOfSecondParallel
        self.falseEasting = falseEasting
        self.falseNorthing = falseNorthing

        let es = ellipsoid.eccentricitySquared
        self.eccentricity = sqrt(es)
        self.authalicLatitude = AuthalicLatitude(ellipsoid: ellipsoid)

        let phi0 = latitudeOfOrigin.degreesToRadians
        let phi1 = latitudeOfFirstParallel.degreesToRadians
        let phi2 = latitudeOfSecondParallel.degreesToRadians

        let m1 = Self.m(phi1, es: es)
        let m2 = Self.m(phi2, es: es)
        let q1 = Self.q(phi1, eccentricity: eccentricity)
        let q2 = Self.q(phi2, eccentricity: eccentricity)

        // Snyder 14-3 (secant cone) / 14-4a (single parallel): n = sin(φ₁).
        if abs(phi1 - phi2) > 0.0000000001 {
            self.n = (m1 * m1 - m2 * m2) / (q2 - q1)
        }
        else {
            self.n = sin(phi1)
        }

        // Snyder 14-2.
        self.c = m1 * m1 + n * q1

        // Snyder 14-1.
        self.rho0 = ellipsoid.semiMajorAxis * sqrt(c - n * Self.q(phi0, eccentricity: eccentricity)) / n
    }

    // MARK: - Forward

    /// Snyder formulas 14-4/14-5/14-6: geodetic degrees into grid
    /// coordinates in meters.
    ///
    /// - Parameters:
    ///   - latitude: The geodetic latitude, in degrees
    ///   - longitude: The geodetic longitude, in degrees
    /// - Returns: The grid easting and northing, in meters (NaN outside
    ///   the projection's domain)
    func forward(
        latitude: Double,
        longitude: Double
    ) -> (x: Double, y: Double) {
        let phi = latitude.degreesToRadians
        // The longitude difference normalized into [-180°, 180°).
        let lambda = (longitude - longitudeOfOrigin).degreesToRadians

        let q = Self.q(phi, eccentricity: eccentricity)
        let inner = c - n * q
        guard inner >= 0.0 else {
            return (Double.nan, Double.nan) // outside the projection domain
        }

        let rho = ellipsoid.semiMajorAxis * sqrt(inner) / n

        let theta = n * lambda
        let x = falseEasting + rho * sin(theta)
        let y = falseNorthing + rho0 - rho * cos(theta)
        return (x, y)
    }

    // MARK: - Inverse

    /// Snyder formulas 14-11 through 14-14: grid coordinates in meters
    /// into geodetic degrees. The authalic latitude is converted through
    /// the Karney auxlat series (matching PROJ 9.8).
    ///
    /// - Parameters:
    ///   - x: The grid easting, in meters
    ///   - y: The grid northing, in meters
    /// - Returns: The geodetic latitude and longitude, in degrees
    func inverse(
        x: Double,
        y: Double
    ) -> (latitude: Double, longitude: Double) {
        let dx = x - falseEasting
        // Snyder 14-11: dy = rho0 - (y - y0).
        let dy = rho0 - (y - falseNorthing)

        let rho = hypot(dx, dy)
        let theta = atan2(dx, dy)
        let lambda = theta / n

        // Snyder 14-13: q = (C - (n·rho/a)²) / n.
        let rhoPrime = n * rho / ellipsoid.semiMajorAxis
        let q = (c - rhoPrime * rhoPrime) / n

        // The authalic latitude xi = asin(q / qPole); the geographic
        // latitude through the auxlat series.
        let qPole = Self.q(.pi / 2.0, eccentricity: eccentricity)
        let ratio = q / qPole
        let clamped = min(1.0, max(-1.0, ratio))
        let xi = asin(clamped)
        let phi = authalicLatitude.geographicLatitude(fromAuthalic: xi)

        return (
            phi.radiansToDegrees,
            longitudeOfOrigin + lambda.radiansToDegrees
        )
    }

    // MARK: - Snyder helpers

    /// Snyder 14-12/3-21 (PROJ's `pj_msfn`): the isometric footprint m.
    private static func m(_ phi: Double, es: Double) -> Double {
        cos(phi) / sqrt(1.0 - es * sin(phi) * sin(phi))
    }

    /// Snyder 3-12 (PROJ's `pj_authalic_lat_q`, the `atanh` form).
    private static func q(_ phi: Double, eccentricity e: Double) -> Double {
        let oneEs = 1.0 - e * e
        let sinPhi = sin(phi)
        return oneEs * (sinPhi / (1.0 - e * e * sinPhi * sinPhi) + atanh(e * sinPhi) / e)
    }

}
