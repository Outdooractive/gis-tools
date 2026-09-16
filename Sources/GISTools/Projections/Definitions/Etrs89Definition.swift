#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// ETRS89 math for EPSG:4258 (ETRS89 geodetic coordinates on the GRS80
/// ellipsoid).
///
/// ETRS89 and WGS84 effectively coincide at meter accuracy: the plate-fixed
/// ETRS89 frame differs from WGS84 by centimeters that grow over time, far
/// below the tolerance of this library's algorithms. The transformation is
/// therefore the identity (same behavior as [Ordnance Survey's
/// approach](https://docs.os.uk/osngd/getting-started/os-ngd-fundamentals/coordinate-reference-systems)
/// of providing ETRS89 data labelled as WGS84).
///
/// For cm-level accuracy an epoch-dependent transformation would be needed,
/// which is out of scope for this library.
struct Etrs89Definition: ProjectionDefinition {

    var projection: Projection { Projection(uncheckedSrid: 4258, definition: self) }
    var kind: ProjectionKind { .geographic }
    var datum: Datum { .etrs89 }

    var wraparoundExtent: Double? { 180.0 }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox.world
    }

    var wktMatchers: [[String]] {
        [
            ["GEOGCS", "ETRS89"],
            ["GEOGCS", "ETRS_1989"],
            ["GEOGCS", "ETRS 1989"],
        ]
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            x: coordinate.longitude,
            y: coordinate.latitude,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: projection)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
