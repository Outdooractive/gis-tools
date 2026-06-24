#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-concave

extension GeoJson {

    /// Returns `true` if the polygon is concave (has at least one interior
    /// angle greater than 180°).
    ///
    /// Non-polygon geometries return `false`.
    ///
    /// For ``Projection/epsg3857`` and ``Projection/epsg4978`` the coordinates
    /// are projected to ``Projection/epsg4326`` first. For ``Projection/noSRID``
    /// the raw 2-D cross product on (x, y) is used.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: `true` if the geometry is a concave polygon, `false` otherwise.
    public func isConcave(gridSize: Double? = nil) -> Bool {
        let geoJson = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self

        if let fc = geoJson as? FeatureCollection {
            return fc.features.contains { $0.isConcave(gridSize: nil) }
        }

        let geom: GeoJson = (geoJson as? Feature)?.geometry ?? geoJson

        guard let polygonGeometry = geom as? PolygonGeometry else { return false }

        return polygonGeometry.polygons.contains { BooleanConcave.isConcave($0) }
    }

}

// MARK: - BooleanConcave namespace

private enum BooleanConcave {

    static func isConcave(_ polygon: Polygon) -> Bool {
        guard let ring = polygon.outerRing?.coordinates else { return false }
        guard ring.count > 4 else { return false }

        let coords: [Coordinate3D]
        if polygon.projection == .noSRID {
            coords = ring
        }
        else if polygon.projection == .epsg4326 {
            coords = ring
        }
        else {
            coords = ring.map { $0.projected(to: .epsg4326) }
        }

        var sign: Bool?
        let n = coords.count - 1

        for i in 0 ..< n {
            let dx1 = coords[(i + 2) % n].longitude - coords[(i + 1) % n].longitude
            let dy1 = coords[(i + 2) % n].latitude - coords[(i + 1) % n].latitude
            let dx2 = coords[i].longitude - coords[(i + 1) % n].longitude
            let dy2 = coords[i].latitude - coords[(i + 1) % n].latitude
            let zCrossProduct = dx1 * dy2 - dy1 * dx2

            if let s = sign {
                if s != (zCrossProduct > 0) {
                    return true
                }
            }
            else {
                sign = zCrossProduct > 0
            }
        }

        return false
    }

}
