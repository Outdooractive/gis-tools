#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct MapTile: CustomStringConvertible, Sendable {

    public let x: Int
    public let y: Int
    public let z: Int

    public var description: String {
        "MapTile<(\(x),\(y))@\(z)>"
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
        let normalizedCoordinate = MapTile.normalizeCoordinate(coordinate.projected(to: .epsg4326))

        self.x = Int(normalizedCoordinate.longitude * scale)
        self.y = Int(normalizedCoordinate.latitude * scale)
        self.z = zoom
    }

    public init?(string: String) {
        guard let components = string.components(separatedBy: "/").nilIfEmpty,
              components.count == 3,
              let z = components[0].toInt,
              let x = components[1].toInt,
              let y = components[2].toInt
        else { return nil }

        self.init(x: x, y: y, z: z)
    }

    public func centerCoordinate(projection: Projection = .epsg4326) -> Coordinate3D {
        // Flip y
        let y = (1 << z) - 1 - y

        let pixelX: Double = (Double(x) + 0.5) * GISTool.tileSideLength
        let pixelY: Double = (Double(y) + 0.5) * GISTool.tileSideLength

        return MapTile.pixelCoordinate(
            pixelX: pixelX,
            pixelY: pixelY,
            atZoom: z,
            tileSideLength: GISTool.tileSideLength,
            projection: projection)
    }

    public func boundingBox(projection: Projection = .epsg4326) -> BoundingBox {
        if projection == .noSRID {
            return BoundingBox(
                southWest: Coordinate3D(x: Double(x), y: Double(y), projection: projection),
                northEast: Coordinate3D(x: Double(x), y: Double(y), projection: projection))
        }

        /// Tile bounds in EPSG:3857.
        // Flip y
        let y = (1 << z) - 1 - y

        let southWest = MapTile.pixelCoordinate(
            pixelX: Double(x) * GISTool.tileSideLength,
            pixelY: Double(y) * GISTool.tileSideLength,
            atZoom: z,
            tileSideLength: GISTool.tileSideLength,
            projection: projection)
        let northEast = MapTile.pixelCoordinate(
            pixelX: Double(x + 1) * GISTool.tileSideLength,
            pixelY: Double(y + 1) * GISTool.tileSideLength,
            atZoom: z,
            tileSideLength: GISTool.tileSideLength,
            projection: projection)

        return BoundingBox(southWest: southWest, northEast: northEast)
    }

    // MARK: - Quadkey

    public var quadkey: String {
        var quadkey = ""

        for zoom in stride(from: z, to: 0, by: -1) {
            var digit = 0
            let mask = 1 << (zoom - 1)

            if (x & mask) != 0 {
                digit += 1
            }
            if (y & mask) != 0 {
                digit += 2
            }

            quadkey.append(String(digit))
        }

        return quadkey
    }

    public init?(quadkey: String) {
        guard !quadkey.isEmpty else {
            self.x = 0
            self.y = 0
            self.z = 0
            return
        }

        var x = 0
        var y = 0

        for (i, digit) in quadkey.reversed().enumerated() {
            let mask = 1 << i

            switch digit {
            case "1":
                x = x | mask
            case "2":
                y = y | mask
            case "3":
                x = x | mask
                y = y | mask
            default:
                guard digit == "0" else { return nil }
            }
        }

        self.x = x
        self.y = y
        self.z = quadkey.count
    }

    // MARK: - Conversion pixel to meters

    /// Converts pixel coordinates in a given zoom level to EPSG:3857.
    public static func pixelCoordinate(
        pixelX: Double,
        pixelY: Double,
        atZoom zoom: Int,
        tileSideLength: Double = GISTool.tileSideLength,
        projection: Projection = .epsg4326)
        -> Coordinate3D
    {
        let resolution = metersPerPixel(at: zoom, tileSideLength: tileSideLength)

        let coordinateXY = Coordinate3D(
            x: pixelX * resolution - GISTool.originShift,
            y: pixelY * resolution - GISTool.originShift)

        if projection == .epsg4326 {
            return coordinateXY.projected(to: projection)
        }

        return coordinateXY
    }

    // MARK: - Meters per pixel

    /// Resolution (meters/pixel) for a given zoom level (measured at `latitude`, defaults to the equator).
    public static func metersPerPixel(
        at zoom: Int,
        latitude: Double = 0.0, // equator
        tileSideLength: Double = GISTool.tileSideLength)
        -> Double
    {
        (cos(latitude * Double.pi / 180.0) * 2.0 * Double.pi * GISTool.equatorialRadius / tileSideLength) / pow(2.0, Double(zoom))
    }

    /// Resolution (meters/pixel) for a given zoom level measured at the tile center.
    public var metersPerPixel: Double {
        MapTile.metersPerPixel(at: z, latitude: centerCoordinate().latitude)
    }

    // MARK: - Private

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
