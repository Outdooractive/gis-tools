#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    /// Return all coordinates in this object
    public func allCoordinates() -> [Coordinate3D] {
        switch self {
        case let point as Point:
            return [point.coordinate]

        case let multiPoint as MultiPoint:
            return multiPoint.coordinates

        case let lineString as LineString:
            return lineString.coordinates

        case let multiLineString as MultiLineString:
            return multiLineString.coordinates.flatMap({ $0 })

        case let polygon as Polygon:
            return polygon.coordinates.flatMap({ $0 })

        case let multiPolygon as MultiPolygon:
            return multiPolygon.coordinates.flatMap({ $0 }).flatMap({ $0 })

        case let geometryCollection as GeometryCollection:
            return geometryCollection.geometries.flatMap({ $0.allCoordinates() })

        case let feature as Feature:
            return feature.geometry.allCoordinates()

        case let featureCollection as FeatureCollection:
            return featureCollection.features.flatMap({ $0.allCoordinates() })

        default:
            return []
        }
    }

}

extension GeoJson {

    /// Returns a new geometry with all coordinates transformed by the given function.
    ///
    /// - Parameter transform: The transformation function
    public func transformedCoordinates(_ transform: (Coordinate3D) -> Coordinate3D) -> Self {
        switch self {
        case let point as Point:
            var newPoint = Point(transform(point.coordinate), calculateBoundingBox: (point.boundingBox != nil))
            newPoint.foreignMembers = point.foreignMembers
            return newPoint as! Self

        case let multiPoint as MultiPoint:
            var newMultiPoint = MultiPoint(multiPoint.coordinates.map(transform), calculateBoundingBox: (multiPoint.boundingBox != nil))
            newMultiPoint.foreignMembers = multiPoint.foreignMembers
            return newMultiPoint as! Self

        case let lineString as LineString:
            var newLineString = LineString(lineString.coordinates.map(transform), calculateBoundingBox: (lineString.boundingBox != nil))
            newLineString.foreignMembers = lineString.foreignMembers
            return newLineString as! Self

        case let multiLineString as MultiLineString:
            let coordinates = multiLineString.coordinates.map({ (inner) in
                return inner.map(transform)
            })
            var newMultiLineString = MultiLineString(coordinates, calculateBoundingBox: (multiLineString.boundingBox != nil))
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return newMultiLineString as! Self

        case let polygon as Polygon:
            let coordinates = polygon.coordinates.map({ (inner) in
                return inner.map(transform)
            })
            var newPolygon = Polygon(coordinates, calculateBoundingBox: (polygon.boundingBox != nil)) ?? polygon
            newPolygon.foreignMembers = polygon.foreignMembers
            return newPolygon as! Self

        case let multiPolygon as MultiPolygon:
            let coordinates = multiPolygon.coordinates.map({ (outer) in
                outer.map({ (inner) in
                    return inner.map(transform)
                })
            })
            var newMultiPolygon = MultiPolygon(coordinates, calculateBoundingBox: (multiPolygon.boundingBox != nil)) ?? multiPolygon
            newMultiPolygon.foreignMembers = multiPolygon.foreignMembers
            return newMultiPolygon as! Self

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(geometryCollection.geometries.map({ $0.transformedCoordinates(transform) }), calculateBoundingBox: (geometryCollection.boundingBox != nil))
            newGeometryCollection.foreignMembers = geometryCollection.foreignMembers
            return newGeometryCollection as! Self

        case let feature as Feature:
            var newFeature = Feature(feature.geometry.transformedCoordinates(transform), properties: feature.properties, calculateBoundingBox: (feature.boundingBox != nil))
            newFeature.foreignMembers = feature.foreignMembers
            return newFeature as! Self

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(featureCollection.features.map({ $0.transformedCoordinates(transform) }), calculateBoundingBox: (featureCollection.boundingBox != nil))
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return newFeatureCollection as! Self

        default:
            return self
        }
    }

    /// Transforms the receivers coordinates.
    ///
    /// - Parameter transform: The transformation function
    public mutating func transformCoordinates(_ transform: (Coordinate3D) -> Coordinate3D) {
        self = transformedCoordinates(transform)
    }

}
