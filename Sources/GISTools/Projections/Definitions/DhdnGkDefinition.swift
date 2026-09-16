#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// German Gauss-Krüger math: the EPSG:31466–31469 zone belt (DHDN /
/// Gauss-Krüger zones 2–5), the classical German cadastral grid on the
/// Bessel 1841 ellipsoid.
///
/// Transverse Mercator with k₀ = 1, no false easting offset beyond the
/// zone prefix: each zone's x₀ is `zone * 1_000_000 + 500_000` (so eastings
/// identify the zone: zone 3 eastings start with 3_5xx_xxx). The geodetic
/// reference is DHDN (``Datum/dhdn``), transformed with the published
/// "DHDN to WGS 84 (2)" Helmert (stated accuracy approximately 3 m).
///
/// Reference zone parameters (EPSG:31466–31469):
/// central meridians 6°/9°/12°/15°E, scale 1, false northing 0.
///
/// - Note: The zone belt covers Germany east of 3°E; coordinates outside
///   the zone's ±3° band are valid extrapolations, matching the UTM zones'
///   behavior.
struct DhdnGkDefinition: ProjectionDefinition {

    /// **DHDN to WGS 84 (2)** (EPSG:1618), position-vector parameters
    /// (stated accuracy approximately 3 m).
    private static let helmert = HelmertTransformation(
        datum: .dhdn,
        dx: 598.1,
        dy: 73.7,
        dz: 418.2,
        rx: 0.202,
        ry: 0.045,
        rz: -2.455,
        scalePpm: 6.7)

    /// The Gauss-Krüger zone number (2–5).
    let zone: Int

    init(zone: Int) {
        precondition(zone >= 2 && zone <= 5, "DHDN Gauss-Krueger zones are 2 to 5")
        self.zone = zone
    }

    var projection: Projection {
        Projection(uncheckedSrid: 31464 + zone, definition: self)
    }

    /// The longitude of the zone's central meridian, in degrees.
    var centralMeridian: Double {
        Double(zone * 3)
    }

    var kind: ProjectionKind {
        .planar
    }

    var datum: Datum {
        .dhdn
    }

    /// Unbounded: grid coordinates outside the German sector are valid
    /// extrapolations (the zone belt carries no EPSG-defined sector extent
    /// in this library's model).
    var validExtent: ProjectionExtent? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        nil
    }

    var wraparoundExtent: Double? {
        nil
    }

    var wktMatchers: [[String]] {
        [
            ["PROJCS", "DHDN / Gauss-Krueger"],
            ["PROJCS", "DHDN / 3-degree Gauss-Krueger"],
            ["PROJCS", "Deutsches_Hauptdreiecksnetz"],
            ["PROJCS", "Gauss_Kruger_DHDN"],
        ]
    }

    /// The Karney transverse Mercator setup of the zone.
    var karneyTransverseMercator: KarneyTransverseMercatorMath {
        KarneyTransverseMercatorMath(
            ellipsoid: .bessel1841,
            longitudeOfOrigin: centralMeridian,
            scaleFactor: 1.0,
            falseEasting: Double(zone * 1_000_000 + 500_000),
            falseNorthing: 0.0)
    }

    /// Hoisted batch conversion functions: the Helmert rotation matrices
    /// and the TM parameterization are built once per batch instead of
    /// per coordinate. The coordinate chain is Helmert -> TM and
    /// TM -> Helmert in the inverse, with the EPSG:4326 label only used as
    /// a staging representation between the two.
    var prepared: BatchPreparedTransforms {
        let steps = Self.helmert.prepared()
        let tm = karneyTransverseMercator
        let projection = self.projection

        return BatchPreparedTransforms(
            forward: { coordinate in
                let dhdn = Self.helmert.transform(
                    wgs84ToDatum: coordinate,
                    step: steps.wgs84ToDatum)
                let (easting, northing) = tm.forward(
                    latitude: dhdn.latitude,
                    longitude: dhdn.longitude)
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
                return Self.helmert.transform(
                    datumToWgs84: Coordinate3D(
                        latitude: latitude,
                        longitude: longitude,
                        altitude: coordinate.altitude,
                        m: coordinate.m),
                    step: steps.datumToWgs84)
            })
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let dhdn = Self.helmert.transform(wgs84ToDatum: coordinate)
        let (easting, northing) = karneyTransverseMercator.forward(
            latitude: dhdn.latitude,
            longitude: dhdn.longitude)

        return Coordinate3D(
            x: easting,
            y: northing,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: projection)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (latitude, longitude) = karneyTransverseMercator.inverse(
            x: coordinate.longitude,
            y: coordinate.latitude)
        return Self.helmert.transform(
            datumToWgs84: Coordinate3D(
                latitude: latitude,
                longitude: longitude,
                altitude: coordinate.altitude,
                m: coordinate.m))
    }

    /// Returns the DHDN Gauss-Krüger definition for a projection, if the
    /// projection is a DHDN zone SRID.
    ///
    /// - Parameter projection: The projection to look up
    /// - Returns: The definition for the zone, or `nil` if the projection is
    ///   not a DHDN Gauss-Krüger zone
    static func definition(for projection: Projection) -> DhdnGkDefinition? {
        definition(forSrid: projection.srid)
    }

    /// Returns the DHDN Gauss-Krüger definition for a canonical SRID
    /// (EPSG:31466–31469, zones 2–5).
    static func definition(forSrid srid: Int) -> DhdnGkDefinition? {
        guard srid >= 31466, srid <= 31469 else { return nil }

        return DhdnGkDefinition(zone: srid - 31464)
    }

}
