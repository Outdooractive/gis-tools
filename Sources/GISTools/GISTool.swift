#if !os(Linux)
import CoreLocation
#endif

/// Some constants used in this library.
public enum GISTool {

    /// WGS84 equatorial radius as specified by the International Union of Geodesy and Geophysics.
    public static let equatorialRadius: CLLocationDistance = 6_378_137

    /// The radius of the earth, in meters.
    public static let earthRadius: CLLocationDistance = 6_371_008.8

    /// Length of the equator, in meters.
    public static let earthCircumference: CLLocationDistance = 40_075_016.6855785

    /// Mercator projection origin shift.
    public static let originShift = 2.0 * Double.pi * GISTool.equatorialRadius / 2.0 // 20037508.342789244

    /// The accuracy for testing what is equal (μm precision, mainly to counter small rounding errors).
    public static let equalityDelta: Double = 1e-10

    /// The length in pixels of a map tile.
    public static let tileSideLength: Double = 256.0

    /// The default precision for encoding/decoding Polylines.
    public static let defaultPolylinePrecision: Double = 1e5

}
