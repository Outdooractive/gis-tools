#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    /// Returns an array of map tiles covering the receiver at the given zoom level.
    ///
    /// - Parameter zoom: The zoom level of the map.
    /// - Returns: An array of ``MapTile`` instances.
    public func tileCover(atZoom zoom: Int) -> [MapTile] {
        var tiles: Set<MapTile> = []

        allCoordinates.forEach { coordinate in
            tiles.insert(MapTile(coordinate: coordinate, atZoom: zoom))
        }

        return Array(tiles)
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
