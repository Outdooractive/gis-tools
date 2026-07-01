#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// A map tile identified by its x/y coordinates and zoom level in the Web Mercator
/// (EPSG:3857) tile coordinate system, commonly used by map renderers such as
/// MapKit, Google Maps, and OpenStreetMap.
public struct MapTile: CustomStringConvertible, Sendable {

    /// The x-coordinate of the tile.
    public let x: Int
    /// The y-coordinate of the tile.
    public let y: Int
    /// The zoom level of the tile.
    public let z: Int

    /// A textual representation of the tile.
    public var description: String {
        "MapTile<(\(x),\(y))@\(z)>"
    }

    /// The parent tile at the previous zoom level.
    public var parent: MapTile {
        guard z > 0 else { return self }
        return MapTile(
            x: x >> 1,
            y: y >> 1,
            z: z - 1)
    }

    /// One of the four child tiles at the next zoom level (north-west quadrant).
    public var child: MapTile {
        MapTile(
            x: x << 1,
            y: y << 1,
            z: z + 1)
    }

    /// All four child tiles at the next zoom level.
    public var children: [MapTile] {
        [
            MapTile(x: x << 1, y: y << 1, z: z + 1),
            MapTile(x: (x << 1) + 1, y: y << 1, z: z + 1),
            MapTile(x: x << 1, y: (y << 1) + 1, z: z + 1),
            MapTile(x: (x << 1) + 1, y: (y << 1) + 1, z: z + 1),
        ]
    }

    /// The sibling tiles sharing the same parent (excludes self).
    /// At z=0 the only tile is returned as itself.
    /// Out-of-world tiles (x or y outside `0 ..< 2ˠ`) are silently excluded.
    public var siblings: [MapTile] {
        guard z > 0 else { return [self] }
        let maxXY = (1 << z) - 1
        return parent.children.filter { candidate in
            (candidate.x != x || candidate.y != y)
                && candidate.x >= 0 && candidate.x <= maxXY
                && candidate.y >= 0 && candidate.y <= maxXY
        }
    }

    /// Creates a map tile from its coordinates and zoom level.
    ///
    /// - Parameters:
    ///    - x: The x-coordinate of the tile
    ///    - y: The y-coordinate of the tile
    ///    - z: The zoom level
    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Creates a map tile from a geographic coordinate at the given zoom level.
    ///
    /// - Parameters:
    ///    - coordinate: The geographic coordinate
    ///    - zoom: The zoom level
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
    /// - Parameters:
    ///    - boundingBox: The bounding box that the tile should completely contain
    ///    - maxZoom: The maximum zoom level of the resulting tile, 0...32
    public init(
        boundingBox: BoundingBox,
        maxZoom: Int = 32
    ) {
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

    /// Creates a map tile from a ``String`` in the format `"z/x/y"`.
    ///
    /// - Parameters:
    ///    - string: A tile string in the format `"z/x/y"`
    /// - Returns: A `MapTile`, or `nil` if the string format is invalid
    public init?(string: String) {
        guard let components = string.components(separatedBy: "/").nilIfEmpty,
              components.count == 3,
              let z = components[0].toInt,
              let x = components[1].toInt,
              let y = components[2].toInt
        else { return nil }

        self.init(x: x, y: y, z: z)
    }

    /// Returns the center coordinate of the tile.
    ///
    /// - Parameter projection: The projection to use for the returned coordinate.
    /// - Returns: The center ``Coordinate3D`` of the tile.
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

    /// Returns the bounding box of the tile.
    ///
    /// - Parameter projection: The projection to use for the bounding box.
    /// - Returns: The ``BoundingBox`` of the tile.
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

    /// The quadkey representation of the tile.
    ///
    /// - Returns: A quadkey string
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

    /// Creates a map tile from a quadkey string.
    ///
    /// - Parameters:
    ///    - quadkey: A quadkey string
    /// - Returns: A `MapTile`, or `nil` if the quadkey is invalid
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
        projection: Projection = .epsg4326
    ) -> Coordinate3D {
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
        tileSideLength: Double = GISTool.tileSideLength
    ) -> Double {
        GISTool.metersPerPixel(atZoom: zoom, latitude: latitude, tileSideLength: tileSideLength)
    }

    /// Resolution (meters/pixel) for a given zoom level measured at the tile center.
    ///
    /// - Returns: The meters per pixel at the tile's center
    public var metersPerPixel: Double {
        GISTool.metersPerPixel(atZoom: z, latitude: centerCoordinate().latitude)
    }

    // MARK: - Private

    /// Normalizes a coordinate for tile indexing using Web Mercator projection.
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

// MARK: - TMS coordinate conversion

extension MapTile {

    /// Converts the MapTile (XYZ convention: y=0 at top) to a TMS row
    /// index (TMS convention: row 0 at bottom).
    ///
    /// GeoPackage tile tables use the TMS convention where row 0 is the
    /// bottom row of the tile pyramid.
    ///
    /// - Parameter matrixHeight: The total number of tile rows at this
    ///   zoom level.
    /// - Returns: The TMS row index.
    public func tmsRow(matrixHeight: Int) -> Int {
        matrixHeight - 1 - y
    }

    /// Creates a MapTile from a TMS tile key.
    ///
    /// GeoPackage tile tables use the TMS convention where row 0 is the
    /// bottom row of the tile pyramid.  This initializer converts back
    /// to the XYZ convention used by MapTile.
    ///
    /// - Parameters:
    ///   - column: The tile column index (same in both conventions).
    ///   - tmsRow: The TMS row index (0 = bottom).
    ///   - zoom: The zoom level.
    ///   - matrixHeight: The total number of tile rows at this zoom level.
    public init(
        column: Int,
        tmsRow: Int,
        zoom: Int,
        matrixHeight: Int
    ) {
        self.x = column
        self.y = matrixHeight - 1 - tmsRow
        self.z = zoom
    }

}

// MARK: - Coordinate shortcuts

extension Coordinate3D {

    /// The receiver as a ``MapTile``.
    ///
    /// - Parameters:
    ///    - zoom: The zoom level
    /// - Returns: A `MapTile` for the receiver at the given zoom
    public func mapTile(atZoom zoom: Int) -> MapTile {
        MapTile(coordinate: self, atZoom: zoom)
    }

}

#if canImport(CoreLocation)
extension CLLocation {

    /// The receiver as a ``MapTile``.
    ///
    /// - Parameters:
    ///    - zoom: The zoom level
    /// - Returns: A `MapTile` for the receiver at the given zoom
    public func mapTile(atZoom zoom: Int) -> MapTile {
        MapTile(coordinate: Coordinate3D(self), atZoom: zoom)
    }

}

extension CLLocationCoordinate2D {

    /// The receiver as a ``MapTile``.
    ///
    /// - Parameters:
    ///    - zoom: The zoom level
    /// - Returns: A `MapTile` for the receiver at the given zoom
    public func mapTile(atZoom zoom: Int) -> MapTile {
        MapTile(coordinate: Coordinate3D(self), atZoom: zoom)
    }

}

#endif
