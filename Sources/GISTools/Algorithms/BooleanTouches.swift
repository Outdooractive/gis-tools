#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-touches

extension GeoJson {

    /// Compares two geometries and returns true if they touch but do not
    /// intersect in their interiors.
    ///
    /// Two geometries touch if they share at least one common boundary point
    /// but their interiors are disjoint.
    ///
    /// All projections are supported. The 2‑D checks operate on raw
    /// ``longitude``/``latitude`` values regardless of CRS.
    /// For ``Projection/epsg4978`` (ECEF) the XY plane is used; altitude/Z
    /// is ignored.
    ///
    /// - Parameter other: The other geometry
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the geometries touch, `false` otherwise.
    public func touches(_ other: GeoJson, gridSize: Double? = nil) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other

        if let fc1 = snappedSelf as? FeatureCollection {
            return fc1.features.contains { $0.touches(snappedOther) }
        }
        if let fc2 = snappedOther as? FeatureCollection {
            return fc2.features.contains { snappedSelf.touches($0) }
        }

        let geom1: GeoJson = (snappedSelf as? Feature)?.geometry ?? snappedSelf
        let geom2: GeoJson = (snappedOther as? Feature)?.geometry ?? snappedOther

        guard let geometry1 = geom1 as? GeoJsonGeometry,
              let geometry2 = geom2 as? GeoJsonGeometry
        else { return false }

        return BooleanTouches.touches(geometry1, geometry2)
    }

}

// MARK: - BooleanTouches namespace

private enum BooleanTouches {

}

// MARK: - Geometry dispatch

extension BooleanTouches {

    static func touches(
        _ geom1: GeoJsonGeometry,
        _ geom2: GeoJsonGeometry
    ) -> Bool {
        if let bbox1 = geom1.boundingBox,
           let bbox2 = geom2.boundingBox,
           !bbox1.intersects(bbox2)
        {
            return false
        }

        switch geom1 {
        case let p as Point:
            return pointTouches(p, geom2)

        case let mp as MultiPoint:
            return multiPointTouches(mp, geom2)

        case let ls as LineString:
            return lineStringTouches(ls, geom2)

        case let mls as MultiLineString:
            return multiLineStringTouches(mls, geom2)

        case let p as Polygon:
            return polygonTouches(p, geom2)

        case let mp as MultiPolygon:
            return multiPolygonTouches(mp, geom2)

        case let gc as GeometryCollection:
            return gc.geometries.contains { touches($0, geom2) }

        default:
            return false
        }
    }

}

// MARK: - Point

extension BooleanTouches {

    private static func pointTouches(
        _ point: Point,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let ls as LineString:
            return isOnLineEnd(point.coordinate, ls)

        case let mls as MultiLineString:
            return mls.lineStrings.contains { isOnLineEnd(point.coordinate, $0) }

        case let p as Polygon:
            return p.rings.contains { $0.lineString.checkIsOnLine(point.coordinate) }

        case let mp as MultiPolygon:
            return mp.polygons.contains { polygon in
                polygon.rings.contains { ring in
                    ring.lineString.checkIsOnLine(point.coordinate)
                }
            }

        default:
            return false
        }
    }

}

// MARK: - MultiPoint

extension BooleanTouches {

    private static func multiPointTouches(
        _ multiPoint: MultiPoint,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let ls as LineString:
            return multiPointTouchesLineString(multiPoint, ls)

        case let mls as MultiLineString:
            return multiPointTouchesMultiLineString(multiPoint, mls)

        case let p as Polygon:
            return multiPointTouchesPolygon(multiPoint, p)

        case let mp as MultiPolygon:
            return multiPointTouchesMultiPolygon(multiPoint, mp)

        default:
            return false
        }
    }

    private static func multiPointTouchesLineString(
        _ multiPoint: MultiPoint,
        _ lineString: LineString
    ) -> Bool {
        var foundTouchingPoint = false

        for point in multiPoint.points {
            if !foundTouchingPoint, isOnLineEnd(point.coordinate, lineString) {
                foundTouchingPoint = true
            }
            if isOnLineInterior(point.coordinate, lineString) {
                return false
            }
        }

        return foundTouchingPoint
    }

    private static func multiPointTouchesMultiLineString(
        _ multiPoint: MultiPoint,
        _ multiLineString: MultiLineString
    ) -> Bool {
        var foundTouchingPoint = false

        for point in multiPoint.points {
            for lineString in multiLineString.lineStrings {
                if !foundTouchingPoint, isOnLineEnd(point.coordinate, lineString) {
                    foundTouchingPoint = true
                }
                if isOnLineInterior(point.coordinate, lineString) {
                    return false
                }
            }
        }

        return foundTouchingPoint
    }

    private static func multiPointTouchesPolygon(
        _ multiPoint: MultiPoint,
        _ polygon: Polygon
    ) -> Bool {
        let rings = polygon.rings
        let outerRing = rings.first?.lineString
        var foundTouchingPoint = false

        for point in multiPoint.points {
            if !foundTouchingPoint, let outerRing {
                if outerRing.checkIsOnLine(point.coordinate) {
                    foundTouchingPoint = true
                }
            }
            if polygon.contains(point.coordinate, ignoringBoundary: true) {
                return false
            }
        }

        return foundTouchingPoint
    }

    private static func multiPointTouchesMultiPolygon(
        _ multiPoint: MultiPoint,
        _ multiPolygon: MultiPolygon
    ) -> Bool {
        var foundTouchingPoint = false

        for point in multiPoint.points {
            for polygon in multiPolygon.polygons {
                if let outerRing = polygon.rings.first?.lineString {
                    if !foundTouchingPoint, outerRing.checkIsOnLine(point.coordinate) {
                        foundTouchingPoint = true
                    }
                }
                if polygon.contains(point.coordinate, ignoringBoundary: true) {
                    return false
                }
            }
        }

        return foundTouchingPoint
    }

}

// MARK: - LineString

extension BooleanTouches {

    private static func lineStringTouches(
        _ lineString: LineString,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let p as Point:
            return isOnLineEnd(p.coordinate, lineString)

        case let mp as MultiPoint:
            return multiPointTouchesLineString(mp, lineString)

        case let ls as LineString:
            return lineStringsTouch(lineString, ls)

        case let mls as MultiLineString:
            return lineStringTouchesMultiLineString(lineString, mls)

        case let p as Polygon:
            return lineStringTouchesPolygon(lineString, p)

        case let mp as MultiPolygon:
            return lineStringTouchesMultiPolygon(lineString, mp)

        default:
            return false
        }
    }

    private static func lineStringsTouch(
        _ lineString1: LineString,
        _ lineString2: LineString
    ) -> Bool {
        let startMatch = isOnLineEnd(lineString1.firstCoordinate, lineString2)
            || isOnLineEnd(lineString1.lastCoordinate, lineString2)
        guard startMatch else { return false }

        for coordinate in lineString1.allCoordinates {
            if isOnLineInterior(coordinate, lineString2) {
                return false
            }
        }

        return true
    }

    private static func lineStringTouchesMultiLineString(
        _ lineString: LineString,
        _ multiLineString: MultiLineString
    ) -> Bool {
        let startMatch = multiLineString.lineStrings.contains { ls in
            isOnLineEnd(lineString.firstCoordinate, ls)
                || isOnLineEnd(lineString.lastCoordinate, ls)
        }
        guard startMatch else { return false }

        for coordinate in lineString.allCoordinates {
            for ls in multiLineString.lineStrings {
                if isOnLineInterior(coordinate, ls) {
                    return false
                }
            }
        }

        return true
    }

    private static func lineStringTouchesPolygon(
        _ lineString: LineString,
        _ polygon: Polygon
    ) -> Bool {
        let rings = polygon.rings
        let outerRing = rings.first?.lineString
        var foundTouchingPoint = false

        for coordinate in lineString.allCoordinates {
            if !foundTouchingPoint, let outerRing {
                if outerRing.checkIsOnLine(coordinate) {
                    foundTouchingPoint = true
                }
            }
            if polygon.contains(coordinate, ignoringBoundary: true) {
                return false
            }
        }

        return foundTouchingPoint
    }

    private static func lineStringTouchesMultiPolygon(
        _ lineString: LineString,
        _ multiPolygon: MultiPolygon
    ) -> Bool {
        var foundTouchingPoint = false

        for coordinate in lineString.allCoordinates {
            for polygon in multiPolygon.polygons {
                if let outerRing = polygon.rings.first?.lineString {
                    if !foundTouchingPoint, outerRing.checkIsOnLine(coordinate) {
                        foundTouchingPoint = true
                    }
                }
                if polygon.contains(coordinate, ignoringBoundary: true) {
                    return false
                }
            }
        }

        return foundTouchingPoint
    }

}

// MARK: - MultiLineString

extension BooleanTouches {

    private static func multiLineStringTouches(
        _ multiLineString: MultiLineString,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let p as Point:
            return multiLineString.lineStrings.contains { isOnLineEnd(p.coordinate, $0) }

        case let mp as MultiPoint:
            return multiPointTouchesMultiLineString(mp, multiLineString)

        case let ls as LineString:
            return lineStringTouchesMultiLineString(ls, multiLineString)

        case let mls as MultiLineString:
            return multiLineStringsTouch(multiLineString, mls)

        case let p as Polygon:
            return multiLineStringTouchesPolygon(multiLineString, p)

        case let mp as MultiPolygon:
            return multiLineStringTouchesMultiPolygon(multiLineString, mp)

        default:
            return false
        }
    }

    private static func multiLineStringsTouch(
        _ mls1: MultiLineString,
        _ mls2: MultiLineString
    ) -> Bool {
        var endMatch = false

        for ls1 in mls1.lineStrings {
            for ls2 in mls2.lineStrings {
                if isOnLineEnd(ls1.firstCoordinate, ls2)
                    || isOnLineEnd(ls1.lastCoordinate, ls2)
                {
                    endMatch = true
                }
                for coordinate in ls1.allCoordinates {
                    if isOnLineInterior(coordinate, ls2) {
                        return false
                    }
                }
            }
        }

        return endMatch
    }

    private static func multiLineStringTouchesPolygon(
        _ multiLineString: MultiLineString,
        _ polygon: Polygon
    ) -> Bool {
        let outerRing = polygon.rings.first?.lineString
        var foundTouchingPoint = false

        for coordinate in multiLineString.allCoordinates {
            if !foundTouchingPoint, let outerRing {
                if outerRing.checkIsOnLine(coordinate) {
                    foundTouchingPoint = true
                }
            }
            if polygon.contains(coordinate, ignoringBoundary: true) {
                return false
            }
        }

        return foundTouchingPoint
    }

    private static func multiLineStringTouchesMultiPolygon(
        _ multiLineString: MultiLineString,
        _ multiPolygon: MultiPolygon
    ) -> Bool {
        var foundTouchingPoint = false

        for coordinate in multiLineString.allCoordinates {
            for polygon in multiPolygon.polygons {
                if let outerRing = polygon.rings.first?.lineString {
                    if !foundTouchingPoint, outerRing.checkIsOnLine(coordinate) {
                        foundTouchingPoint = true
                    }
                }
                if polygon.contains(coordinate, ignoringBoundary: true) {
                    return false
                }
            }
        }

        return foundTouchingPoint
    }

}

// MARK: - Polygon

extension BooleanTouches {

    private static func polygonTouches(
        _ polygon: Polygon,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let p as Point:
            return pointTouches(p, polygon)

        case let mp as MultiPoint:
            return multiPointTouchesPolygon(mp, polygon)

        case let ls as LineString:
            return lineStringTouchesPolygon(ls, polygon)

        case let mls as MultiLineString:
            return multiLineStringTouchesPolygon(mls, polygon)

        case let p as Polygon:
            return polygonsTouch(polygon, p)

        case let mp as MultiPolygon:
            return polygonTouchesMultiPolygon(polygon, mp)

        default:
            return false
        }
    }

    private static func polygonsTouch(
        _ polygon1: Polygon,
        _ polygon2: Polygon
    ) -> Bool {
        let outerRing1 = polygon1.rings.first?.lineString
        let outerRing2 = polygon2.rings.first?.lineString
        guard let ring1 = outerRing1, let ring2 = outerRing2 else { return false }

        var foundTouchingPoint = false

        for coordinate in ring1.allCoordinates {
            if !foundTouchingPoint, ring2.checkIsOnLine(coordinate) {
                foundTouchingPoint = true
            }
            if polygon2.contains(coordinate, ignoringBoundary: true) {
                return false
            }
        }

        return foundTouchingPoint
    }

    private static func polygonTouchesMultiPolygon(
        _ polygon: Polygon,
        _ multiPolygon: MultiPolygon
    ) -> Bool {
        let outerRing1 = polygon.rings.first?.lineString
        guard let ring1 = outerRing1 else { return false }

        for p2 in multiPolygon.polygons {
            let outerRing2 = p2.rings.first?.lineString
            guard let ring2 = outerRing2 else { continue }

            var foundTouchingPoint = false

            for coordinate in ring1.allCoordinates {
                if !foundTouchingPoint, ring2.checkIsOnLine(coordinate) {
                    foundTouchingPoint = true
                }
                if p2.contains(coordinate, ignoringBoundary: true) {
                    return false
                }
            }

            if foundTouchingPoint {
                return true
            }
        }

        return false
    }

}

// MARK: - MultiPolygon

extension BooleanTouches {

    private static func multiPolygonTouches(
        _ multiPolygon: MultiPolygon,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let p as Point:
            return pointTouches(p, multiPolygon)

        case let mp as MultiPoint:
            return multiPointTouchesMultiPolygon(mp, multiPolygon)

        case let ls as LineString:
            return lineStringTouchesMultiPolygon(ls, multiPolygon)

        case let mls as MultiLineString:
            return multiLineStringTouchesMultiPolygon(mls, multiPolygon)

        case let p as Polygon:
            return polygonTouchesMultiPolygon(p, multiPolygon)

        case let mp as MultiPolygon:
            return multiPolygonsTouch(multiPolygon, mp)

        default:
            return false
        }
    }

    private static func multiPolygonsTouch(
        _ mp1: MultiPolygon,
        _ mp2: MultiPolygon
    ) -> Bool {
        for p1 in mp1.polygons {
            let outerRing1 = p1.rings.first?.lineString
            guard let ring1 = outerRing1 else { continue }

            for p2 in mp2.polygons {
                let outerRing2 = p2.rings.first?.lineString
                guard let ring2 = outerRing2 else { continue }

                var foundTouchingPoint = false

                for coordinate in ring1.allCoordinates {
                    if !foundTouchingPoint, ring2.checkIsOnLine(coordinate) {
                        foundTouchingPoint = true
                    }
                    if p2.contains(coordinate, ignoringBoundary: true) {
                        return false
                    }
                }

                if foundTouchingPoint {
                    return true
                }
            }
        }

        return false
    }

}

// MARK: - Line helpers

extension BooleanTouches {

    fileprivate static func isOnLineEnd(
        _ coordinate: Coordinate3D?,
        _ lineString: LineString
    ) -> Bool {
        guard let coordinate else { return false }
        return lineString.boundary.coordinates.contains { $0.isCoincident(to: coordinate) }
    }

    fileprivate static func isOnLineInterior(
        _ coordinate: Coordinate3D?,
        _ lineString: LineString
    ) -> Bool {
        guard let coordinate else { return false }
        return !isOnLineEnd(coordinate, lineString)
            && lineString.checkIsOnLine(coordinate)
    }

}


