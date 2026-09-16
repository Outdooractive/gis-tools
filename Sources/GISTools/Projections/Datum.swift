
/// The ellipsoid of a geodetic datum.
///
/// Reference values follow the EPSG registry (see EPSG guidance note 7-2).
public struct Ellipsoid:
    Hashable,
    Sendable,
    CustomStringConvertible
{

    /// Semi-major axis, in meters.
    public let semiMajorAxis: Double

    /// The inverse of the flattening (a / (a - b)).
    public let inverseFlattening: Double

    public init(
        semiMajorAxis: Double,
        inverseFlattening: Double
    ) {
        self.semiMajorAxis = semiMajorAxis
        self.inverseFlattening = inverseFlattening
    }

    // MARK: - Well-known ellipsoids

    /// WGS84 (EPSG:7030).
    public static let wgs84 = Ellipsoid(
        semiMajorAxis: 6_378_137.0,
        inverseFlattening: 298.257223563)

    /// GRS80 (EPSG:7019), the ETRS89 ellipsoid.
    public static let grs80 = Ellipsoid(
        semiMajorAxis: 6_378_137.0,
        inverseFlattening: 298.257222101)

    /// Clarke 1866 (EPSG:7008), the NAD27 ellipsoid.
    public static let clarke1866 = Ellipsoid(
        semiMajorAxis: 6_378_206.4,
        inverseFlattening: 294.978698213898)

    /// Airy 1830 (EPSG:7001), the OSGB 1936 ellipsoid.
    public static let airy1830 = Ellipsoid(
        semiMajorAxis: 6_377_563.396,
        inverseFlattening: 299.3249646)

    /// Modified Airy (EPSG:7050), the TM65/TM75 ellipsoid used for the
    /// Irish Grids (Airy 1830 modified per the 1877 Tenerife measurement).
    public static let modifiedAiry = Ellipsoid(
        semiMajorAxis: 6_377_340.189,
        inverseFlattening: 299.3249646)

    /// Bessel 1841 (EPSG:7004), the Swiss CH1903/CH1903+ ellipsoid.
    public static let bessel1841 = Ellipsoid(
        semiMajorAxis: 6_377_397.155,
        inverseFlattening: 299.1528128)

    /// A textual description of the receiver.
    public var description: String {
        "Ellipsoid(a: \(semiMajorAxis), 1/f: \(inverseFlattening))"
    }

    // MARK: - Derived values

    /// First eccentricity squared, e².
    public var eccentricitySquared: Double {
        let f = 1.0 / inverseFlattening
        return 2.0 * f - f * f
    }

    /// Semi-minor axis, in meters.
    public var semiMinorAxis: Double {
        semiMajorAxis * (1.0 - 1.0 / inverseFlattening)
    }

}

/// A geodetic datum, combining an ellipsoid with its realization.
public struct Datum:
    Hashable,
    Sendable,
    CustomStringConvertible
{

    /// The foundation all library projections are based on (GPS etc.).
    public static let wgs84 = Datum(
        name: "WGS 84",
        realization: "World Geodetic System 1984",
        ellipsoid: .wgs84)

    /// European Terrestrial Reference System 1989. Computed positions
    /// effectively coincide with WGS84 at meter accuracy (centimeter-level
    /// drift is not represented).
    public static let etrs89 = Datum(
        name: "ETRS89",
        realization: "European Terrestrial Reference System 1989",
        ellipsoid: .grs80)

    /// The classical North American datum (Clarke 1866), defined through
    /// triangulation.
    public static let nad27 = Datum(
        name: "NAD 1927",
        realization: "North American Datum of 1927",
        ellipsoid: .clarke1866)

    /// Ordnance Survey of Great Britain 1936 (Airy 1830).
    public static let osgb1936 = Datum(
        name: "OSGB 1936",
        realization: "Ordnance Survey Great Britain 1936 triangulation",
        ellipsoid: .airy1830)

    /// Swiss CH1903+, the modern Swiss datum (LV95). Nearly identical to
    /// ETRS89 (-WGS84 effect at meter accuracy); the classical CH1903 and
    /// CH1903+ shared Helmert parameters coincide at meter accuracy.
    public static let ch1903plus = Datum(
        name: "CH1903+",
        realization: "Swiss terrestrial reference frame (CHENyx06-based realization)",
        ellipsoid: .bessel1841)

    /// Swiss CH1903, the classical Swiss triangulation datum (LV03).
    public static let ch1903 = Datum(
        name: "CH1903",
        realization: "CH1903 classical Swiss triangulation",
        ellipsoid: .bessel1841)

    /// Irish TM65 datum, the classical 1965 Irish triangulation
    /// (Irish Grid, modified Airy).
    public static let tm65 = Datum(
        name: "TM65",
        realization: "Ireland 1965 triangulation",
        ellipsoid: .modifiedAiry)

    /// Irish TM75 datum (the 1975 readjustment of the Geodetic Datum of
    /// 1965, modified Airy).
    public static let tm75 = Datum(
        name: "TM75",
        realization: "Ireland 1975 readjustment (Geodetic Datum of 1965)",
        ellipsoid: .modifiedAiry)

    /// IRENET95, the Irish realization of ETRS89 (effectively coincident
    /// with WGS84 at meter accuracy).
    public static let irenet95 = Datum(
        name: "IRENET95",
        realization: "Irish realization of ETRS89",
        ellipsoid: .grs80)

    /// Amersfoort, the Dutch national datum on the Bessel 1841 ellipsoid
    /// (EPSG:4289; used by EPSG:28992, RD New). Transformations use the
    /// published "Amersfoort to WGS 84 (4)" Euler parameters.
    public static let amersfoort = Datum(
        name: "Amersfoort",
        realization: "Dutch national triangulation (1850-1985)",
        ellipsoid: .bessel1841)

    /// Deutsches Hauptdreiecksnetz (DHDN), the classical German triangulation
    /// datum on the Bessel 1841 ellipsoid (EPSG:4314; used by EPSG:31466–31469,
    /// the Gauss-Krüger zones). Transformations use the published
    /// "DHDN to WGS 84 (2)" parameters (stated accuracy approximately 3 m).
    public static let dhdn = Datum(
        name: "DHDN",
        realization: "Deutsches Hauptdreiecksnetz (German principal triangulation network)",
        ellipsoid: .bessel1841)

    /// Militär-Geographisches Institut (MGI), the classical Austrian
    /// triangulation datum on the Bessel 1841 ellipsoid (EPSG:4312; used by
    /// EPSG:31255–31259, the Austrian Gauss-Krüger zones). Transformations
    /// use the published "MGI to WGS 84 (2)" parameters (stated accuracy
    /// approximately 1.5 m).
    public static let mgi = Datum(
        name: "MGI",
        realization: "Militaer-Geographisches Institut (Austrian military-geographic institute triangulation)",
        ellipsoid: .bessel1841)

    /// A human readable datum name.
    public let name: String

    /// The realization the datum is based on.
    public let realization: String

    /// The ellipsoid of the datum.
    public let ellipsoid: Ellipsoid

    public init(
        name: String,
        realization: String,
        ellipsoid: Ellipsoid
    ) {
        self.name = name
        self.realization = realization
        self.ellipsoid = ellipsoid
    }

    /// A textual description of the receiver.
    public var description: String {
        "\(name) (\(realization), \(ellipsoid))"
    }

}
