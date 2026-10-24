#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

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

    /// Length of one degree of latitude in meters, using the same spherical
    /// circumference model as ``earthCircumference``.
    ///
    /// This is the canonical value for the meter/degree conversion helpers:
    /// `earthCircumference / 360 ≈ 111_319.49 m`.
    public static let oneDegreeLatitudeDistance: CLLocationDistance = earthCircumference / 360.0

    /// A deliberately conservative metres-per-degree bound for spatial search
    /// windows.
    ///
    /// This is smaller than ``oneDegreeLatitudeDistance`` so latitude search
    /// boxes cannot under-cover at high latitudes. Do not replace it with the
    /// equatorial constant.
    public static let conservativeMetersPerDegree: CLLocationDistance = 111_000.0

    /// Length of one degree of longitude at `latitude`, in meters.
    ///
    /// Uses the spherical ``oneDegreeLatitudeDistance`` model; longitude
    /// distance shrinks by `cos(latitude)` toward the poles.
    ///
    /// - Parameter latitude: The latitude in degrees.
    /// - Returns: The length of one degree of longitude at that latitude.
    public static func metersPerDegreeLongitude(
        atLatitude latitude: CLLocationDegrees
    ) -> CLLocationDistance {
        cos(latitude * Double.pi / 180.0) * oneDegreeLatitudeDistance
    }

    /// WGS84 equatorial radius as specified by the International Union of Geodesy and Geophysics.
    public static let equatorialRadius: CLLocationDistance = 6_378_137

    /// Meters in one statute mile.
    public static let metersPerMile: CLLocationDistance = 1_609.344

    /// Meters in one international nautical mile.
    public static let metersPerNauticalMile: CLLocationDistance = 1_852.0

    /// Feet in one meter, using the legacy `3.28084` conversion factor.
    public static let feetPerMeter: Double = 3.28084

    /// Inches in one meter, using the legacy `39.370` conversion factor.
    public static let inchesPerMeter: Double = 39.370

    /// Yards in one meter, using the legacy `1.0936` conversion factor.
    public static let yardsPerMeter: Double = 1.0936

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

    // MARK: - Area conversion factors

    /// Acres in one square meter.
    static let acresPerSquareMeter: Double = 0.000247105

    /// Square feet in one square meter.
    static let squareFeetPerSquareMeter: Double = 10.763910417

    /// Square inches in one square meter.
    static let squareInchesPerSquareMeter: Double = 1_550.003100006

    /// Square kilometers in one square meter.
    static let squareKilometersPerSquareMeter: Double = 0.000001

    /// Square miles in one square meter.
    static let squareMilesPerSquareMeter: Double = 0.000000386

    /// Square yards in one square meter.
    static let squareYardsPerSquareMeter: Double = 1.195990046

    /// Square centimeters in one square meter.
    static let squareCentimetersPerSquareMeter: Double = 10_000.0

    /// Square millimeters in one square meter.
    static let squareMillimetersPerSquareMeter: Double = 1_000_000.0

}
