/// Internal strategy providing the transform math for a single projection.
///
/// All conversions are expressed relative to the EPSG:4326 pivot:
/// ``forward(_:)`` maps geographic coordinates into the receiver's
/// projection, ``inverse(_:)`` maps back. Any projection pair is routed
/// through that pivot (source → EPSG:4326 → target).
protocol ProjectionDefinition: Sendable {

    /// The projection the receiver provides math for.
    var projection: Projection { get }

    /// The semantic category of the projection.
    var kind: ProjectionKind { get }

    /// The geodetic datum of the projection's coordinate frame.
    var datum: Datum { get }

    /// The valid coordinate extent of the projection, or `nil` if the
    /// coordinate space is unbounded (e.g. geocentric or no SRID).
    var validExtent: ProjectionExtent? { get }

    /// A bounding box spanning the whole world in this projection,
    /// or `nil` if no meaningful world extent exists.
    var worldBoundingBox: BoundingBox? { get }

    /// WKT fragment sets identifying this projection in a `.prj` file
    /// (e.g. `["PROJCS", "Pseudo-Mercator"]` for EPSG:3857).
    ///
    /// Each inner list is one alternative: a WKT string matches the
    /// definition when every fragment of at least one alternative is
    /// contained in the string. Definitions are probed in registry order
    /// and the first match wins, so the registry order is significant:
    /// more specific patterns must come before more generic ones (e.g.
    /// EPSG:3857's "Pseudo-Mercator" before EPSG:3395's "Mercator").
    var wktMatchers: [[String]] { get }

    /// Converts a coordinate from EPSG:4326 into the receiver's projection.
    ///
    /// - Parameter coordinate: A coordinate in EPSG:4326
    /// - Returns: The coordinate in the receiver's projection
    func forward(_ coordinate: Coordinate3D) -> Coordinate3D

    /// The absolute value beyond which the horizontal axis of the
    /// projection wraps around (e.g. ±180° for geographic coordinates),
    /// or `nil` if it does not wrap.
    var wraparoundExtent: Double? { get }

    /// Converts a coordinate from the receiver's projection into EPSG:4326.
    ///
    /// - Parameter coordinate: A coordinate in the receiver's projection
    /// - Returns: The coordinate in EPSG:4326
    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D

}

extension ProjectionDefinition {

    /// The geodetic datum of the projection's coordinate frame.
    ///
    /// Default is ``Datum/wgs84``; datum-capable projections override this.
    var datum: Datum {
        .wgs84
    }

}

