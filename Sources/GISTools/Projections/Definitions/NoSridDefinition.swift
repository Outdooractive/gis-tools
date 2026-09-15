import Foundation

/// Null math for coordinates without an SRID.
///
/// Coordinates without an SRID carry no CRS information, so no transformation
/// math applies to them: ``Coordinate3D/projected(to:)`` copies their values
/// verbatim for every target projection and this definition is never reached
/// through the pivot. Its conversions exist only for completeness and copy
/// values verbatim as well.
struct NoSridDefinition: ProjectionDefinition {

    var projection: Projection { Projection(uncheckedSrid: 0, definition: self) }
    var kind: ProjectionKind { .undefined }

    var wraparoundExtent: Double? { nil }
    var wktMatchers: [[String]] {
        []
    }

    /// Coordinates without an SRID have no defined extent.
    var validExtent: ProjectionExtent? {
        nil
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox(
            southWest: Coordinate3D(x: -180.0, y: -90.0, projection: .noSRID),
            northEast: Coordinate3D(x: 180.0, y: 90.0, projection: .noSRID))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            x: coordinate.longitude,
            y: coordinate.latitude,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: .noSRID)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        // Verbatim copy; noSRID values are never transformed.
        Coordinate3D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
