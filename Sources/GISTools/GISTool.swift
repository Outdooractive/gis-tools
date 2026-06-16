#if canImport(CoreLocation)
import CoreLocation
#endif

/// Some constants used in this library.
public enum GISTool {

    /// The default precision for encoding/decoding Polylines.
    public static let defaultPolylinePrecision: Double = 1e5

    /// Length of the equator, in meters.
    public static let earthCircumference: CLLocationDistance = 40_075_016.6855785

    /// The radius of the earth, in meters.
    public static let earthRadius: CLLocationDistance = 6_371_008.8

    /// WGS84 equatorial radius as specified by the International Union of Geodesy and Geophysics.
    public static let equatorialRadius: CLLocationDistance = 6_378_137

    /// The accuracy for testing what is equal (μm precision, mainly to counter small rounding errors).
    public static let equalityDelta: Double = 1e-10

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
