import Foundation

// MARK: - EPSG:3857

/// Web Mercator math for EPSG:3857.
struct Epsg3857Definition: ProjectionDefinition {

    var projection: Projection { Projection(uncheckedSrid: 3857, definition: self) }
    var kind: ProjectionKind { .planar }

    var wraparoundExtent: Double? { GISTool.originShift }
    var wktMatchers: [[String]] {
        [
            ["PROJCS", "Pseudo-Mercator"],
        ]
    }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(
            minX: -GISTool.originShift,
            minY: -GISTool.originShift,
            maxX: GISTool.originShift,
            maxY: GISTool.originShift)
    }

    var worldBoundingBox: BoundingBox? {
        let shift = GISTool.originShift
        return BoundingBox(
            southWest: Coordinate3D(x: -shift, y: -shift, projection: .epsg3857),
            northEast: Coordinate3D(x: shift, y: shift, projection: .epsg3857))
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let x = coordinate.longitude * GISTool.originShift / 180.0
        var y: Double = log(tan((90.0 + coordinate.latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
        y *= GISTool.originShift / 180.0

        return Coordinate3D(
            x: x,
            y: y,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: .epsg3857)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let longitude = (coordinate.longitude / GISTool.originShift) * 180.0
        let expArgument = (coordinate.latitude / GISTool.originShift) * 180.0 * Double.pi / 180.0
        let latitude = 180.0 / Double.pi * ((2.0 * atan(exp(expArgument))) - (Double.pi / 2.0))

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

}
