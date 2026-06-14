import Foundation

/// Snaps coordinates to the nearest grid point.
extension GeoJson {

    /// Snaps each coordinate to the nearest grid point with the given spacing.
    ///
    /// The tolerance is in the coordinate reference system's native unit:
    /// - **EPSG:4326** (lon/lat) / **noSRID**: degrees
    /// - **EPSG:3857** (web mercator): meters
    ///
    /// To snap to a meter‑based grid from EPSG:4326, convert the tolerance first:
    /// ```swift
    /// let d = GISTool.degrees(fromMeters: 100, atLatitude: centerLat)
    /// let snapped = geometry.snappedToGrid(tolerance: d.longitudeDegrees)
    /// ```
    /// And to convert the other way:
    /// ```swift
    /// let m = GISTool.meters(fromDegrees: 0.1, longitudeDegrees: 0.1, atLatitude: centerLat)
    /// ```
    ///
    /// - Warning: Snapping can produce invalid geometries — rings with fewer than 3
    ///   distinct points, self‑intersections, or collapsed features. Use ``GeoJson/isValid``
    ///   or ``GeoJson/validated`` to check the result before passing it downstream.
    ///
    /// - Parameter tolerance: Grid spacing in the CRS unit (must be > 0).
    /// - Returns: A new geometry with coordinates snapped to the nearest grid point.
    public func snappedToGrid(tolerance: Double) -> Self {
        SnapToGrid.snap(self, tolerance: tolerance) as! Self
    }

    /// Snaps each coordinate to the nearest grid point, mutating in place.
    ///
    /// - Parameter tolerance: Grid spacing in the CRS unit (must be > 0).
    public mutating func snapToGrid(tolerance: Double) {
        self = snappedToGrid(tolerance: tolerance)
    }

}

// MARK: - SnapToGrid namespace

private enum SnapToGrid {

    static func snap(_ geoJson: GeoJson, tolerance: Double) -> GeoJson {
        guard tolerance > 0.0 else { return geoJson }

        switch geoJson {
        case let point as Point:
            return snap(point: point, tolerance: tolerance)

        case let multiPoint as MultiPoint:
            return snap(multiPoint: multiPoint, tolerance: tolerance)

        case let lineString as LineString:
            return snap(lineString: lineString, tolerance: tolerance)

        case let multiLineString as MultiLineString:
            return snap(multiLineString: multiLineString, tolerance: tolerance)

        case let polygon as Polygon:
            return snap(polygon: polygon, tolerance: tolerance)

        case let multiPolygon as MultiPolygon:
            return snap(multiPolygon: multiPolygon, tolerance: tolerance)

        case let geometryCollection as GeometryCollection:
            return snap(geometryCollection: geometryCollection, tolerance: tolerance)

        case let feature as Feature:
            return snap(feature: feature, tolerance: tolerance)

        case let featureCollection as FeatureCollection:
            return snap(featureCollection: featureCollection, tolerance: tolerance)

        default:
            return geoJson
        }
    }

}

// MARK: - Coordinate snapping

extension SnapToGrid {

    private static func snapCoordinate(_ coord: Coordinate3D, tolerance: Double) -> Coordinate3D {
        var c = coord
        c.longitude = round(c.longitude / tolerance) * tolerance
        c.latitude = round(c.latitude / tolerance) * tolerance
        return c
    }

    private static func dedup(_ coordinates: [Coordinate3D]) -> [Coordinate3D] {
        guard coordinates.count > 1 else { return coordinates }

        var result: [Coordinate3D] = [coordinates[0]]
        for coord in coordinates.dropFirst() {
            if coord != result.last! {
                result.append(coord)
            }
        }
        return result
    }

}

// MARK: - Geometry dispatch

extension SnapToGrid {

    private static func snap(point: Point, tolerance: Double) -> Point {
        let snapped = snapCoordinate(point.coordinate, tolerance: tolerance)
        var result = Point(snapped)
        result.boundingBox = point.boundingBox
        result.foreignMembers = point.foreignMembers
        return result
    }

    private static func snap(multiPoint: MultiPoint, tolerance: Double) -> MultiPoint {
        guard var result = MultiPoint(multiPoint.coordinates.map({ snapCoordinate($0, tolerance: tolerance) }))
        else { return multiPoint }
        result.boundingBox = multiPoint.boundingBox
        result.foreignMembers = multiPoint.foreignMembers
        return result
    }

    private static func snap(lineString: LineString, tolerance: Double) -> LineString {
        let snapped = lineString.coordinates.map({ snapCoordinate($0, tolerance: tolerance) })
        let cleaned = dedup(snapped)
        guard var result = LineString(cleaned) else { return lineString }
        result.boundingBox = lineString.boundingBox
        result.foreignMembers = lineString.foreignMembers
        return result
    }

    private static func snap(multiLineString: MultiLineString, tolerance: Double) -> MultiLineString {
        let snapped = multiLineString.coordinates.map({ line in
            dedup(line.map({ snapCoordinate($0, tolerance: tolerance) }))
        })
        guard var result = MultiLineString(snapped) else { return multiLineString }
        result.boundingBox = multiLineString.boundingBox
        result.foreignMembers = multiLineString.foreignMembers
        return result
    }

    private static func snap(polygon: Polygon, tolerance: Double) -> Polygon {
        let snapped = polygon.coordinates.map({ ring in
            dedup(ring.map({ snapCoordinate($0, tolerance: tolerance) }))
        })
        guard var result = Polygon(snapped) else { return polygon }
        result.boundingBox = polygon.boundingBox
        result.foreignMembers = polygon.foreignMembers
        return result
    }

    private static func snap(multiPolygon: MultiPolygon, tolerance: Double) -> MultiPolygon {
        let snapped = multiPolygon.coordinates.map({ polygon in
            polygon.map({ ring in
                dedup(ring.map({ snapCoordinate($0, tolerance: tolerance) }))
            })
        })
        guard var result = MultiPolygon(snapped) else { return multiPolygon }
        result.boundingBox = multiPolygon.boundingBox
        result.foreignMembers = multiPolygon.foreignMembers
        return result
    }

    private static func snap(geometryCollection: GeometryCollection, tolerance: Double) -> GeometryCollection {
        var result = GeometryCollection(geometryCollection.geometries.map({
            snap($0, tolerance: tolerance) as! GeoJsonGeometry
        }))
        result.boundingBox = geometryCollection.boundingBox
        result.foreignMembers = geometryCollection.foreignMembers
        return result
    }

    private static func snap(feature: Feature, tolerance: Double) -> Feature {
        var result = Feature(
            snap(feature.geometry, tolerance: tolerance) as! GeoJsonGeometry,
            id: feature.id,
            properties: feature.properties)
        result.boundingBox = feature.boundingBox
        result.foreignMembers = feature.foreignMembers
        return result
    }

    private static func snap(featureCollection: FeatureCollection, tolerance: Double) -> FeatureCollection {
        var result = FeatureCollection(featureCollection.features.map({ snap(feature: $0, tolerance: tolerance) }))
        result.boundingBox = featureCollection.boundingBox
        result.foreignMembers = featureCollection.foreignMembers
        return result
    }

}
