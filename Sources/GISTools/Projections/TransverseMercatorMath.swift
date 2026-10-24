#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Internal transverse Mercator math, parameterized by ellipsoid and
/// projection origin (Snyder formulas, *Map Projections - A Working
/// Manual*, USGS PP 1395).
///
/// Used by `UtmDefinition` (EPSG:32xxx, origin at the equator) and by the
/// datument-capable built-in projected CRSs (EPSG:27700 etc.), and exposed
/// publicly through ``CustomProjection/transverseMercator(datum:helmert:)``.
struct TransverseMercatorMath: Sendable {

    /// The ellipsoid the projection is computed on.
    let ellipsoid: Ellipsoid

    /// The latitude of the projection's origin, in degrees.
    let latitudeOfOrigin: Double

    /// The longitude of the projection's central meridian, in degrees.
    let longitudeOfOrigin: Double

    /// The central scale factor (e.g. 0.9996 for the UTM convention).
    let scaleFactor: Double

    /// The false easting applied to x values, in meters.
    let falseEasting: Double

    /// The false northing applied to y values.
    let falseNorthing: Double

    init(
        ellipsoid: Ellipsoid,
        latitudeOfOrigin: Double = 0.0,
        longitudeOfOrigin: Double,
        scaleFactor: Double,
        falseEasting: Double,
        falseNorthing: Double = 0.0
    ) {
        self.ellipsoid = ellipsoid
        self.latitudeOfOrigin = latitudeOfOrigin
        self.longitudeOfOrigin = longitudeOfOrigin
        self.scaleFactor = scaleFactor
        self.falseEasting = falseEasting
        self.falseNorthing = falseNorthing
    }

    // MARK: - Forward

    /// Snyder forward formulas (equations 8-9..8-25): geodetic degrees into
    /// grid coordinates in meters.
    func forward(
        latitude: Double,
        longitude: Double
    ) -> (x: Double, y: Double) {
        let a = ellipsoid.semiMajorAxis
        let e2 = ellipsoid.eccentricitySquared
        let e1sq = e2 / (1.0 - e2)

        let phi = latitude.degreesToRadians
        let deltaLambda = longitude.degreesToRadians - longitudeOfOrigin.degreesToRadians

        let sinPhi = sin(phi)
        let cosPhi = cos(phi)
        let tanPhi = tan(phi)

        let radiusSquared = 1.0 - e2 * sinPhi * sinPhi
        let nRadius = a / sqrt(radiusSquared)
        let tRadius = tanPhi * tanPhi
        let cTerm = e1sq * cosPhi * cosPhi
        let aTerm = deltaLambda * cosPhi

        let meridianArc = Self.meridianArc(phi, ellipsoid: ellipsoid)

        let easting = falseEasting
            + scaleFactor * nRadius * (
                aTerm
                    + (1.0 - tRadius + cTerm) * pow(aTerm, 3) / 6.0
                    + (5.0 - 18.0 * tRadius + tRadius * tRadius + 72.0 * cTerm - 58.0 * e1sq) * pow(aTerm, 5) / 120.0
            )

        let northing = falseNorthing + scaleFactor * (
            meridianArc - Self.meridianArc(latitudeOfOrigin.degreesToRadians, ellipsoid: ellipsoid)
                + nRadius * tanPhi * (
                    aTerm * aTerm / 2.0
                        + (5.0 - tRadius + 9.0 * cTerm + 4.0 * cTerm * cTerm) * pow(aTerm, 4) / 24.0
                        + (61.0 - 58.0 * tRadius + tRadius * tRadius + 600.0 * cTerm - 330.0 * e1sq) * pow(aTerm, 6) / 720.0
                )
        )

        return (easting, northing)
    }

    // MARK: - Inverse

    /// Snyder inverse formulas: grid coordinates in meters into geodetic
    /// degrees.
    func inverse(
        x: Double,
        y: Double
    ) -> (latitude: Double, longitude: Double) {
        let a = ellipsoid.semiMajorAxis
        let e2 = ellipsoid.eccentricitySquared
        let e1sq = e2 / (1.0 - e2)

        let x = x - falseEasting
        let y = y - falseNorthing

        let meridianArc = y / scaleFactor
            + Self.meridianArc(latitudeOfOrigin.degreesToRadians, ellipsoid: ellipsoid)
        let mu = meridianArc / (a * (1.0 - e2 / 4.0 - 3.0 * e2 * e2 / 64.0 - 5.0 * pow(e2, 3) / 256.0))

        let e1 = (1.0 - sqrt(1.0 - e2)) / (1.0 + sqrt(1.0 - e2))

        let phi1 = mu
            + (3.0 * e1 / 2.0 - 27.0 * pow(e1, 3) / 32.0) * sin(2.0 * mu)
            + (21.0 * e1 * e1 / 16.0 - 55.0 * pow(e1, 4) / 32.0) * sin(4.0 * mu)
            + (151.0 * pow(e1, 3) / 96.0) * sin(6.0 * mu)
            + (1097.0 * pow(e1, 4) / 512.0) * sin(8.0 * mu)

        let radiusSquared1 = 1.0 - e2 * sin(phi1) * sin(phi1)
        let nRadius1 = a / sqrt(radiusSquared1)
        let tRadius1 = tan(phi1) * tan(phi1)
        let cTerm1 = e1sq * cos(phi1) * cos(phi1)
        let meridianRadius1 = a * (1.0 - e2) / pow(radiusSquared1, 1.5)
        let dTerm = x / (nRadius1 * scaleFactor)

        let latitude = phi1
            - (nRadius1 * tan(phi1) / meridianRadius1) * (
                dTerm * dTerm / 2.0
                    - (5.0 + 3.0 * tRadius1 + 10.0 * cTerm1 - 4.0 * cTerm1 * cTerm1 - 9.0 * e1sq) * pow(dTerm, 4) / 24.0
                    + (61.0 + 90.0 * tRadius1 + 298.0 * cTerm1 + 45.0 * tRadius1 * tRadius1 - 252.0 * e1sq - 3.0 * cTerm1 * cTerm1) * pow(dTerm, 6) / 720.0
            )

        let lambdaTerm = (dTerm
            - (1.0 + 2.0 * tRadius1 + cTerm1) * pow(dTerm, 3) / 6.0
            + (5.0 - 2.0 * cTerm1 + 28.0 * tRadius1 - 3.0 * cTerm1 * cTerm1 + 8.0 * e1sq + 24.0 * tRadius1 * tRadius1) * pow(dTerm, 5) / 120.0)
            / cos(phi1)
        let longitude = longitudeOfOrigin.degreesToRadians + lambdaTerm

        return (latitude * 180.0 / .pi, longitude * 180.0 / .pi)
    }

    // MARK: - Meridian arc

    /// Meridian arc length from the equator to `phi` (radians), in meters.
    ///
    /// Uses the third-flattening series (`n = f / (2 - f)`) through `n⁶`,
    /// which matches the exact elliptic integral to a few nanometres over
    /// the whole ellipsoid. The older Snyder `e²` expansion truncated at
    /// `e⁶` is accurate only to about a millimetre near the poles, which is
    /// visible when EPSG:32662's meridian-arc axis is converted to another
    /// projection.
    static func meridianArc(
        _ phi: Double,
        ellipsoid: Ellipsoid
    ) -> Double {
        let a = ellipsoid.semiMajorAxis
        let f = 1.0 / ellipsoid.inverseFlattening
        let n = f / (2.0 - f)
        let n2 = n * n
        let n3 = n2 * n
        let n4 = n2 * n2
        let n5 = n4 * n
        let n6 = n3 * n3

        return a / (1.0 + n) * (
            (1.0 + n2 / 4.0 + n4 / 64.0 + n6 / 256.0) * phi
                - (3.0 / 2.0) * (n - n3 / 8.0 + n5 / 64.0) * sin(2.0 * phi)
                + (15.0 / 16.0) * (n2 - n4 / 4.0 + 3.0 * n6 / 64.0) * sin(4.0 * phi)
                - (35.0 / 48.0) * (n3 - 5.0 * n5 / 16.0) * sin(6.0 * phi)
                + (315.0 / 512.0) * (n4 - 7.0 * n6 / 16.0) * sin(8.0 * phi)
                - (693.0 / 1280.0) * n5 * sin(10.0 * phi)
                + (1001.0 / 2048.0) * n6 * sin(12.0 * phi)
        )
    }

    /// The geodetic latitude (radians) whose meridian arc length from the
    /// equator equals `meridianArc`, inverting ``meridianArc(_:ellipsoid:)``
    /// with a footpoint series and two Newton refinements.
    ///
    /// The refinement keeps the inversion accurate to well below a
    /// nanometre, so projections such as EPSG:32662 that use the meridian
    /// arc for one axis round-trip without losing precision.
    static func latitude(
        forMeridianArc meridianArc: Double,
        ellipsoid: Ellipsoid
    ) -> Double {
        let a = ellipsoid.semiMajorAxis
        let e2 = ellipsoid.eccentricitySquared
        let f = 1.0 / ellipsoid.inverseFlattening
        let n = f / (2.0 - f)
        let n2 = n * n
        let n3 = n2 * n
        let n4 = n2 * n2

        let mu = meridianArc
            / (a / (1.0 + n) * (1.0 + n2 / 4.0 + n4 / 64.0 + pow(n, 6) / 256.0))

        var phi = mu
            + (3.0 * n / 2.0 - 27.0 * n3 / 32.0) * sin(2.0 * mu)
            + (21.0 * n2 / 16.0 - 55.0 * n4 / 32.0) * sin(4.0 * mu)
            + (151.0 * n3 / 96.0 - 417.0 * pow(n, 5) / 128.0) * sin(6.0 * mu)
            + (1097.0 * n4 / 512.0) * sin(8.0 * mu)

        for _ in 0 ..< 2 {
            let sinPhi = sin(phi)
            let radiusSquared = 1.0 - e2 * sinPhi * sinPhi
            let meridionalRadius = a * (1.0 - e2) / pow(radiusSquared, 1.5)
            phi -= (Self.meridianArc(phi, ellipsoid: ellipsoid) - meridianArc) / meridionalRadius
        }

        return phi
    }

}
