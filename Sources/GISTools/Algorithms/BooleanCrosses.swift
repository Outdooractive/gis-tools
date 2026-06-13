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
    public func crosses(_ other: GeoJson) -> Bool {
        // FeatureCollection: check if any contained feature crosses.
        if let fc1 = self as? FeatureCollection {
            return fc1.features.contains { $0.crosses(other) }
        }
        if let fc2 = other as? FeatureCollection {
            return fc2.features.contains { self.crosses($0.geometry) }
        }

        // Anything else
        let geom1: GeoJson = (self as? Feature)?.geometry ?? self
        let geom2: GeoJson = (other as? Feature)?.geometry ?? other

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

        for point in multiPoint.points {
            var isInterior = false
            let coords = lineString.coordinates
            for i in 0..<(coords.count - 1) {
                let incEnd = (i != 0 && i != coords.count - 2)
                if isPointOnLineSegment(
                    start: coords[i],
                    end: coords[i + 1],
                    point: point.coordinate,
                    incEnd: incEnd)
                {
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
            if polygonGeometry.contains(point.coordinate, ignoringBoundary: false) {
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

        for intersectPoint in intersectionPoints {
            let pt = intersectPoint.coordinate
            if !pt.isCoincident(to: coords1.first),
               !pt.isCoincident(to: coords1.last),
               !pt.isCoincident(to: coords2.first),
               !pt.isCoincident(to: coords2.last)
            {
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

    // MARK: - isPointOnLineSegment

    // TODO: We also have LineSegment.checkIsOnSegment()

    /// Checks whether `point` lies on the line segment from `start` to `end`.
    ///
    /// - parameter incEnd: If `true` the point may coincide with `start` or `end`.
    private func isPointOnLineSegment(
        start: Coordinate3D,
        end: Coordinate3D,
        point: Coordinate3D,
        incEnd: Bool
    ) -> Bool {
        let dxc = point.longitude - start.longitude
        let dyc = point.latitude - start.latitude
        let dxl = end.longitude - start.longitude
        let dyl = end.latitude - start.latitude
        let cross = dxc * dyl - dyc * dxl

        guard cross == 0.0 else { return false }

        if incEnd {
            if abs(dxl) >= abs(dyl) {
                return dxl > 0
                    ? start.longitude <= point.longitude && point.longitude <= end.longitude
                    : end.longitude <= point.longitude && point.longitude <= start.longitude
            }
            return dyl > 0
                ? start.latitude <= point.latitude && point.latitude <= end.latitude
                : end.latitude <= point.latitude && point.latitude <= start.latitude
        }
        else {
            if abs(dxl) >= abs(dyl) {
                return dxl > 0
                    ? start.longitude < point.longitude && point.longitude < end.longitude
                    : end.longitude < point.longitude && point.longitude < start.longitude
            }
            return dyl > 0
                ? start.latitude < point.latitude && point.latitude < end.latitude
                : end.latitude < point.latitude && point.latitude < start.latitude
        }
    }

}

// MARK: - Coordinate3D helper

extension Coordinate3D {

    /// `true` when the receiver is equal to `other` within
    /// the global equality delta.
    fileprivate func isCoincident(to other: Coordinate3D?) -> Bool {
        guard let other else { return false }
        return self.equals(other: other, includingAltitude: false)
    }

}
