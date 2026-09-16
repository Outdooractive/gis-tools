#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// OSGB 1936 math for EPSG:4277 (OSGB 1936 geodetic coordinates on the
/// Airy 1830 ellipsoid).
///
/// Transformations use the OS-documented approximate Helmert
/// transformation (EPSG:1314, "OSGB 1936 to WGS 84 (6)", stated accuracy
/// approximately 2 m). The OS-recommended route for sub-meter accuracy is
/// the OSTN15 grid, which the library does not incorporate (see the grid
/// shift support issue).
struct Osgb1936Definition: ProjectionDefinition {

    private static let helmert = HelmertTransformation.osgb1936

    var projection: Projection { Projection(uncheckedSrid: 4277, definition: self) }
    var kind: ProjectionKind { .geographic }
    var datum: Datum { .osgb1936 }

    var wraparoundExtent: Double? { 180.0 }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox.world
    }

    var wktMatchers: [[String]] {
        [
            ["GEOGCS", "OSGB 1936"],
            ["GEOGCS", "OSGB_1936"],
            ["GEOGCS", "OSGB36"],
        ]
    }

    /// Hoisted batch conversion functions: the Helmert rotation matrices
    /// are built once per batch instead of per coordinate.
    var prepared: BatchPreparedTransforms {
        let steps = Self.helmert.prepared()
        let projection = self.projection

        return BatchPreparedTransforms(
            forward: { coordinate in
                Self.helmert.transform(
                    wgs84ToDatum: coordinate,
                    step: steps.wgs84ToDatum,
                    targetProjection: projection)
            },
            inverse: { coordinate in
                Self.helmert.transform(
                    datumToWgs84: coordinate,
                    step: steps.datumToWgs84)
            })
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        Self.helmert.transform(wgs84ToDatum: coordinate, projection: projection)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        Self.helmert.transform(datumToWgs84: coordinate)
    }

}
