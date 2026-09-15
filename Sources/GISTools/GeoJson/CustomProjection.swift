#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
import Synchronization

/// A user-supplied projection definition for ``Projection/register(_:)``.
///
/// All transformations are expressed relative to the **EPSG:4326 (WGS84)
/// pivot**: ``forward`` projects geographic WGS84 coordinates into the custom
/// projection, ``inverse`` maps back. Any projection pair is routed through
/// that pivot, so definitions for coordinates on other datums must perform
/// the datum transformation inside these closures.
///
/// ```swift
/// let custom = CustomProjection(
///     srid: 900_001,
///     kind: .planar,
///     wraparoundExtent: 180_000.0,
///     validExtent: ProjectionExtent(minX: -180_000, minY: -90_000,
///                                   maxX: 180_000, maxY: 90_000),
///     worldBoundingBox: nil,
///     wktMatchers: [["PROJCS", "My Custom Grid"]],
///     forward: { coordinate in
///         Coordinate3D(
///             x: coordinate.longitude * 1_000.0,
///             y: coordinate.latitude * 1_000.0,
///             projection: .epsg4326)
///     },
///     inverse: { coordinate in
///         Coordinate3D(
///             latitude: coordinate.latitude / 1_000.0,
///             longitude: coordinate.longitude / 1_000.0,
///             m: coordinate.m)
///     })
/// Projection.register(custom)
/// ```
///
/// - Note: Register projections early (e.g. at app startup). Registration is
///   *add-only*: definitions cannot be removed or replaced, and registering
///   an already used SRID is rejected. Decoding an encoded ``Projection``
///   whose SRID is not registered throws during `Codable`.
public struct CustomProjection: Sendable {

    /// The SRID of the custom projection. Must be a positive integer that
    /// does not collide with an already-registered SRID.
    public var srid: Int

    /// The semantic category of the coordinates, driving the kind-based
    /// algorithm dispatch.
    public var kind: ProjectionKind

    /// The geodetic datum of the projection's coordinate frame. For
    /// non-WGS84 datums, ``forward``/``inverse`` perform the datum
    /// transformation relative to the pivot. Defaults to ``Datum/wgs84``.
    public var datum: Datum

    /// The absolute value beyond which the horizontal axis wraps around
    /// (e.g. the antimeridian for geographic coordinate systems).
    /// `nil` disables wrapping.
    public var wraparoundExtent: Double?

    /// The valid extent of the projection in its own coordinates,
    /// or `nil` if unbounded.
    public var validExtent: ProjectionExtent?

    /// A bounding box spanning the whole world in this projection,
    /// or `nil` if no meaningful world extent exists.
    public var worldBoundingBox: BoundingBox?

    /// WKT fragment sets identifying the projection in `.prj`-like strings
    /// (e.g. `[["PROJCS", "My Custom Grid"]]`).
    ///
    /// Each inner list is one alternative whose every fragment must be
    /// contained in the string for a match. Built-in patterns are tested
    /// first, custom patterns last.
    public var wktMatchers: [[String]]

    /// Converts a coordinate from EPSG:4326 (WGS84) into the custom
    /// projection.
    public var forward: @Sendable (Coordinate3D) -> Coordinate3D

    /// Converts a coordinate from the custom projection into EPSG:4326
    /// (WGS84).
    public var inverse: @Sendable (Coordinate3D) -> Coordinate3D

    public init(
        srid: Int,
        kind: ProjectionKind,
        datum: Datum = .wgs84,
        wraparoundExtent: Double? = nil,
        validExtent: ProjectionExtent? = nil,
        worldBoundingBox: BoundingBox? = nil,
        wktMatchers: [[String]] = [],
        forward: @escaping @Sendable (Coordinate3D) -> Coordinate3D,
        inverse: @escaping @Sendable (Coordinate3D) -> Coordinate3D
    ) {
        self.srid = srid
        self.kind = kind
        self.datum = datum
        self.wraparoundExtent = wraparoundExtent
        self.validExtent = validExtent
        self.worldBoundingBox = worldBoundingBox
        self.wktMatchers = wktMatchers
        self.forward = forward
        self.inverse = inverse
    }

}

// MARK: - Registration

extension Projection {

    /// Registers a custom projection definition so that it can be resolved
    /// via ``init(srid:)`` and used by every algorithm through the
    /// projection registry.
    ///
    /// **Registration is add-only**: built-in projections are permanently
    /// registered and a custom definition cannot be removed or replaced
    /// afterwards.
    ///
    /// The registration is rejected (`false`) when the SRID is `<= 0` or
    /// already in use by a built-in or previously registered projection.
    /// There is no failure path for *lookups* afterwards: a successfully
    /// registered SRID resolves like any built-in one.
    ///
    /// - Parameter projection: The custom definition to register
    /// - Returns: `true` when the registration succeeded
    @discardableResult
    public static func register(_ projection: CustomProjection) -> Bool {
        ProjectionRegistry.register(projection)
    }

}

// MARK: - Internal wrapper

/// Internal adapter bridging a ``CustomProjection`` into the internal
/// ``ProjectionDefinition`` contract.
struct RegisteredCustomDefinition: ProjectionDefinition {

    let custom: CustomProjection

    var projection: Projection { Projection(uncheckedSrid: custom.srid, definition: self) }
    var kind: ProjectionKind { custom.kind }
    var datum: Datum { custom.datum }
    var wraparoundExtent: Double? { custom.wraparoundExtent }
    var validExtent: ProjectionExtent? { custom.validExtent }
    var worldBoundingBox: BoundingBox? { custom.worldBoundingBox }
    var wktMatchers: [[String]] { custom.wktMatchers }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        var result = custom.forward(coordinate)
        if result.projection != projection {
            result = Coordinate3D(
                x: result.longitude,
                y: result.latitude,
                z: result.altitude,
                m: result.m,
                projection: projection)
        }
        return result
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        var result = custom.inverse(coordinate)
        if result.projection != .epsg4326 {
            result = Coordinate3D(
                latitude: result.latitude,
                longitude: result.longitude,
                altitude: result.altitude,
                m: result.m)
        }
        return result
    }

}
