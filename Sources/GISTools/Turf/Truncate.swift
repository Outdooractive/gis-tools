#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-truncate

extension Coordinate3D {

    /// Truncates the precision of the coordinate.
    ///
    /// - Parameters:
    ///    - precision: The coordinate decimal precision (default *6*)
    ///    - removeAltitude: Whether to remove the coordinate's altitude value (default *false*)
    public func truncated(
        precision: Int = 6,
        removeAltitude: Bool = false,
        removeM: Bool = false)
        -> Coordinate3D
    {
        Coordinate3D(
            x: longitude.rounded(precision: precision),
            y: latitude.rounded(precision: precision),
            z: (removeAltitude ? nil : altitude?.rounded(precision: precision)),
            m: (removeM ? nil : m),
            projection: projection)
    }

    /// Truncates the precision of the coordinate.
    ///
    /// - Parameters:
    ///    - precision: The coordinate decimal precision (default *6*)
    ///    - removeAltitude: Whether to remove the coordinate's altitude value (default *false*)
    public mutating func truncate(precision: Int, removeAltitude: Bool = false) {
        self = truncated(precision: precision, removeAltitude: removeAltitude)
    }

}

extension GeoJson {

    /// Truncates the precision of the geometry.
    ///
    /// - Parameters:
    ///    - precision: The coordinate decimal precision (default *6*)
    ///    - removeAltitude: Whether to remove the coordinate's altitude value (default *false*)
    public func truncated(
        precision: Int = 6,
        removeAltitude: Bool = false)
        -> Self
    {
        switch self {
        case let point as Point:
            var newPoint = Point(point.coordinate.truncated(precision: precision, removeAltitude: removeAltitude))
            newPoint.boundingBox = point.boundingBox
            newPoint.foreignMembers = point.foreignMembers
            return newPoint as! Self

        case let multiPoint as MultiPoint:
            guard var newMultiPoint = MultiPoint(multiPoint.coordinates.map({
                $0.truncated(precision: precision, removeAltitude: removeAltitude)
            })) else { return self }
            newMultiPoint.boundingBox = multiPoint.boundingBox
            newMultiPoint.foreignMembers = multiPoint.foreignMembers
            return newMultiPoint as! Self

        case let lineString as LineString:
            guard var newLineString = LineString(lineString.coordinates.map({
                $0.truncated(precision: precision, removeAltitude: removeAltitude)
            }))  else { return self }
            newLineString.boundingBox = lineString.boundingBox
            newLineString.foreignMembers = lineString.foreignMembers
            return newLineString as! Self

        case let multiLineString as MultiLineString:
            guard var newMultiLineString = MultiLineString(multiLineString.coordinates.map({
                $0.map({
                    $0.truncated(precision: precision, removeAltitude: removeAltitude)
                })
            }))  else { return self }
            newMultiLineString.boundingBox = multiLineString.boundingBox
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return newMultiLineString as! Self

        case let polygon as Polygon:
            guard var newPolygon = Polygon(polygon.coordinates.map({
                $0.map({
                    $0.truncated(precision: precision, removeAltitude: removeAltitude)
                })
            })) else { return self }
            newPolygon.boundingBox = polygon.boundingBox
            newPolygon.foreignMembers = polygon.foreignMembers
            return newPolygon as! Self

        case let multiPolygon as MultiPolygon:
            guard var newMultiPolygon = MultiPolygon(multiPolygon.coordinates.map({
                $0.map({
                    $0.map({
                        $0.truncated(precision: precision, removeAltitude: removeAltitude)
                    })
                })
            })) else { return self }
            newMultiPolygon.boundingBox = multiPolygon.boundingBox
            newMultiPolygon.foreignMembers = multiPolygon.foreignMembers
            return newMultiPolygon as! Self

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(geometryCollection.geometries.map({
                $0.truncated(precision: precision, removeAltitude: removeAltitude)
            }))
            newGeometryCollection.boundingBox = geometryCollection.boundingBox
            newGeometryCollection.foreignMembers = geometryCollection.foreignMembers
            return newGeometryCollection as! Self

        case let feature as Feature:
            var newFeature = Feature(feature.geometry.truncated(precision: precision, removeAltitude: removeAltitude), id: feature.id, properties: feature.properties)
            newFeature.boundingBox = feature.boundingBox
            newFeature.foreignMembers = feature.foreignMembers
            return newFeature as! Self

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(featureCollection.features.map({
                $0.truncated(precision: precision, removeAltitude: removeAltitude)
            }))
            newFeatureCollection.boundingBox = featureCollection.boundingBox
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return newFeatureCollection as! Self

        default:
            return self
        }
    }

    /// Truncates the precision of the geometry.
    ///
    /// - Parameters:
    ///    - precision: The coordinate decimal precision (default *6*)
    ///    - removeAltitude: Whether to remove the coordinate's altitude value (default *false*)
    public mutating func truncate(
        precision: Int = 6,
        removeAltitude: Bool = false)
    {
        self = truncated(precision: precision, removeAltitude: removeAltitude)
    }

}
