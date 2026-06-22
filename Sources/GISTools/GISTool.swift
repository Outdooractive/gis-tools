#if canImport(CoreLocation)
import CoreLocation
#endif

/// Some constants used in this library.
public enum GISTool {

    /// The default precision for encoding/decoding Polylines.
    /// The value is the multiplier applied to EPSG:4326 degree values to produce integers:
    /// `100_000` gives ~1.1 m resolution at the equator (0.00001°).
    public static let defaultPolylinePrecision: Double = 100_000.0

    /// Length of the equator, in meters.
    public static let earthCircumference: CLLocationDistance = 40_075_016.6855785

    /// The radius of the earth, in meters.
    public static let earthRadius: CLLocationDistance = 6_371_008.8

    /// WGS84 equatorial radius as specified by the International Union of Geodesy and Geophysics.
    public static let equatorialRadius: CLLocationDistance = 6_378_137

    /// The accuracy for testing what is equal (~0.011mm at the equator for EPSG:4326,
    /// 0.1nm for EPSG:3857, mainly to counter small rounding errors).
    public static let equalityDelta: CLLocationDistance = 0.0000000001

    /// Epsilon for line intersection, collinearity and triangulation stability checks.
    public static let intersectionEpsilon: CLLocationDistance = 0.000000000001

    /// Epsilon for determinant / matrix stability checks (planepoint, Voronoi, circumcircle).
    public static let determinantEpsilon: CLLocationDistance = 0.000000000000001

    /// Mercator projection origin shift.
    public static let originShift = 2.0 * Double.pi * GISTool.equatorialRadius / 2.0 // 20037508.342789244

    /// The length in pixels of a map tile.
    public static let tileSideLength: Double = 256.0

    /// WGS84 first eccentricity squared (e²).
    public static let wgs84EccentricitySquared: Double = 2.0 * wgs84Flattening - wgs84Flattening * wgs84Flattening

    /// WGS84 inverse flattening (1/f).
    public static let wgs84Flattening: Double = 1.0 / 298.257223563

    /// WGS84 semi-minor axis in meters.
    public static let wgs84SemiMinorAxis: CLLocationDistance = equatorialRadius * (1.0 - wgs84Flattening)

}
