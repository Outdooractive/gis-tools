#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    /// Returns the receiver with all coordinates reversed.
    public var reversed: Self {
        switch self {
        case let lineString as LineString:
            var newLineString = LineString(lineString.coordinates.reversed()) ?? lineString
            newLineString.boundingBox = lineString.boundingBox
            newLineString.foreignMembers = lineString.foreignMembers
            return GeometryDispatch.checkedCast(newLineString, to: Self.self)

        case let multiLineString as MultiLineString:
            var newMultiLineString = MultiLineString(multiLineString.coordinates.map({ $0.reversed() })) ?? multiLineString
            newMultiLineString.boundingBox = multiLineString.boundingBox
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return GeometryDispatch.checkedCast(newMultiLineString, to: Self.self)

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(geometryCollection.geometries.map({ $0.reversed }))
            newGeometryCollection.boundingBox = geometryCollection.boundingBox
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
                geometry.reversed,
                id: feature.id,
                properties: feature.properties)
            newFeature.boundingBox = feature.boundingBox
            newFeature.foreignMembers = feature.foreignMembers
            return GeometryDispatch.checkedCast(newFeature, to: Self.self)

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(featureCollection.features.reversed().map({ $0.reversed }))
            newFeatureCollection.boundingBox = featureCollection.boundingBox
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return GeometryDispatch.checkedCast(newFeatureCollection, to: Self.self)

        default:
            return self
        }
    }

    /// Reverses all of the receiver's coordinates.
    public mutating func reverse() {
        self = reversed
    }

}

extension Ring {

    /// Returns the receiver with all coordinates reversed.
    public var reversed: Ring {
        Ring(coordinates.reversed()) ?? self
    }

    /// Reverses all of the receiver's coordinates.
    public mutating func reverse() {
        self = reversed
    }

}

extension LineSegment {

    /// Returns the receiver with all coordinates reversed.
    public var reversed: LineSegment {
        var result = LineSegment(
            first: second,
            second: first,
            index: index)
        result.boundingBox = boundingBox
        return result
    }

    /// Reverses all of the receiver's coordinates.
    public mutating func reverse() {
        self = reversed
    }

}
