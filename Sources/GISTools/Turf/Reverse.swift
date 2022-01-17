#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    public var reversed: Self {
        switch self {
        case let lineString as LineString:
            var newLineString = LineString(lineString.coordinates.reversed()) ?? lineString
            newLineString.boundingBox = lineString.boundingBox
            newLineString.foreignMembers = lineString.foreignMembers
            return newLineString as! Self

        case let multiLineString as MultiLineString:
            var newMultiLineString = MultiLineString(multiLineString.coordinates.map({ $0.reversed() })) ?? multiLineString
            newMultiLineString.boundingBox = multiLineString.boundingBox
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return newMultiLineString as! Self

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(geometryCollection.geometries.reversed().map({ $0.reversed }))
            newGeometryCollection.boundingBox = geometryCollection.boundingBox
            newGeometryCollection.foreignMembers = geometryCollection.foreignMembers
            return newGeometryCollection as! Self

        case let feature as Feature:
            var newFeature = Feature(feature.geometry.reversed)
            newFeature.id = feature.id
            newFeature.boundingBox = feature.boundingBox
            newFeature.foreignMembers = feature.foreignMembers
            return newFeature as! Self

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(featureCollection.features.reversed().map({ $0.reversed }))
            newFeatureCollection.boundingBox = featureCollection.boundingBox
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return newFeatureCollection as! Self

        default:
            return self
        }
    }

    public mutating func reverse() {
        self = reversed
    }

}

extension Ring {

    public var reversed: Ring {
        Ring(coordinates.reversed()) ?? self
    }

    public mutating func reverse() {
        self = reversed
    }

}

extension LineSegment {

    public var reversed: LineSegment {
        var result = LineSegment(first: second, second: first)
        result.boundingBox = boundingBox
        return result
    }

    public mutating func reverse() {
        self = reversed
    }

}
