import Foundation

/// The hemisphere of a UTM zone.
public enum UtmHemisphere: Sendable {

    /// Northern zone (EPSG:32601–32660, false northing 0).
    case north

    /// Southern zone (EPSG:32701–32760, false northing 10_000_000 m).
    case south

    /// The false northing applied to y values of the zone.
    var falseNorthing: Double {
        switch self {
        case .north: 0.0
        case .south: 10_000_000.0
        }
    }

}

/// Transverse Mercator math for a single UTM zone.
///
/// Uses the standard Snyder transverse Mercator formulas (*Map Projections -
/// A Working Manual*, USGS PP 1395) on the WGS84 ellipsoid with the UTM
/// central scale factor of 0.9996. Coordinates are easting/northing in
/// meters with a false easting of 500_000 m and a false northing of
/// 0 m (northern zones) or 10_000_000 m (southern zones).
///
/// The formulas lose accuracy farther than about ±3–4° from the zone's
/// central meridian, which is inherent to the transverse Mercator series
/// and matches the use expected of UTM coordinates.
struct UtmDefinition: ProjectionDefinition {

    /// The projection case of the zone (EPSG:326xx/327xx).
    let projection: Projection

    /// The UTM zone number, 1–60.
    let zone: Int

    /// The hemisphere the zone covers.
    let hemisphere: UtmHemisphere

    /// The UTM central scale factor.
    private static let k0 = 0.9996

    /// The false easting applied to x values of every zone.
    private static let falseEasting = 500_000.0

    /// The longitude of the zone's central meridian, in radians.
    var centralMeridian: Double {
        Double((zone - 1) * 6 - 180 + 3) * .pi / 180.0
    }

    var kind: ProjectionKind { .planar }

    /// The EPSG-defined sector extent of the zone.
    var validExtent: (minX: Double, minY: Double, maxX: Double, maxY: Double)? {
        (
            minX: 100_000.0,
            minY: 0.0,
            maxX: 900_000.0,
            maxY: 10_000_000.0
        )
    }

    /// The sector of the zone in its own coordinates (the full extent of
    /// the projection: a UTM zone covers no "world" extent).
    var worldBoundingBox: BoundingBox? {
        guard let extent = validExtent else { return nil }
        return BoundingBox(
            southWest: Coordinate3D(x: extent.minX, y: extent.minY, projection: projection),
            northEast: Coordinate3D(x: extent.maxX, y: extent.maxY, projection: projection))
    }

    /// UTM zones have no unique WKT fragment.
    var wktMatchers: [[String]] {
        []
    }

    // MARK: - Lookup

    /// Returns the UTM definition for a projection, if the projection is a
    /// UTM zone SRID.
    ///
    /// - Parameter projection: The projection to look up
    /// - Returns: The definition for the zone, or `nil` if the projection is not UTM
    static func definition(for projection: Projection) -> UtmDefinition? {
        let srid = projection.rawValue

        let isNorthern = srid >= 32_601 && srid <= 32_660
        let isSouthern = srid >= 32_701 && srid <= 32_760
        guard isNorthern || isSouthern else { return nil }

        let hemisphere: UtmHemisphere = isNorthern ? .north : .south
        let zone = isNorthern ? srid - 32_600 : srid - 32_700
        guard zone >= 1, zone <= 60 else { return nil }

        return UtmDefinition(projection: projection, zone: zone, hemisphere: hemisphere)
    }

    // MARK: - Conversions

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let a = GISTool.equatorialRadius
        let e2 = GISTool.wgs84EccentricitySquared
        let e1sq = e2 / (1.0 - e2)

        let phi = coordinate.latitude.degreesToRadians
        let deltaLambda = (coordinate.longitude.degreesToRadians) - centralMeridian

        let sinPhi = sin(phi)
        let cosPhi = cos(phi)
        let tanPhi = tan(phi)

        let radiusSquared = 1.0 - e2 * sinPhi * sinPhi
        let nRadius = a / sqrt(radiusSquared)
        let tRadius = tanPhi * tanPhi
        let cTerm = e1sq * cosPhi * cosPhi
        let aTerm = deltaLambda * cosPhi

        let meridianArc = Self.meridianArc(phi)

        let easting = Self.falseEasting
            + Self.k0 * nRadius * (
                aTerm
                    + (1.0 - tRadius + cTerm) * pow(aTerm, 3) / 6.0
                    + (5.0 - 18.0 * tRadius + tRadius * tRadius + 72.0 * cTerm - 58.0 * e1sq) * pow(aTerm, 5) / 120.0
            )

        let northing = Self.k0 * (
            meridianArc
                + nRadius * tanPhi * (
                    aTerm * aTerm / 2.0
                        + (5.0 - tRadius + 9.0 * cTerm + 4.0 * cTerm * cTerm) * pow(aTerm, 4) / 24.0
                        + (61.0 - 58.0 * tRadius + tRadius * tRadius + 600.0 * cTerm - 330.0 * e1sq) * pow(aTerm, 6) / 720.0
                )
        ) + hemisphere.falseNorthing

        return Coordinate3D(
            x: easting,
            y: northing,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: projection)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let a = GISTool.equatorialRadius
        let e2 = GISTool.wgs84EccentricitySquared
        let e1sq = e2 / (1.0 - e2)

        let x = coordinate.longitude - Self.falseEasting
        let y = coordinate.latitude - hemisphere.falseNorthing

        let meridianArc = y / Self.k0
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
        let dTerm = x / (nRadius1 * Self.k0)

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
        let longitude = centralMeridian + lambdaTerm

        return Coordinate3D(
            latitude: latitude * 180.0 / .pi,
            longitude: longitude * 180.0 / .pi,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

    // MARK: - Snippet helpers

    /// Snyder meridian arc length (formulas 3-21) from the equator to `phi`,
    /// in meters.
    private static func meridianArc(_ phi: Double) -> Double {
        let a = GISTool.equatorialRadius
        let e2 = GISTool.wgs84EccentricitySquared

        return a * (
            (1.0 - e2 / 4.0 - 3.0 * e2 * e2 / 64.0 - 5.0 * pow(e2, 3) / 256.0) * phi
                - (3.0 * e2 / 8.0 + 3.0 * e2 * e2 / 32.0 + 45.0 * pow(e2, 3) / 1024.0) * sin(2.0 * phi)
                + (15.0 * e2 * e2 / 256.0 + 45.0 * pow(e2, 3) / 1024.0) * sin(4.0 * phi)
                - (35.0 * pow(e2, 3) / 3072.0) * sin(6.0 * phi)
        )
    }

}

// MARK: - Projection

extension Projection {

    /// The UTM zone number (1–60) of the receiver, or `nil` for
    /// non-UTM projections.
    public var utmZone: Int? {
        UtmDefinition.definition(for: self)?.zone
    }

    /// The UTM hemisphere of the receiver, or `nil` for non-UTM projections.
    public var utmHemisphere: UtmHemisphere? {
        UtmDefinition.definition(for: self)?.hemisphere
    }

    /// Creates a UTM zone projection from its zone number and hemisphere.
    ///
    /// - Parameters:
    ///     - utmZone: The UTM zone number (`1 ... 60`)
    ///     - hemisphere: The hemisphere the zone covers
    /// - Returns: The zone projection, or `nil` for an invalid zone number
    public init?(utmZone: Int, hemisphere: UtmHemisphere) {
        guard utmZone >= 1, utmZone <= 60 else { return nil }

        let srid = hemisphere == .north ? 32_600 + utmZone : 32_700 + utmZone
        guard let projection = Projection(srid: srid) else { return nil }
        self = projection
    }

}
