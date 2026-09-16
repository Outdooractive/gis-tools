#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Austrian Gauss-Krüger math: the EPSG:31255–31259 zone belt (MGI /
/// Gauss-Krüger), the classical Austrian military survey grid on the
/// Bessel 1841 ellipsoid.
///
/// Transverse Mercator with k₀ = 1 and a false northing of −5_000_000 m
/// (the y₀ convention that keeps Austrian northings negative until the
/// 5-million offset is added back, historically to keep values positive in
/// the "Feuerstein" tables). The geodetic reference is MGI
/// (``Datum/mgi``), transformed with the published "MGI to WGS 84 (2)"
/// Helmert (stated accuracy approximately 1.5 m).
///
/// Reference zone parameters (EPSG:31255–31259):
/// - EPSG:31255 ("Austria GK Central"): central meridian 13°20'E, x₀ 0,
///   y₀ −5_000_000
/// - EPSG:31256 ("Austria GK East"): central meridian 16°20'E, x₀ 0,
///   y₀ −5_000_000
/// - EPSG:31257 ("Austria GK M28"): central meridian 10°20'E, x₀ 150_000,
///   y₀ −5_000_000
/// - EPSG:31258 ("Austria GK M31"): central meridian 13°20'E, x₀ 450_000,
///   y₀ −5_000_000
/// - EPSG:31259 ("Austria GK M34"): central meridian 16°20'E, x₀ 750_000,
///   y₀ −5_000_000
///
/// - Note: The M-zone numbering counts from the historic Ferro meridian
///   (17°40'W): M28 → 10°20'E Greenwich, M31 → 13°20'E, M34 → 16°20'E.
///
/// - Note: The central meridians are Greenwich-based (13°20' = 13.333…°E,
///   16°20' = 16.333…°E); the historic Ferro offsets are absorbed by the
///   published parameters. EPSG:31255/31256 are the pre-1950s single-zone
///   variants with x₀ = 0 (eastings can be negative); EPSG:31257–31259 are
///   the modern three-zone belt. All five are unbounded extrapolations
///   outside their nominal sectors.
struct MgiGkDefinition: ProjectionDefinition {

    /// **MGI to WGS 84 (2)** (EPSG:1613), position-vector parameters
    /// (stated accuracy approximately 1.5 m).
    private static let helmert = HelmertTransformation(
        datum: .mgi,
        dx: 577.326,
        dy: 90.129,
        dz: 463.919,
        rx: 5.137,
        ry: 1.474,
        rz: 5.297,
        scalePpm: 2.4232)

    /// The EPSG SRID of the zone (31255–31259).
    let srid: Int

    /// The longitude of the zone's central meridian, in degrees.
    let centralMeridian: Double

    /// The false easting applied to x values, in meters.
    let falseEasting: Double

    private static let falseNorthing: Double = -5_000_000.0

    init(srid: Int) {
        precondition((31255 ... 31259).contains(srid), "MGI Gauss-Krueger SRIDs are EPSG:31255-31259")

        switch srid {
        case 31255:
            self.srid = srid
            self.centralMeridian = 13 + 20.0 / 60.0
            self.falseEasting = 0.0

        case 31256:
            self.srid = srid
            self.centralMeridian = 16 + 20.0 / 60.0
            self.falseEasting = 0.0

        case 31257:
            self.srid = srid
            self.centralMeridian = 10 + 20.0 / 60.0
            self.falseEasting = 150_000.0

        case 31258:
            self.srid = srid
            self.centralMeridian = 13 + 20.0 / 60.0
            self.falseEasting = 450_000.0

        default:
            self.srid = 31259
            self.centralMeridian = 16 + 20.0 / 60.0
            self.falseEasting = 750_000.0
        }
    }

    init(srid: Int, centralMeridian: Double, falseEasting: Double) {
        precondition((31255 ... 31259).contains(srid), "MGI Gauss-Krueger SRIDs are EPSG:31255-31259")
        self.srid = srid
        self.centralMeridian = centralMeridian
        self.falseEasting = falseEasting
    }

    var projection: Projection {
        Projection(uncheckedSrid: srid, definition: self)
    }

    var kind: ProjectionKind {
        .planar
    }

    var datum: Datum {
        .mgi
    }

    /// Unbounded: the western variants (x₀ = 0) carry negative eastings
    /// inside their nominal sectors, and coordinates outside the Austrian
    /// sector are valid extrapolations.
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
            ["PROJCS", "MGI / Gauss-Kruger"],
            ["PROJCS", "MGI / Gauss-Krueger"],
            ["PROJCS", "Militar_Geographische_Institut"],
            ["PROJCS", "Austria_Gauss_Kruger"],
        ]
    }

    /// The Karney transverse Mercator setup of the zone.
    var karneyTransverseMercator: KarneyTransverseMercatorMath {
        KarneyTransverseMercatorMath(
            ellipsoid: .bessel1841,
            longitudeOfOrigin: centralMeridian,
            scaleFactor: 1.0,
            falseEasting: falseEasting,
            falseNorthing: Self.falseNorthing)
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
                let mgi = Self.helmert.transform(
                    wgs84ToDatum: coordinate,
                    step: steps.wgs84ToDatum)
                let (easting, northing) = tm.forward(
                    latitude: mgi.latitude,
                    longitude: mgi.longitude)
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
        let mgi = Self.helmert.transform(wgs84ToDatum: coordinate)
        let (easting, northing) = karneyTransverseMercator.forward(
            latitude: mgi.latitude,
            longitude: mgi.longitude)

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

    /// Returns the MGI Gauss-Krüger definition for a projection, if the
    /// projection is an MGI zone SRID.
    ///
    /// - Parameter projection: The projection to look up
    /// - Returns: The definition for the zone, or `nil` if the projection is
    ///   not an MGI Gauss-Krüger zone
    static func definition(for projection: Projection) -> MgiGkDefinition? {
        definition(forSrid: projection.srid)
    }

    /// Returns the MGI Gauss-Krüger definition for a canonical SRID
    /// (EPSG:31255–31259).
    static func definition(forSrid srid: Int) -> MgiGkDefinition? {
        guard (31255 ... 31259).contains(srid) else { return nil }

        return MgiGkDefinition(srid: srid)
    }

}
