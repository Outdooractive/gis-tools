#if !os(Linux)
import CoreLocation
#endif
import Foundation

// MARK: - MapTile

public struct MapTile: CustomStringConvertible {

    public let x: Int
    public let y: Int
    public let z: Int

    public var description: String {
        "MapTile<\(x),\(y))@\(z)>"
    }

    public var parent: MapTile {
        guard z > 0 else { return self }
        return MapTile(
            x: x >> 1,
            y: y >> 1,
            z: z - 1)
    }

    public var child: MapTile {
        MapTile(
            x: x << 1,
            y: y << 1,
            z: z + 1)
    }

    public var children: [MapTile] {
        [
            MapTile(x: x << 1, y: y << 1, z: z + 1),
            MapTile(x: (x << 1) + 1, y: y << 1, z: z + 1),
            MapTile(x: x << 1, y: (y << 1) + 1, z: z + 1),
            MapTile(x: (x << 1) + 1, y: (y << 1) + 1, z: z + 1),
        ]
    }

    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(coordinate: Coordinate3D, atZoom zoom: Int) {
        let scale = Double(1 << zoom)
        let normalizedCoordinate = MapTile.normalizeCoordinate(coordinate)

        self.x = Int(normalizedCoordinate.longitude * scale)
        self.y = Int(normalizedCoordinate.latitude * scale)
        self.z = zoom
    }

    public var centerCoordinate: Coordinate3D {
        // Flip y
        let y = (1 << z) - 1 - y

        let pixelX: Double = (Double(x) + 0.5) * GISTool.tileSideLength
        let pixelY: Double = (Double(y) + 0.5) * GISTool.tileSideLength

        let coordinateXY = MapTile.projectPixelToEpsg3857(
            pixelX: pixelX,
            pixelY: pixelY,
            atZoom: z,
            tileSideLength: GISTool.tileSideLength)

        return coordinateXY.coordinate3D
    }

    /// Tile bounds in EPSG:3857.
    public var epsg3857TileBounds: ProjectedBoundingBox {
        // Flip y
        let y = (1 << z) - 1 - y

        let southWest = MapTile.projectPixelToEpsg3857(
            pixelX: Double(x) * GISTool.tileSideLength,
            pixelY: Double(y) * GISTool.tileSideLength,
            atZoom: z,
            tileSideLength: GISTool.tileSideLength)
        let northEast = MapTile.projectPixelToEpsg3857(
            pixelX: Double(x + 1) * GISTool.tileSideLength,
            pixelY: Double(y + 1) * GISTool.tileSideLength,
            atZoom: z,
            tileSideLength: GISTool.tileSideLength)

        return ProjectedBoundingBox(southWest: southWest, northEast: northEast)
    }

    /// Tile bounds in EPSG:4326
    public var epsg4236TileBounds: ProjectedBoundingBox {
        let bounds = epsg3857TileBounds

        let southWest = bounds.southWest.projectedToEpsg4326
        let northEast = bounds.northEast.projectedToEpsg4326

        return ProjectedBoundingBox(southWest: southWest, northEast: northEast)
    }

    public var boundingBox: BoundingBox {
        epsg4236TileBounds.boundingBox
    }

    // MARK: - Conversions

    /// Converts pixel coordinates in a given zoom level to EPSG:3857.
    public static func projectPixelToEpsg3857(
        pixelX: Double,
        pixelY: Double,
        atZoom zoom: Int,
        tileSideLength: Double = GISTool.tileSideLength)
        -> ProjectedCoordinate
    {
        let resolution = metersPerPixel(at: zoom, tileSideLength: tileSideLength)
        let originShift: Double = 2 * Double.pi * GISTool.equatorialRadius / 2.0

        return ProjectedCoordinate(
            latitude: pixelY * resolution - originShift,
            longitude: pixelX * resolution - originShift,
            projection: .epsg3857)
    }

    /// Resolution (meters/pixel) for a given zoom level (measured at the equator).
    public static func metersPerPixel(
        at zoom: Int,
        tileSideLength: Double = GISTool.tileSideLength)
        -> Double
    {
        (2.0 * Double.pi * GISTool.equatorialRadius / tileSideLength) / pow(2.0, Double(zoom))
    }

    // Private helpers

    private static func normalizeCoordinate(_ coordinate: Coordinate3D) -> Coordinate3D {
        var coordinate = coordinate

        if coordinate.longitude > 180.0 {
            coordinate.longitude -= 360.0
        }

        coordinate.longitude /= 360.0
        coordinate.longitude += 0.5
        coordinate.latitude = 0.5 - ((log(tan((Double.pi / 4) + ((0.5 * Double.pi * coordinate.latitude) / 180.0))) / Double.pi) / 2.0)

        return coordinate
    }

}

// MARK: - Equatable, Hashable

extension MapTile: Equatable, Hashable {}
