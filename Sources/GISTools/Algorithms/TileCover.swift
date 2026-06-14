#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    /// Returns an array of map tiles covering the receiver at the given zoom level.
    ///
    /// Walks each edge segment in tile space to collect all tiles the geometry passes through,
    /// rather than only tiles at vertex positions. This provides proper coverage along the
    /// edges of line strings and polygon rings.
    ///
    /// - Parameter zoom: The zoom level of the map.
    /// - Returns: An array of ``MapTile`` instances.
    public func tileCover(atZoom zoom: Int) -> [MapTile] {
        let segments = lineSegments
        let scale = Double(1 << zoom)

        guard segments.isNotEmpty else {
            let coordinateTiles = allCoordinates.map {
                MapTile(coordinate: $0, atZoom: zoom)
            }
            return Array(Set(coordinateTiles))
        }

        var tiles: Set<MapTile> = []

        for segment in segments {
            walkSegment(
                from: segment.first,
                to: segment.second,
                zoom: zoom,
                scale: scale,
                tiles: &tiles)
        }

        return Array(tiles)
    }

    /// Walk a single segment in tile space, inserting every tile it crosses.
    private func walkSegment(
        from a: Coordinate3D,
        to b: Coordinate3D,
        zoom: Int,
        scale: Double,
        tiles: inout Set<MapTile>
    ) {
        let na = MapTile.normalizeCoordinate(a.projected(to: .epsg4326))
        let nb = MapTile.normalizeCoordinate(b.projected(to: .epsg4326))

        var x0 = na.longitude * scale
        let y0 = na.latitude * scale
        var x1 = nb.longitude * scale
        let y1 = nb.latitude * scale

        // When the shortest path crosses the anti-meridian, unwrap x1
        // by ±scale so the grid walker takes the shorter route.
        let rawD = b.longitude - a.longitude
        if rawD > 180.0 {
            x1 -= scale
        }
        else if rawD < -180.0 {
            x1 += scale
        }

        let scaleInt = Int(scale)

        func clampedTile(x: Int, y: Int) -> MapTile {
            let cx = ((x % scaleInt) + scaleInt) % scaleInt
            return MapTile(x: cx, y: y, z: zoom)
        }

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

}

extension BoundingBox {

    /// Returns an array of map tiles covering the bounding box at the given zoom level.
    ///
    /// - Parameter zoom: The zoom level of the map.
    /// - Returns: An array of ``MapTile`` instances.
    public func tileCover(atZoom zoom: Int) -> [MapTile] {
        boundingBoxGeometry.tileCover(atZoom: zoom)
    }

}
