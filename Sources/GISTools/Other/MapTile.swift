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

    public var siblings: [MapTile] {
        parent.children
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

    // Ported from https://github.com/mapbox/tilebelt/blob/master/index.js
    /// Initialize a tile from a bounding box.
    /// The resulting tile will have a zoom level in `0...maxZoom`.
    ///
    /// - parameter boundingBox: The bounding box that the tile should completely contain
    /// - parameter maxZoom: The maximum zoom level of the resulting tile, 0...32
    public init(
        boundingBox: BoundingBox,
        maxZoom: Int = 32)
    {
        if boundingBox.crossesAntiMeridian {
            self.init(x: 0, y: 0, z: 0)
            return
        }

        let maxZoom = max(0, min(32, maxZoom))

        let min = MapTile(coordinate: boundingBox.southWest, atZoom: 32)
        let max = MapTile(coordinate: boundingBox.northEast, atZoom: 32)

        var bestZ = -1
        for z in 0 ..< maxZoom {
            let mask = 1 << (32 - (z + 1))
            if (min.x & mask) != (max.x & mask)
                || (min.y & mask) != (max.y & mask)
            {
                bestZ = z
                break
            }
        }
        if bestZ == 0 {
            self.init(x: 0, y: 0, z: 0)
            return
        }
        if bestZ == -1 {
            bestZ = maxZoom
        }

        self.init(
            x: min.x >> (32 - bestZ),
            y: min.y >> (32 - bestZ),
            z: bestZ)
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

        return GISTool.coordinate(
            fromPixelX: pixelX,
            pixelY: pixelY,
            zoom: z,
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

        let southWest = GISTool.coordinate(
            fromPixelX: Double(x) * GISTool.tileSideLength,
            pixelY: Double(y) * GISTool.tileSideLength,
            zoom: z,
            tileSideLength: GISTool.tileSideLength,
            projection: projection)
        let northEast = GISTool.coordinate(
            fromPixelX: Double(x + 1) * GISTool.tileSideLength,
            pixelY: Double(y + 1) * GISTool.tileSideLength,
            zoom: z,
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

    /// Converts pixel coordinates in a given zoom level to a coordinate.
    @available(*, deprecated, renamed: "GISTool.coordinate(fromPixelX:pixelY:zoom:tileSideLength:projection:)", message: "This method has been moved to the GISTool namespace")
    public static func pixelCoordinate(
        pixelX: Double,
        pixelY: Double,
        atZoom zoom: Int,
        tileSideLength: Double = GISTool.tileSideLength,
        projection: Projection = .epsg4326)
        -> Coordinate3D
    {
        GISTool.coordinate(
            fromPixelX: pixelX,
            pixelY: pixelY,
            zoom: zoom,
            tileSideLength: tileSideLength,
            projection: projection)
    }

    // MARK: - Meters per pixel

    /// Resolution (meters/pixel) for a given zoom level (measured at `latitude`, defaults to the equator).
    @available(*, deprecated, renamed: "GISTool.metersPerPixel", message: "This method has been moved to the GISTool namespace")
    public static func metersPerPixel(
        at zoom: Int,
        latitude: Double = 0.0, // equator
        tileSideLength: Double = GISTool.tileSideLength)
        -> Double
    {
        GISTool.metersPerPixel(atZoom: zoom, latitude: latitude, tileSideLength: tileSideLength)
    }

    /// Resolution (meters/pixel) for a given zoom level measured at the tile center.
    public var metersPerPixel: Double {
        GISTool.metersPerPixel(atZoom: z, latitude: centerCoordinate().latitude)
    }

    // MARK: - Private

    static func normalizeCoordinate(_ coordinate: Coordinate3D) -> Coordinate3D {
        var (latitude, longitude) = (coordinate.latitude, coordinate.longitude)

        if longitude > 180.0 {
           longitude -= 360.0
        }

        latitude = min(85.05112877980659, max(-85.05112877980659, latitude))

        longitude /= 360.0
        longitude += 0.5
        latitude = 0.5 - ((log(tan((Double.pi / 4) + ((0.5 * Double.pi * latitude) / 180.0))) / Double.pi) / 2.0)

        return Coordinate3D(latitude: latitude, longitude: longitude)
    }

}

// MARK: - Equatable, Hashable

extension MapTile: Equatable, Hashable {}

// MARK: - Coordinate shortcuts

extension Coordinate3D {

    /// The receiver as a ``MapTile``.
    public func mapTile(atZoom zoom: Int) -> MapTile {
        MapTile(coordinate: self, atZoom: zoom)
    }

}

#if !os(Linux)
extension CLLocation {

    /// The receiver as a ``MapTile``.
    public func mapTile(atZoom zoom: Int) -> MapTile {
        MapTile(coordinate: Coordinate3D(self), atZoom: zoom)
    }

}

extension CLLocationCoordinate2D {

    /// The receiver as a ``MapTile``.
    public func mapTile(atZoom zoom: Int) -> MapTile {
        MapTile(coordinate: Coordinate3D(self), atZoom: zoom)
    }

}
#endif
