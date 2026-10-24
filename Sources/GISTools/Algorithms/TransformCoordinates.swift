#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    /// Returns a new geometry with all coordinates transformed by the given function.
    ///
    /// - Parameter transform: The transformation function
    ///
    /// - Returns: A new geometry with transformed coordinates.
    public func transformedCoordinates(
        _ transform: (Coordinate3D) -> Coordinate3D
    ) -> Self {
        switch self {
        case let point as Point:
            var newPoint = Point(
                transform(point.coordinate),
                calculateBoundingBox: (point.boundingBox != nil))
            newPoint.foreignMembers = point.foreignMembers
            return GeometryDispatch.checkedCast(newPoint, to: Self.self)

        case let multiPoint as MultiPoint:
            var newMultiPoint = MultiPoint(
                multiPoint.coordinates.map(transform),
                calculateBoundingBox: (multiPoint.boundingBox != nil)) ?? multiPoint
            newMultiPoint.foreignMembers = multiPoint.foreignMembers
            return GeometryDispatch.checkedCast(newMultiPoint, to: Self.self)

        case let lineString as LineString:
            var newLineString = LineString(
                lineString.coordinates.map(transform),
                calculateBoundingBox: (lineString.boundingBox != nil)) ?? lineString
            newLineString.foreignMembers = lineString.foreignMembers
            return GeometryDispatch.checkedCast(newLineString, to: Self.self)

        case let multiLineString as MultiLineString:
            let coordinates = multiLineString.coordinates.map({ (inner) in
                inner.map(transform)
            })
            var newMultiLineString = MultiLineString(
                coordinates,
                calculateBoundingBox: (multiLineString.boundingBox != nil)) ?? multiLineString
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return GeometryDispatch.checkedCast(newMultiLineString, to: Self.self)

        case let polygon as Polygon:
            let coordinates = polygon.coordinates.map({ (inner) in
                inner.map(transform)
            })
            var newPolygon = Polygon(
                coordinates,
                calculateBoundingBox: (polygon.boundingBox != nil)) ?? polygon
            newPolygon.foreignMembers = polygon.foreignMembers
            return GeometryDispatch.checkedCast(newPolygon, to: Self.self)

        case let multiPolygon as MultiPolygon:
            let coordinates = multiPolygon.coordinates.map({ (outer) in
                outer.map({ (inner) in
                    inner.map(transform)
                })
            })
            var newMultiPolygon = MultiPolygon(
                coordinates,
                calculateBoundingBox: (multiPolygon.boundingBox != nil)) ?? multiPolygon
            newMultiPolygon.foreignMembers = multiPolygon.foreignMembers
            return GeometryDispatch.checkedCast(newMultiPolygon, to: Self.self)

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(
                geometryCollection.geometries.map({ $0.transformedCoordinates(transform) }),
                calculateBoundingBox: (geometryCollection.boundingBox != nil))
            newGeometryCollection.foreignMembers = geometryCollection.foreignMembers
            return GeometryDispatch.checkedCast(newGeometryCollection, to: Self.self)

        case let feature as Feature:
            guard let geometry = feature.geometry else {
                var newFeature = Feature(
                    id: feature.id,
                    properties: feature.properties,
                    foreignMembers: feature.foreignMembers)
                newFeature.boundingBox = feature.boundingBox
                return GeometryDispatch.checkedCast(newFeature, to: Self.self)
            }

            var newFeature = Feature(
                geometry.transformedCoordinates(transform),
                id: feature.id,
                properties: feature.properties,
                calculateBoundingBox: (feature.boundingBox != nil))
            newFeature.foreignMembers = feature.foreignMembers
            return GeometryDispatch.checkedCast(newFeature, to: Self.self)

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(
                featureCollection.features.map({ $0.transformedCoordinates(transform) }),
                calculateBoundingBox: (featureCollection.boundingBox != nil))
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return GeometryDispatch.checkedCast(newFeatureCollection, to: Self.self)

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
