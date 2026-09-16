import Foundation

// MARK: - EPSG:4326

/// Identity math for the EPSG:4326 pivot projection.
struct Epsg4326Definition: ProjectionDefinition {

    var projection: Projection { Projection(uncheckedSrid: 4326, definition: self) }
    var kind: ProjectionKind { .geographic }

    var wraparoundExtent: Double? { 180.0 }
    var wktMatchers: [[String]] {
        [
            ["GEOGCS", "WGS 84"],
            ["GEOGCS", "WGS_1984"],
        ]
    }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(minX: -180.0, minY: -90.0, maxX: 180.0, maxY: 90.0)
    }

    var worldBoundingBox: BoundingBox? {
        BoundingBox.world
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
