#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// A ring prepared for scanline tile fill: a list of edge segments in
/// geographic coordinates (degrees, possibly unwrapped across the
/// anti-meridian) and the ring's tile-y range.
private struct PreparedRing {
    var segments: [(lon0: Double, lat0: Double, lon1: Double, lat1: Double)]
    var minY: Int
    var maxY: Int
}

/// A segment in Web Mercator tile space (already multiplied by `2^zoom`).
private struct TileSegment {
    var xa: Double
    var ya: Double
    var xb: Double
    var yb: Double
}

extension GeoJson {

    /// Returns an array of map tiles covering the receiver at the given zoom level.
    ///
    /// Coverage is computed in Web Mercator tile space and respects the actual
    /// shape of the geometry:
    ///
    /// - Point / MultiPoint: each coordinate maps to its containing tile.
    /// - LineString / MultiLineString: every tile an edge passes through is
    ///   collected via a DDA grid walk (no interior fill, since a line has none).
    /// - Polygon / MultiPolygon / BoundingBox: a scanline fill is performed in
    ///   tile space, so every fully-enclosed interior tile is returned as well
    ///   as the boundary tiles. Holes are subtracted via an even-odd rule.
    ///
    /// Geometries that cross the anti-meridian are handled by unwrapping each
    /// ring's longitudes into a continuous 360°-wide world before scanning, so
    /// tiles on both sides of the date line are covered exactly once. Tile
    /// x-coordinates are wrapped modulo `2^zoom` at insertion time.
    ///
    /// All projections with a defined geographic meaning (EPSG:4326, EPSG:3857,
    /// EPSG:4978) are supported — coordinates are projected to EPSG:4326
    /// before computing tile positions. noSRID returns an empty array because
    /// there is no defined geographic reference.
    ///
    /// - Parameter zoom: The zoom level of the map.
    /// - Returns: An array of ``MapTile`` instances.
    public func tileCover(atZoom zoom: Int) -> [MapTile] {
        guard projection != .noSRID else { return [] }

        switch self {
        case is Point, is MultiPoint:
            return coordinateTiles(atZoom: zoom)

        case let polygonGeometry as PolygonGeometry:
            return polygonTiles(atZoom: zoom, from: polygonGeometry)

        case let lineStringGeometry as LineStringGeometry:
            return lineTiles(atZoom: zoom, from: lineStringGeometry)

        case let geometryCollection as GeometryCollection:
            return geometryCollection.geometries.flatMap { $0.tileCover(atZoom: zoom) }

        case let feature as Feature:
            return feature.geometry.tileCover(atZoom: zoom)

        case let featureCollection as FeatureCollection:
            return featureCollection.features.flatMap { $0.tileCover(atZoom: zoom) }

        default:
            return coordinateTiles(atZoom: zoom)
        }
    }

    // MARK: - Points

    /// Maps each coordinate of the receiver to its containing tile.
    private func coordinateTiles(atZoom zoom: Int) -> [MapTile] {
        let coordinateTiles = allCoordinates.map { MapTile(coordinate: $0, atZoom: zoom) }
        return Array(Set(coordinateTiles))
    }

    // MARK: - Lines

    /// Walks every edge segment of a line geometry in tile space, inserting
    /// each tile the segment crosses. No interior fill is performed because a
    /// line has no interior.
    private func lineTiles(atZoom zoom: Int, from geometry: LineStringGeometry) -> [MapTile] {
        var tiles: Set<MapTile> = []
        let scale = Double(1 << zoom)

        for lineString in geometry.lineStrings {
            let coordinates = lineString.coordinates
            if coordinates.count < 2 {
                for coordinate in coordinates {
                    tiles.insert(MapTile(coordinate: coordinate, atZoom: zoom))
                }
                continue
            }

            let unwrapped = Self.unwrapLongitudes(coordinates.map { $0.projected(to: .epsg4326) })
            for (first, second, _) in unwrapped.overlappingPairs() {
                guard let second else { continue }
                walkSegment(
                    longitude0: first.longitude,
                    latitude0: first.latitude,
                    longitude1: second.longitude,
                    latitude1: second.latitude,
                    zoom: zoom,
                    scale: scale,
                    tiles: &tiles)
            }
        }

        return Array(tiles)
    }

    // MARK: - Polygons

    /// Performs a scanline fill in tile space for each polygon, subtracting
    /// holes, and returns every covered tile.
    private func polygonTiles(atZoom zoom: Int, from geometry: PolygonGeometry) -> [MapTile] {
        var tiles: Set<MapTile> = []

        for polygon in geometry.polygons {
            fillPolygon(polygon, atZoom: zoom, into: &tiles)
        }

        return Array(tiles)
    }

    /// Fills the interior and boundary of a single polygon (with holes) into
    /// `tiles`, using a scanline fill performed in Web Mercator tile space.
    ///
    /// Ring longitudes are unwrapped into a continuous space so that polygons
    /// crossing the anti-meridian are handled correctly; tile x-coordinates
    /// are wrapped modulo `2^zoom` when inserted.
    private func fillPolygon(
        _ polygon: Polygon,
        atZoom zoom: Int,
        into tiles: inout Set<MapTile>
    ) {
        let scale = Double(1 << zoom)
        let scaleInt = Int(scale)

        var preparedRings: [PreparedRing] = []

        for ring in polygon.rings {
            let coordinates = ring.coordinates
            guard coordinates.count >= 2 else { continue }

            let unwrapped = Self.unwrapLongitudes(coordinates.map { $0.projected(to: .epsg4326) })

            var segments: [(lon0: Double, lat0: Double, lon1: Double, lat1: Double)] = []
            segments.reserveCapacity(unwrapped.count - 1)
            var minY = Int.max
            var maxY = Int.min

            for (first, second, _) in unwrapped.overlappingPairs() {
                guard let second else { continue }

                let (_, normLat0) = Self.mercatorNormalize(longitude: first.longitude, latitude: first.latitude)
                let (_, normLat1) = Self.mercatorNormalize(longitude: second.longitude, latitude: second.latitude)
                let y0 = normLat0 * scale
                let y1 = normLat1 * scale

                let yLo = Int(Swift.min(y0, y1).rounded(.down))
                let yHi = Int(Swift.max(y0, y1).rounded(.up))
                minY = Swift.min(minY, yLo)
                maxY = Swift.max(maxY, yHi)

                segments.append((first.longitude, first.latitude, second.longitude, second.latitude))
            }

            guard segments.isNotEmpty else { continue }
            preparedRings.append(PreparedRing(segments: segments, minY: minY, maxY: maxY))
        }

        guard preparedRings.isNotEmpty else { return }

        let fillMinY = preparedRings.map(\.minY).min() ?? 0
        let fillMaxY = preparedRings.map(\.maxY).max() ?? 0

        let clampX = { (x: Int) -> Int in
            ((x % scaleInt) + scaleInt) % scaleInt
        }

        // Pre-compute tile-space coordinates for every segment endpoint.
        var tileRings: [[TileSegment]] = []
        tileRings.reserveCapacity(preparedRings.count)
        for ring in preparedRings {
            var tileSegments: [TileSegment] = []
            tileSegments.reserveCapacity(ring.segments.count)
            for segment in ring.segments {
                let (lon0, lat0) = Self.mercatorNormalize(longitude: segment.lon0, latitude: segment.lat0)
                let (lon1, lat1) = Self.mercatorNormalize(longitude: segment.lon1, latitude: segment.lat1)
                tileSegments.append(TileSegment(
                    xa: lon0 * scale,
                    ya: lat0 * scale,
                    xb: lon1 * scale,
                    yb: lat1 * scale))
            }
            tileRings.append(tileSegments)
        }

        // Scanline fill: for each tile row, find every edge crossing of the
        // row's mid-line, sort by x, and fill between consecutive pairs. All
        // rings (outer and holes) are processed together; an even-odd rule
        // over the sorted crossings produces the correct union with holes
        // removed.
        for y in fillMinY ... fillMaxY {
            let scanY = Double(y) + 0.5

            var crossings: [Double] = []
            crossings.reserveCapacity(tileRings.flatMap({ $0 }).count / 2 + 1)

            for tileSegments in tileRings {
                for segment in tileSegments {
                    let ya = segment.ya
                    let yb = segment.yb
                    let yMin = Swift.min(ya, yb)
                    let yMax = Swift.max(ya, yb)

                    // Skip horizontal segments and segments not straddling scanY.
                    guard yMax > scanY, scanY > yMin else { continue }

                    let t = (scanY - ya) / (yb - ya)
                    let xCross = segment.xa + (t * (segment.xb - segment.xa))
                    crossings.append(xCross)
                }
            }

            guard crossings.count >= 2 else { continue }

            crossings.sort(by: <)

            var index = 0
            while index < crossings.count - 1 {
                let startX = Int(crossings[index].rounded(.down))
                let endX = Int(crossings[index + 1].rounded(.down))
                let lo = Swift.min(startX, endX)
                let hi = Swift.max(startX, endX)
                for x in lo ... hi {
                    tiles.insert(MapTile(x: clampX(x), y: y, z: zoom))
                }
                index += 2
            }
        }

        // Ensure boundary tiles touched by an edge are included. The scanline
        // fill above already captures most boundary tiles because the row
        // mid-line crosses the ring, but thin slivers where the polygon only
        // grazes a tile row without the mid-line crossing any edge are covered
        // by walking every edge as well.
        for ring in preparedRings {
            for segment in ring.segments {
                walkSegment(
                    longitude0: segment.lon0,
                    latitude0: segment.lat0,
                    longitude1: segment.lon1,
                    latitude1: segment.lat1,
                    zoom: zoom,
                    scale: scale,
                    tiles: &tiles)
            }
        }
    }

    // MARK: - Edge walking

    /// Walks a single segment in tile space via a DDA grid traversal,
    /// inserting every tile the segment passes through.
    ///
    /// Inputs are geographic coordinates (degrees). Longitude is normalized
    /// to tile space without clamping, so unwrapped antimeridian longitudes
    /// (e.g. 190°) map correctly; tile x is wrapped modulo `2^zoom` on
    /// insertion.
    private func walkSegment(
        longitude0: Double,
        latitude0: Double,
        longitude1: Double,
        latitude1: Double,
        zoom: Int,
        scale: Double,
        tiles: inout Set<MapTile>
    ) {
        let scaleInt = Int(scale)

        func clampedTile(x: Int, y: Int) -> MapTile {
            let cx = ((x % scaleInt) + scaleInt) % scaleInt
            return MapTile(x: cx, y: y, z: zoom)
        }

        let (lon0, lat0) = Self.mercatorNormalize(longitude: longitude0, latitude: latitude0)
        let (lon1, lat1) = Self.mercatorNormalize(longitude: longitude1, latitude: latitude1)

        let x0 = lon0 * scale
        let y0 = lat0 * scale
        let x1 = lon1 * scale
        let y1 = lat1 * scale

        let startX = Int(x0.rounded(.down))
        let startY = Int(y0.rounded(.down))
        let endX = Int(x1.rounded(.down))
        let endY = Int(y1.rounded(.down))

        tiles.insert(clampedTile(x: startX, y: startY))

        guard startX != endX || startY != endY else { return }

        let stepX = x1 > x0 ? 1 : -1
        let stepY = y1 > y0 ? 1 : -1

        let tDeltaX = abs(1.0 / (x1 - x0))
        let tDeltaY = abs(1.0 / (y1 - y0))

        let tMaxX: Double
        if x1 > x0 {
            tMaxX = (x0.rounded(.up) - x0) * tDeltaX
        }
        else if x1 < x0 {
            tMaxX = (x0 - x0.rounded(.down)) * tDeltaX
        }
        else {
            tMaxX = .infinity
        }

        let tMaxY: Double
        if y1 > y0 {
            tMaxY = (y0.rounded(.up) - y0) * tDeltaY
        }
        else if y1 < y0 {
            tMaxY = (y0 - y0.rounded(.down)) * tDeltaY
        }
        else {
            tMaxY = .infinity
        }

        var x = startX
        var y = startY
        var tx = tMaxX
        var ty = tMaxY

        while x != endX || y != endY {
            if tx < ty {
                tx += tDeltaX
                x += stepX
            }
            else {
                ty += tDeltaY
                y += stepY
            }
            tiles.insert(clampedTile(x: x, y: y))
        }
    }

    // MARK: - Longitude unwrapping

    /// Unwraps an array of coordinates so that the longitude sequence is
    /// continuous, removing jumps across the ±180° anti-meridian.
    ///
    /// The first coordinate is kept as-is; each subsequent coordinate is
    /// shifted by a multiple of 360° so that the longitude difference between
    /// consecutive points is in `(-180, 180]`. This lets the tile walker and
    /// scanline fill treat a polygon that crosses the date line as a single
    /// continuous polygon in "wrapped" tile space.
    static func unwrapLongitudes(_ coordinates: [Coordinate3D]) -> [Coordinate3D] {
        guard coordinates.isNotEmpty else { return coordinates }

        var result: [Coordinate3D] = []
        result.reserveCapacity(coordinates.count)

        var offset: Double = 0.0
        var previous = coordinates[0]

        result.append(previous)

        for index in 1 ..< coordinates.count {
            let current = coordinates[index]
            let delta = current.longitude - previous.longitude

            if delta > 180.0 {
                offset -= 360.0
            }
            else if delta < -180.0 {
                offset += 360.0
            }

            let unwrapped = Coordinate3D(
                latitude: current.latitude,
                longitude: current.longitude + offset)

            result.append(unwrapped)
            previous = current
        }

        return result
    }

    /// Projects a geographic coordinate to Web Mercator tile-space
    /// coordinates in `[0, 1]`, clamping latitude to the Mercator limit and
    /// shifting longitude to `[0, 1)` via `+ 0.5`. Longitude is **not**
    /// normalized to `[-180, 180]` so unwrapped antimeridian longitudes
    /// (e.g. 190°) are preserved.
    static func mercatorNormalize(
        longitude: Double,
        latitude: Double
    ) -> (longitude: Double, latitude: Double) {
        var lon = longitude
        var lat = Swift.min(85.05112877980659, Swift.max(-85.05112877980659, latitude))

        lon /= 360.0
        lon += 0.5
        lat = 0.5 - ((log(tan((Double.pi / 4.0) + ((0.5 * Double.pi * lat) / 180.0))) / Double.pi) / 2.0)

        return (lon, lat)
    }

}

extension BoundingBox {

    /// Returns an array of map tiles covering the bounding box at the given zoom level.
    ///
    /// Bounding boxes that cross the anti-meridian are internally represented
    /// as a split polygon (see ``boundingBoxGeometry``), so the returned tiles
    /// correctly cover both sides of the date line.
    ///
    /// - Parameter zoom: The zoom level of the map.
    /// - Returns: An array of ``MapTile`` instances.
    public func tileCover(atZoom zoom: Int) -> [MapTile] {
        boundingBoxGeometry.tileCover(atZoom: zoom)
    }

}