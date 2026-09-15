import Foundation

// MARK: - EPSG:32662

/// Plate Carrée (equirectangular) math for EPSG:32662 (WGS 84 / Plate Carree).
///
/// The simplest possible projection: longitude and latitude are used
/// directly as x and y in degrees. Distance and area calculations on
/// Plate Carrée coordinates are NOT metric despite the planar kind.
struct Epsg32662Definition: ProjectionDefinition {

    var projection: Projection { Projection(uncheckedSrid: 32_662, definition: self) }
    var kind: ProjectionKind { .planar }

    var wraparoundExtent: Double? { 180.0 }
    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Plate Carree"],
        ]
    }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox(
            southWest: Coordinate3D(x: -180.0, y: -90.0, projection: .epsg32662),
            northEast: Coordinate3D(x: 180.0, y: 90.0, projection: .epsg32662))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            x: coordinate.longitude,
            y: coordinate.latitude,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: .epsg32662)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        Coordinate3D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}

// MARK: - No SRID

/// Null math for coordinates without an SRID.
