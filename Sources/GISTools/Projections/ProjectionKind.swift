
/// The semantic category of a projection.
///
/// Algorithms use this to select behavior that depends on the *type* of
/// coordinate system (angular vs. planar vs. geocentric) instead of a
/// specific EPSG code, so that newly registered projections automatically
/// get sensible default behavior.
public enum ProjectionKind: Sendable {

    /// Angular geographic coordinates: latitude/longitude in degrees
    /// (e.g. EPSG:4326).
    case geographic

    /// Planar projected coordinates in meters, using Euclidean math
    /// (e.g. EPSG:3857).
    case planar

    /// Geocentric 3D cartesian coordinates (ECEF) in meters
    /// (e.g. EPSG:4978).
    case geocentric

    /// No SRID (invalid/unknown projection).
    case undefined

}
