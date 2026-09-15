
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
