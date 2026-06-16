#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-crosses

extension GeoJson {

    /// Returns `true` if the intersection of two geometries results in a
    /// geometry whose dimension is one less than the maximum dimension of
    /// the two source geometries, and the intersection set is interior to
    /// both source geometries.
    ///
    /// Supports: MultiPoint / LineString, MultiPoint / Polygon,
    ///           LineString / LineString, LineString / Polygon.
    ///
    /// MultiPolygon behaves like Polygon in these comparisons.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func crosses(_ other: GeoJson, gridSize: Double? = nil) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other

        // FeatureCollection: check if any contained feature crosses.
        if let fc1 = snappedSelf as? FeatureCollection {
            return fc1.features.contains { $0.crosses(snappedOther, gridSize: nil) }
        }
        if let fc2 = snappedOther as? FeatureCollection {
            return fc2.features.contains { snappedSelf.crosses($0.geometry, gridSize: nil) }
        }

        // Anything else
        let geom1: GeoJson = (snappedSelf as? Feature)?.geometry ?? snappedSelf
        let geom2: GeoJson = (snappedOther as? Feature)?.geometry ?? snappedOther

        guard let geometry1 = geom1 as? GeoJsonGeometry,
              let geometry2 = geom2 as? GeoJsonGeometry
        else { return false }

        return geometryCrosses(geometry1, geometry2)
    }

    // MARK: - Geometry dispatch

    private func geometryCrosses(
        _ geom1: GeoJsonGeometry,
        _ geom2: GeoJsonGeometry
    ) -> Bool {
        switch geom1 {
        case let mp as MultiPoint:
            switch geom2 {
            case let ls as LineString:
                return doMultiPointAndLineStringCross(mp, ls)
            case let pg as PolygonGeometry:
                return doesMultiPointCrossPoly(mp, pg)
            default:
                return false
            }

        case let ls as LineString:
            switch geom2 {
            case let mp as MultiPoint:
                return doMultiPointAndLineStringCross(mp, ls)
            case let ls2 as LineString:
                return doLineStringsCross(ls, ls2)
            case let pg as PolygonGeometry:
                return doLineStringAndPolygonCross(ls, pg)
            default:
                return false
            }

        case let pg as PolygonGeometry:
            switch geom2 {
            case let mp as MultiPoint:
                return doesMultiPointCrossPoly(mp, pg)
            case let ls as LineString:
                return doLineStringAndPolygonCross(ls, pg)
            default:
                return false
            }

        default:
            return false
        }
    }

    // MARK: - MultiPoint × LineString

    private func doMultiPointAndLineStringCross(
        _ multiPoint: MultiPoint,
        _ lineString: LineString
    ) -> Bool {
        var foundIntPoint = false
        var foundExtPoint = false

        let segments = lineString.lineSegments
        for point in multiPoint.points {
            var isInterior = false
            for segment in segments {
                if segment.checkIsOnSegment(point.coordinate) {
                    isInterior = true
                    break
                }
            }
            if isInterior {
                foundIntPoint = true
            }
            else {
                foundExtPoint = true
            }
            if foundIntPoint, foundExtPoint {
                return true
            }
        }
        return false
    }

    // MARK: - MultiPoint × Polygon

    private func doesMultiPointCrossPoly(
        _ multiPoint: MultiPoint,
        _ polygonGeometry: PolygonGeometry
    ) -> Bool {
        var foundIntPoint = false
        var foundExtPoint = false

        for point in multiPoint.points {
            if polygonGeometry.contains(point.coordinate, ignoringBoundary: false, gridSize: nil) {
                foundIntPoint = true
            }
            else {
                foundExtPoint = true
            }
            if foundIntPoint, foundExtPoint {
                return true
            }
        }
        return false
    }

    // MARK: - LineString × LineString

    private func doLineStringsCross(
        _ lineString1: LineString,
        _ lineString2: LineString
    ) -> Bool {
        let intersectionPoints = lineString1.intersections(with: lineString2)
        guard intersectionPoints.isNotEmpty else { return false }

        guard let coords1 = lineString1.coordinates as [Coordinate3D]?,
              let coords2 = lineString2.coordinates as [Coordinate3D]?
        else { return false }

        let boundary1 = lineString1.boundary
        let boundary2 = lineString2.boundary

        for intersectPoint in intersectionPoints {
            let pt = intersectPoint.coordinate
            let onBoundary1 = boundary1.coordinates.contains { $0.isCoincident(to: pt) }
            let onBoundary2 = boundary2.coordinates.contains { $0.isCoincident(to: pt) }
            if !onBoundary1 && !onBoundary2 {
                return true
            }
        }

        return false
    }

    // MARK: - LineString × Polygon

    private func doLineStringAndPolygonCross(
        _ lineString: LineString,
        _ polygonGeometry: PolygonGeometry
    ) -> Bool {
        for polygon in polygonGeometry.polygons {
            for ring in polygon.rings {
                let ls = ring.lineString
                if lineString.intersections(with: ls).isNotEmpty {
                    return true
                }
            }
        }
        return false
    }

}


