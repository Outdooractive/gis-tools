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

private enum BooleanTouches {}

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
            return mls.boundary.coordinates.contains {
                $0.isCoincident(to: point.coordinate)
            }

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
            if !foundTouchingPoint,
               multiLineString.boundary.coordinates.contains(where: {
                   $0.isCoincident(to: point.coordinate)
               })
            {
                foundTouchingPoint = true
            }
            if multiLineString.lineStrings.contains(where: {
                isOnLineInterior(point.coordinate, $0)
            }) {
                return false
            }
        }

        return foundTouchingPoint
    }

    private static func multiPointTouchesPolygon(
        _ multiPoint: MultiPoint,
        _ polygon: Polygon
    ) -> Bool {
        var foundTouchingPoint = false

        for point in multiPoint.points {
            if !foundTouchingPoint, isOnPolygonBoundary(point.coordinate, polygon) {
                foundTouchingPoint = true
            }
            if polygon.contains(point.coordinate) {
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
            if !foundTouchingPoint, isOnMultiPolygonBoundary(point.coordinate, multiPolygon) {
                foundTouchingPoint = true
            }
            for polygon in multiPolygon.polygons where polygon.contains(point.coordinate) {
                return false
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
        if lineString1.isOverlapping(with: lineString2) {
            return false
        }

        let startMatch = lineString1.firstCoordinate.map {
            lineString2.checkIsOnLine($0)
        } ?? false
        let endMatch = lineString1.lastCoordinate.map {
            lineString2.checkIsOnLine($0)
        } ?? false
        let otherStartMatch = lineString2.firstCoordinate.map {
            lineString1.checkIsOnLine($0)
        } ?? false
        let otherEndMatch = lineString2.lastCoordinate.map {
            lineString1.checkIsOnLine($0)
        } ?? false
        guard startMatch || endMatch || otherStartMatch || otherEndMatch else {
            return false
        }

        // Only interior/interior intersections are crossings. An endpoint of
        // one line landing in the interior of the other is a valid touch.
        for intersection in lineString1.intersections(with: lineString2) {
            let point = intersection.coordinate
            if isOnLineInterior(point, lineString1), isOnLineInterior(point, lineString2) {
                return false
            }
        }

        for (index, coordinate) in lineString1.coordinates.enumerated() {
            guard index > 0, index < lineString1.coordinates.count - 1 else { continue }

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
            lineString.firstCoordinate.map { ls.checkIsOnLine($0) } ?? false
                || lineString.lastCoordinate.map { ls.checkIsOnLine($0) } ?? false
        }
        guard startMatch else { return false }

        for ls in multiLineString.lineStrings {
            for intersection in lineString.intersections(with: ls) {
                let point = intersection.coordinate
                if isOnLineInterior(point, lineString), isOnLineInterior(point, ls) {
                    return false
                }
            }
        }

        for (index, coordinate) in lineString.coordinates.enumerated() {
            guard index > 0, index < lineString.coordinates.count - 1 else { continue }

            for ls in multiLineString.lineStrings where isOnLineInterior(coordinate, ls) {
                return false
            }
        }

        return true
    }

    private static func lineStringTouchesPolygon(
        _ lineString: LineString,
        _ polygon: Polygon
    ) -> Bool {
        var foundTouchingPoint = false

        for coordinate in lineString.allCoordinates {
            if !foundTouchingPoint, isOnPolygonBoundary(coordinate, polygon) {
                foundTouchingPoint = true
            }
            if polygon.contains(coordinate) {
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
            if !foundTouchingPoint, isOnMultiPolygonBoundary(coordinate, multiPolygon) {
                foundTouchingPoint = true
            }
            for polygon in multiPolygon.polygons where polygon.contains(coordinate) {
                return false
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
            return multiLineString.boundary.coordinates.contains {
                $0.isCoincident(to: p.coordinate)
            }

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
        var foundTouchingPoint = false

        for coordinate in multiLineString.allCoordinates {
            if !foundTouchingPoint, isOnPolygonBoundary(coordinate, polygon) {
                foundTouchingPoint = true
            }
            if polygon.contains(coordinate) {
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
            if !foundTouchingPoint, isOnMultiPolygonBoundary(coordinate, multiPolygon) {
                foundTouchingPoint = true
            }
            for polygon in multiPolygon.polygons where polygon.contains(coordinate) {
                return false
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
        if polygon1.isOverlapping(with: polygon2) {
            return false
        }
        if polygon1.covers(polygon2) || polygon2.covers(polygon1) {
            return false
        }

        for ring in polygon1.rings {
            for coordinate in ring.coordinates
                where isOnPolygonBoundary(coordinate, polygon2)
            {
                return true
            }
        }
        for ring in polygon2.rings {
            for coordinate in ring.coordinates
                where isOnPolygonBoundary(coordinate, polygon1)
            {
                return true
            }
        }

        return false
    }

    private static func polygonTouchesMultiPolygon(
        _ polygon: Polygon,
        _ multiPolygon: MultiPolygon
    ) -> Bool {
        var touched = false

        for other in multiPolygon.polygons {
            if polygon.isOverlapping(with: other)
                || polygon.covers(other)
                || other.covers(polygon)
            {
                return false
            }
            if polygonsTouch(polygon, other) {
                touched = true
            }
        }

        return touched
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
        var touched = false

        for p1 in mp1.polygons {
            for p2 in mp2.polygons {
                if p1.isOverlapping(with: p2)
                    || p1.covers(p2)
                    || p2.covers(p1)
                {
                    return false
                }
                if polygonsTouch(p1, p2) {
                    touched = true
                }
            }
        }

        return touched
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

    fileprivate static func isOnPolygonBoundary(
        _ coordinate: Coordinate3D,
        _ polygon: Polygon
    ) -> Bool {
        polygon.rings.contains { $0.lineString.checkIsOnLine(coordinate) }
    }

    fileprivate static func isOnMultiPolygonBoundary(
        _ coordinate: Coordinate3D,
        _ multiPolygon: MultiPolygon
    ) -> Bool {
        multiPolygon.polygons.contains { isOnPolygonBoundary(coordinate, $0) }
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
