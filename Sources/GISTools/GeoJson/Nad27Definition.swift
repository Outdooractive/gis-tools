#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// NAD27 math for EPSG:4267 (NAD 1927 geodetic coordinates on the
/// Clarke 1866 ellipsoid).
///
/// Transformations use the EPSG "NAD27 to WGS 84 (4)" Helmert
/// transformation (translation-only, stated accuracy approximately 10 m).
/// Sub-meter accuracy for NAD27 requires NADCON grid shifts, which the
/// library does not incorporate (see the grid shift support issue).
struct Nad27Definition: ProjectionDefinition {

    private static let helmert = HelmertTransformation.nad27

    var projection: Projection { Projection(uncheckedSrid: 4267, definition: self) }
    var kind: ProjectionKind { .geographic }
    var datum: Datum { .nad27 }

    var wraparoundExtent: Double? { 180.0 }

    /// The expression is global. Unbounded like EPSG:4326 (the extent of
    /// the underlying datum's realization is not enforced).
    var validExtent: ProjectionExtent? {
        ProjectionExtent(minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox.world
    }

    var wktMatchers: [[String]] {
        [
            ["GEOGCS", "NAD27"],
            ["GEOGCS", "NAD_1927"],
            ["GEOGCS", "NAD 1927"],
            ["GEOGCS", "North_American_1927"],
            ["GEOGCS", "North American 1927"],
        ]
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        Self.helmert.transform(wgs84ToDatum: coordinate, projection: projection)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        Self.helmert.transform(datumToWgs84: coordinate)
    }

}
