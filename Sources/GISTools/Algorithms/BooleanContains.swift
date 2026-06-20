#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-contains

extension GeoJson {

    /// Compares two geometries and returns true if the receiver contains the
    /// other geometry.
    ///
    /// "A contains B" means that no points of B lie in the exterior of A, and
    /// at least one point of B lies in the interior of A.
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if the receiver contains the other geometry
    public func contains(_ other: GeoJson) -> Bool {
        if let fc1 = self as? FeatureCollection {
            return fc1.features.contains { $0.contains(other) }
        }
        if let fc2 = other as? FeatureCollection {
            return fc2.features.contains { self.contains($0) }
        }

        let geom1: GeoJson = (self as? Feature)?.geometry ?? self
        let geom2: GeoJson = (other as? Feature)?.geometry ?? other

        guard let geometry1 = geom1 as? GeoJsonGeometry,
              let geometry2 = geom2 as? GeoJsonGeometry
        else { return false }

        return BooleanContains.contains(geometry1, geometry2)
    }

    /// Compares two geometries and returns true if the receiver is within the
    /// other geometry.
    ///
    /// "A is within B" means that no points of A lie in the exterior of B, and
    /// at least one point of A lies in the interior of B.
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if the receiver is within the other geometry
    public func isWithin(_ other: GeoJson) -> Bool {
        other.contains(self)
    }

}

// MARK: - BooleanContains namespace

enum BooleanContains {

}

// MARK: - Geometry dispatch

extension BooleanContains {

    static func contains(
        _ geom1: GeoJsonGeometry,
        _ geom2: GeoJsonGeometry
    ) -> Bool {
        if let bbox1 = geom1.boundingBox,
           let bbox2 = geom2.boundingBox,
           !bbox1.contains(bbox2)
        {
            return false
        }

        switch geom1 {
        case let p as Point:
            return pointContains(p, geom2)

        case let mp as MultiPoint:
            return multiPointContains(mp, geom2)

        case let ls as LineString:
            return lineStringContains(ls, geom2)

        case let mls as MultiLineString:
            return multiLineStringContains(mls, geom2)

        case let p as Polygon:
            return polygonContains(p, geom2)

        case let mp as MultiPolygon:
            return multiPolygonContains(mp, geom2)

        case let gc as GeometryCollection:
            return gc.geometries.contains { contains($0, geom2) }

        default:
            return false
        }
    }

}

// MARK: - Coordinate-in-geometry helper

extension BooleanContains {

    /// Returns true when the coordinate lies in or on the given geometry.
    private static func isCoordinateInGeometry(
        _ coordinate: Coordinate3D,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let point as Point:
            return coordinate.isCoincident(to: point.coordinate)

        case let multiPoint as MultiPoint:
            return multiPoint.points.contains(where: { coordinate.isCoincident(to: $0.coordinate) })

        case let lineStringGeometry as LineStringGeometry:
            return lineStringGeometry.checkIsOnLine(coordinate)

        case let polygonGeometry as PolygonGeometry:
            return polygonGeometry.contains(coordinate, ignoringBoundary: false, gridSize: nil)

        case let geometryCollection as GeometryCollection:
            return geometryCollection.geometries.contains { isCoordinateInGeometry(coordinate, $0) }

        default:
            return false
        }
    }

    /// Returns true when all coordinates of the given geometry lie in or on the
    /// container geometry.
    private static func allCoordinatesInGeometry(
        of geom: GeoJsonGeometry,
        inside container: GeoJsonGeometry
    ) -> Bool {
        geom.allCoordinates.allSatisfy { isCoordinateInGeometry($0, container) }
    }

}

// MARK: - Point

extension BooleanContains {

    private static func pointContains(
        _ point: Point,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let other as Point:
            return point.coordinate.isCoincident(to: other.coordinate)

        default:
            return false
        }
    }

}

// MARK: - MultiPoint

extension BooleanContains {

    private static func multiPointContains(
        _ multiPoint: MultiPoint,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let point as Point:
            return multiPointContainsPoint(multiPoint, point)

        case let other as MultiPoint:
            return multiPointContainsMultiPoint(multiPoint, other)

        default:
            return false
        }
    }

    private static func multiPointContainsPoint(
        _ multiPoint: MultiPoint,
        _ point: Point
    ) -> Bool {
        multiPoint.points.contains(where: { $0.coordinate.isCoincident(to: point.coordinate) })
    }

    private static func multiPointContainsMultiPoint(
        _ multiPoint: MultiPoint,
        _ other: MultiPoint
    ) -> Bool {
        other.points.allSatisfy { otherPoint in
            multiPoint.points.contains(where: { $0.coordinate.isCoincident(to: otherPoint.coordinate) })
        }
    }

}

// MARK: - LineString

extension BooleanContains {

    private static func lineStringContains(
        _ line: LineString,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let point as Point:
            return line.checkIsOnLine(point)

        case let multiPoint as MultiPoint:
            return multiPoint.points.allSatisfy { line.checkIsOnLine($0) }

        case let other as LineString:
            return lineStringContainsLineString(line, other)

        default:
            return false
        }
    }

    private static func lineStringContainsLineString(
        _ line: LineString,
        _ other: LineString
    ) -> Bool {
        other.allCoordinates.allSatisfy { line.checkIsOnLine($0) }
    }

}

// MARK: - MultiLineString

extension BooleanContains {

    private static func multiLineStringContains(
        _ multiLine: MultiLineString,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let point as Point:
            return multiLine.lineStrings.contains { $0.checkIsOnLine(point) }

        case let multiPoint as MultiPoint:
            return multiPoint.points.allSatisfy { point in
                multiLine.lineStrings.contains { $0.checkIsOnLine(point) }
            }

        case let line as LineString:
            return multiLineStringContainsLineString(multiLine, line)

        case let other as MultiLineString:
            return multiLineStringContainsMultiLineString(multiLine, other)

        default:
            return false
        }
    }

    private static func multiLineStringContainsLineString(
        _ multiLine: MultiLineString,
        _ line: LineString
    ) -> Bool {
        line.allCoordinates.allSatisfy { coord in
            multiLine.lineStrings.contains { $0.checkIsOnLine(coord) }
        }
    }

    private static func multiLineStringContainsMultiLineString(
        _ multiLine: MultiLineString,
        _ other: MultiLineString
    ) -> Bool {
        other.lineStrings.allSatisfy { line in
            multiLineStringContainsLineString(multiLine, line)
        }
    }

}

// MARK: - Polygon

extension BooleanContains {

    private static func polygonContains(
        _ polygon: Polygon,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let point as Point:
            return polygon.contains(point, ignoringBoundary: false)

        case let multiPoint as MultiPoint:
            return multiPoint.points.allSatisfy { polygon.contains($0, ignoringBoundary: false) }

        case let line as LineString:
            return allCoordinatesInGeometry(of: line, inside: polygon)

        case let multiLine as MultiLineString:
            return allCoordinatesInGeometry(of: multiLine, inside: polygon)

        case let other as Polygon:
            return polygonContainsPolygon(polygon, other)

        case let multiPolygon as MultiPolygon:
            return multiPolygon.polygons.allSatisfy { polygonContainsPolygon(polygon, $0) }

        default:
            return false
        }
    }

    private static func polygonContainsPolygon(
        _ polygon: Polygon,
        _ other: Polygon
    ) -> Bool {
        allCoordinatesInGeometry(of: other, inside: polygon)
    }

}

// MARK: - MultiPolygon

extension BooleanContains {

    private static func multiPolygonContains(
        _ multiPolygon: MultiPolygon,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        switch geom {
        case let point as Point:
            return multiPolygon.contains(point, ignoringBoundary: false)

        case let multiPoint as MultiPoint:
            return multiPoint.points.allSatisfy { multiPolygon.contains($0, ignoringBoundary: false) }

        case let line as LineString:
            return multiPolygonContainsLineStringOrMultiPoint(multiPolygon, line)

        case let multiLine as MultiLineString:
            return allCoordinatesInGeometry(of: multiLine, inside: multiPolygon)

        case let polygon as Polygon:
            return allCoordinatesInGeometry(of: polygon, inside: multiPolygon)

        case let other as MultiPolygon:
            return multiPolygonContainsMultiPolygon(multiPolygon, other)

        default:
            return false
        }
    }

    private static func multiPolygonContainsLineStringOrMultiPoint(
        _ multiPolygon: MultiPolygon,
        _ geom: GeoJsonGeometry
    ) -> Bool {
        allCoordinatesInGeometry(of: geom, inside: multiPolygon)
    }

    private static func multiPolygonContainsMultiPolygon(
        _ multiPolygon: MultiPolygon,
        _ other: MultiPolygon
    ) -> Bool {
        allCoordinatesInGeometry(of: other, inside: multiPolygon)
    }

}
