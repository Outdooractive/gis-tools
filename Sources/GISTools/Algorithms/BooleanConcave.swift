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
    /// - Returns: `true` if the geometry is a concave polygon, `false` otherwise.
    public func isConcave() -> Bool {
        if let fc = self as? FeatureCollection {
            return fc.features.contains { $0.isConcave() }
        }

        let geom: GeoJson = (self as? Feature)?.geometry ?? self

        guard let polygonGeometry = geom as? PolygonGeometry else { return false }

        return polygonGeometry.polygons.contains { BooleanConcave.isConcave($0) }
    }

}

// MARK: - BooleanConcave namespace

private enum BooleanConcave {

}

// MARK: - Implementation

extension BooleanConcave {

    static func isConcave(_ polygon: Polygon) -> Bool {
        guard let coordinates = polygon.outerRing?.coordinates else { return false }

        // A triangle (4 coordinates including the closing coordinate) is always convex
        guard coordinates.count > 4 else { return false }

        var sign: Bool?
        let n = coordinates.count - 1

        for i in 0 ..< n {
            let dx1 = coordinates[(i + 2) % n].longitude - coordinates[(i + 1) % n].longitude
            let dy1 = coordinates[(i + 2) % n].latitude - coordinates[(i + 1) % n].latitude
            let dx2 = coordinates[i].longitude - coordinates[(i + 1) % n].longitude
            let dy2 = coordinates[i].latitude - coordinates[(i + 1) % n].latitude
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
