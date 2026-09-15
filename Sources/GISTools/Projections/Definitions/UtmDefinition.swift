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

    /// The projection of the zone (EPSG:326xx/327xx), carrying this
    /// definition itself.
    var projection: Projection {
        Projection(uncheckedSrid: srid, definition: self)
    }

    private var srid: Int {
        hemisphere == .north ? 32_600 + zone : 32_700 + zone
    }

    /// The UTM zone number, 1–60.
    let zone: Int

    /// The hemisphere the zone covers.
    let hemisphere: UtmHemisphere

    /// Creates a UTM definition from its zone number and hemisphere.
    init(
        zone: Int,
        hemisphere: UtmHemisphere
    ) {
        self.zone = zone
        self.hemisphere = hemisphere
    }

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
    var validExtent: ProjectionExtent? {
        ProjectionExtent(
            minX: 100_000.0,
            minY: 0.0,
            maxX: 900_000.0,
            maxY: 10_000_000.0)
    }

    /// The sector of the zone in its own coordinates (the full extent of
    /// the projection: a UTM zone covers no "world" extent).
    var worldBoundingBox: BoundingBox? {
        guard let extent = validExtent else { return nil }
        return BoundingBox(
            southWest: Coordinate3D(x: extent.minX, y: extent.minY, projection: projection),
            northEast: Coordinate3D(x: extent.maxX, y: extent.maxY, projection: projection))
    }

    /// UTM zone coordinates never wrap.
    var wraparoundExtent: Double? {
        nil
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
        definition(forSrid: projection.srid)
    }

    /// Returns the UTM definition for a canonical SRID.
    ///
    /// - Parameter srid: An EPSG:326xx/327xx SRID
    /// - Returns: The definition for the zone, or `nil` if the SRID is not UTM
    static func definition(forSrid srid: Int) -> UtmDefinition? {
        let isNorthern = srid >= 32_601 && srid <= 32_660
        let isSouthern = srid >= 32_701 && srid <= 32_760
        guard isNorthern || isSouthern else { return nil }

        let hemisphere: UtmHemisphere = isNorthern ? .north : .south
        let zone = isNorthern ? srid - 32_600 : srid - 32_700
        guard zone >= 1, zone <= 60 else { return nil }

        return UtmDefinition(zone: zone, hemisphere: hemisphere)
    }

    // MARK: - Conversions

    // The UTM convention applies the Snyder transverse Mercator formulas on
    // the WGS84 ellipsoid with the 0.9996 scale factor and the per-zone
    // false easting/northing; delegating to the parameterized math keeps
    // the UTM zones and other TM-based CRSs (EPSG:27700 etc.) on the same
    // implementation.

    /// Hoisted batch conversion functions: the TM parameterization is
    /// built once per batch instead of per coordinate.
    var prepared: BatchPreparedTransforms {
        let tm = transverseMercator
        let projection = self.projection

        return BatchPreparedTransforms(
            forward: { coordinate in
                let (easting, northing) = tm.forward(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude)
                return Coordinate3D(
                    x: easting,
                    y: northing,
                    z: coordinate.altitude,
                    m: coordinate.m,
                    projection: projection)
            },
            inverse: { coordinate in
                let (latitude, longitude) = tm.inverse(
                    x: coordinate.longitude,
                    y: coordinate.latitude)
                return Coordinate3D(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: coordinate.altitude,
                    m: coordinate.m)
            })
    }

    /// The Snyder transverse Mercator setup of the zone.
    var transverseMercator: TransverseMercatorMath {
        TransverseMercatorMath(
            ellipsoid: Ellipsoid.wgs84,
            latitudeOfOrigin: 0.0,
            longitudeOfOrigin: centralMeridian * 180.0 / .pi,
            scaleFactor: Self.k0,
            falseEasting: Self.falseEasting,
            falseNorthing: hemisphere.falseNorthing)
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (easting, northing) = transverseMercator.forward(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude)

        return Coordinate3D(
            x: easting,
            y: northing,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: projection)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (latitude, longitude) = transverseMercator.inverse(
            x: coordinate.longitude,
            y: coordinate.latitude)

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
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
    /// non-UTM projections. Both the WGS84 belts (EPSG:326xx/327xx) and
    /// the ETRS89 belt (EPSG:25831–25837) resolve here.
    public var utmZone: Int? {
        UtmDefinition.definition(for: self)?.zone
            ?? Etrs89UtmDefinition.definition(forSrid: srid)?.zone
    }

    /// The UTM hemisphere of the receiver, or `nil` for non-UTM projections.
    public var utmHemisphere: UtmHemisphere? {
        UtmDefinition.definition(for: self)?.hemisphere
            ?? Etrs89UtmDefinition.definition(forSrid: srid).map { _ in .north }
    }


}
