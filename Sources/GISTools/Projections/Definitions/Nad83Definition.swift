#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// NAD83 geographic math for EPSG:4269 (the North American Datum 1983
/// realization).
///
/// NAD83 and WGS84 effectively coincide at meter accuracy: the datum
/// difference is continental plate motion (1–2 m), with no simple Helmert
/// — sub-meter accuracy requires the NADCON/HARN grid shifts (see the grid
/// shift support issue). The transformation is therefore the identity
/// (same behavior as ``Etrs89Definition``).
struct Nad83Definition: ProjectionDefinition {

    var projection: Projection {
        Projection(uncheckedSrid: 4269, definition: self)
    }

    var kind: ProjectionKind {
        .geographic
    }

    var datum: Datum {
        .nad83
    }

    var wraparoundExtent: Double? {
        180.0
    }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox.world
    }

    var wktMatchers: [[String]] {
        [
            ["GEOGCS", "NAD83"],
            ["GEOGCS", "NAD_1983"],
            ["GEOGCS", "NAD 1983"],
            ["GEOGCS", "North_American_1983"],
            ["GEOGCS", "North American 1983"],
        ]
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        forward(coordinate)
    }

}
