#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    public func tileCover(atZoom zoom: Int) -> [MapTile] {
        var tiles: Set<MapTile> = []

        allCoordinates.forEach { coordinate in
            tiles.insert(MapTile(coordinate: coordinate, atZoom: zoom))
        }

        return Array(tiles)
    }

}

extension BoundingBox {

    public func tileCover(atZoom zoom: Int) -> [MapTile] {
        boundingBoxPolygon.tileCover(atZoom: zoom)
    }

}
