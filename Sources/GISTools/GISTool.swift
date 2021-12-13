#if !os(Linux)
import CoreLocation
#endif

// MARK: GISTool

/// Some constants used in this library.
public enum GISTool {

    /// WGS84 equatorial radius as specified by the International Union of Geodesy and Geophysics.
    public static let equatorialRadius: CLLocationDistance = 6_378_137

    /// The radius of the earth, in meters.
    public static let earthRadius: CLLocationDistance = 6_371_008.8

    /// Length of the equator, in meters.
    public static let earthCircumference: CLLocationDistance = 40_075_016.6855785

    /// The accuracy for testing what is equal
    public static let equalityDelta: Double = 1e-10

}
