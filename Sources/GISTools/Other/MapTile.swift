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

    /// Map tiles that share the same parent tile (excludes self).
    /// At zoom level 0 there are no other tiles, so this returns an empty array.
    public var siblings: [MapTile] {
        guard z > 0 else { return [] }
        return parent.children.filter { $0.x != x || $0.y != y }
    }

    /// The tile and all valid adjacent tiles at the same zoom level
    /// (8-directional neighbours). Out-of-world tiles are silently skipped.
    /// At zoom level 0 there are no other tiles, so this returns an empty array.
    public var neighbours: [MapTile] {
        guard z > 0 else { return [] }
        let maxXY = (1 << z) - 1
        guard x >= 0, x <= maxXY, y >= 0, y <= maxXY else { return [] }
        let offsets: [(dx: Int, dy: Int)] = [
            (0, 0), (-1, -1), (0, -1), (1, -1),
            (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)]
        return offsets.compactMap { (dx, dy) -> MapTile? in
            let nx = x + dx
            let ny = y + dy
            guard nx >= 0, nx <= maxXY, ny >= 0, ny <= maxXY else { return nil }
            return MapTile(x: nx, y: ny, z: z)
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

        if projection == .epsg4978 {
            return ecefBoundingBox
        }

        // EPSG:3857, EPSG:4326

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

    /// The axis-aligned bounding box of this tile in EPSG:4978 (ECEF).
    ///
    /// Unlike EPSG:4326 and EPSG:3857 where the SW and NE tile corners
    /// directly define the AABB, ECEF requires sampling the tile's lat/lon
    /// range at interior critical points (equator, ±90°/±180° longitude)
    /// to capture the true ECEF extrema.
    private var ecefBoundingBox: BoundingBox {
        let y = (1 << z) - 1 - self.y

        let sw4326 = GISTool.coordinate(
            fromPixelX: Double(x) * GISTool.tileSideLength,
            pixelY: Double(y) * GISTool.tileSideLength,
            zoom: z,
            projection: .epsg4326)
        let ne4326 = GISTool.coordinate(
            fromPixelX: Double(x + 1) * GISTool.tileSideLength,
            pixelY: Double(y + 1) * GISTool.tileSideLength,
            zoom: z,
            projection: .epsg4326)

        let latMin = sw4326.latitude
        let latMax = ne4326.latitude
        let lonMin = sw4326.longitude
        let lonMax = ne4326.longitude

        var xValues: [Double] = []
        var yValues: [Double] = []
        var zValues: [Double] = []

        func addECEF(lat: Double, lon: Double) {
            let pt = Coordinate3D(latitude: lat, longitude: lon).projected(to: .epsg4978)
            xValues.append(pt.x)
            yValues.append(pt.y)
            zValues.append(pt.z ?? 0.0)
        }

        func evaluateRange(latMin: Double, latMax: Double, lonMin: Double, lonMax: Double) {
            addECEF(lat: latMin, lon: lonMin)
            addECEF(lat: latMin, lon: lonMax)
            addECEF(lat: latMax, lon: lonMin)
            addECEF(lat: latMax, lon: lonMax)

            if latMin <= 0.0, 0.0 <= latMax {
                if lonMin <= 0.0, 0.0 <= lonMax { addECEF(lat: 0.0, lon: 0.0) }
                if lonMin <= 180.0, 180.0 <= lonMax { addECEF(lat: 0.0, lon: 180.0) }
                if lonMin <= 90.0, 90.0 <= lonMax { addECEF(lat: 0.0, lon: 90.0) }
                if lonMin <= -90.0, -90.0 <= lonMax { addECEF(lat: 0.0, lon: -90.0) }
            }
        }

        if lonMin <= lonMax {
            evaluateRange(latMin: latMin, latMax: latMax, lonMin: lonMin, lonMax: lonMax)
        }
        else {
            evaluateRange(latMin: latMin, latMax: latMax, lonMin: lonMin, lonMax: 180.0)
            evaluateRange(latMin: latMin, latMax: latMax, lonMin: -180.0, lonMax: lonMax)
        }

        return BoundingBox(
            southWest: Coordinate3D(x: xValues.min()!, y: yValues.min()!, z: zValues.min()!, projection: .epsg4978),
            northEast: Coordinate3D(x: xValues.max()!, y: yValues.max()!, z: zValues.max()!, projection: .epsg4978))
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

    // MARK: - Ancestry / Descendant

    /// Returns `true` if this tile is an ancestor of `other`.
    ///
    /// A tile is an ancestor of another if the other tile can be reached by
    /// repeatedly applying ``children`` (i.e. the other tile is at a higher
    /// zoom level and falls within this tile's quadrant). A tile is not
    /// considered an ancestor of itself.
    ///
    /// - Parameter other: The potential descendant tile.
    /// - Returns: `true` if this tile is an ancestor of `other`.
    public func isAncestorOf(_ other: MapTile) -> Bool {
        guard other.z > z else { return false }
        var tile = other
        while tile.z > z {
            tile = tile.parent
        }
        return tile == self
    }

    /// Returns `true` if this tile is a descendant of `other`.
    ///
    /// A tile is a descendant of another if this tile can be reached by
    /// repeatedly applying ``children`` from the other tile (i.e. this tile
    /// is at a higher zoom level and falls within the other tile's quadrant).
    /// A tile is not considered a descendant of itself.
    ///
    /// - Parameter other: The potential ancestor tile.
    /// - Returns: `true` if this tile is a descendant of `other`.
    public func isDescendantOf(_ other: MapTile) -> Bool {
        other.isAncestorOf(self)
    }

    /// Returns `true` if this tile is an ancestor or descendant of `other`,
    /// or if they are the same tile.
    ///
    /// Two tiles are related if one can be reached from the other by walking
    /// the ``parent`` chain. Tiles at the same zoom are related only if they
    /// are identical.
    ///
    /// - Parameter other: The tile to check for a relationship.
    /// - Returns: `true` if the tiles are ancestors, descendants, or identical.
    public func isRelated(to other: MapTile) -> Bool {
        if self == other { return true }
        return isAncestorOf(other) || isDescendantOf(other)
    }

    /// All ancestor tiles from the immediate parent up to the root tile
    /// (z = 0), ordered from nearest (smallest zoom difference) to farthest.
    ///
    /// At zoom level 0 this is an empty array.
    public var ancestors: [MapTile] {
        guard z > 0 else { return [] }
        var result: [MapTile] = []
        var tile = parent
        while tile.z >= 0 {
            result.append(tile)
            if tile.z == 0 { break }
            tile = tile.parent
        }
        return result
    }

    /// All descendant tiles of this tile at the given target zoom level.
    ///
    /// The target zoom must be greater than or equal to this tile's zoom.
    /// If the target zoom equals this tile's zoom, the result contains only
    /// this tile. If the target zoom is less than this tile's zoom, the result
    /// is empty.
    ///
    /// - Parameter zoom: The target zoom level.
    /// - Returns: An array of descendant tiles at the given zoom level.
    public func descendants(atZoom zoom: Int) -> [MapTile] {
        guard zoom >= z else { return [] }
        if zoom == z { return [self] }

        var tiles: [MapTile] = [self]
        for _ in z ..< zoom {
            tiles = tiles.flatMap { $0.children }
        }
        return tiles
    }

    // MARK: - Containment

    /// Returns `true` if the given geographic coordinate falls within this
    /// tile's bounding box.
    ///
    /// The coordinate is projected to EPSG:4326 before testing. Coordinates
    /// exactly on the tile boundary (east or south edge) are considered
    /// outside, matching the half-open interval convention used by the
    /// tile pyramid.
    ///
    /// - Parameter coordinate: The geographic coordinate to test.
    /// - Returns: `true` if the coordinate is within this tile.
    public func contains(_ coordinate: Coordinate3D) -> Bool {
        boundingBox().contains(coordinate.projected(to: .epsg4326))
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
