import Foundation

/// The location of a coordinate relative to a geometry.
///
/// This mirrors the OGC Simple Features / JTS `Location` model and is the
/// primitive behind `contains(_:gridSize:)`, `covers(_:gridSize:)`
/// and their equivalents on the other geometry types:
///
/// - `contains` is `true` only for ``interior`` (OGC/PostGIS `ST_Contains`
///   semantics for points).
/// - `covers` is `true` for ``interior`` and ``boundary`` (OGC/PostGIS
///   `ST_Covers` semantics for points).
///
/// For polygons with holes, a coordinate on a hole's boundary is ``boundary``,
/// not ``exterior``. This matches JTS `SimplePointInAreaLocator` and GEOS.
public enum PointLocation: Sendable, Equatable, Hashable, CaseIterable {

    /// The coordinate lies in the interior of the geometry.
    case interior

    /// The coordinate lies exactly on the geometry's boundary.
    case boundary

    /// The coordinate lies outside the geometry.
    case exterior

}
