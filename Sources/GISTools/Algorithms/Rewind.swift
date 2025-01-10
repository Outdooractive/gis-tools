#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    /// Returns the receiver with the outer ring counterclockwise and inner rings clockwise.
    /// `Point` and `MultiPoint` will be returned as-is.
    public var rewinded: Self {
        switch self {
        case let lineString as LineString:
            guard let ring = Ring(lineString.coordinates) else { return self }
            if ring.isClockwise { return self }
            return lineString.reversed as! Self

        case let multiLineString as MultiLineString:
            var newMultiLineString = MultiLineString(
                unchecked: multiLineString.lineStrings.map({ $0.rewinded }),
                calculateBoundingBox: (multiLineString.boundingBox != nil))
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return newMultiLineString as! Self

        case let polygon as Polygon:
            guard var outer = polygon.outerRing else { return self }
            if outer.isClockwise { outer.reverse() }
            let inner: [Ring] = polygon.innerRings?.map({ $0.isClockwise ? $0 : $0.reversed }) ?? []
            var newPolygon = Polygon(
                unchecked: [outer] + inner,
                calculateBoundingBox: (polygon.boundingBox != nil))
            newPolygon.foreignMembers = polygon.foreignMembers
            return newPolygon as! Self

        case let multiPolygon as MultiPolygon:
            var newMultiPolygon = MultiPolygon(
                unchecked: multiPolygon.polygons.map({ $0.rewinded }),
                calculateBoundingBox: (multiPolygon.boundingBox != nil))
            newMultiPolygon.foreignMembers = multiPolygon.foreignMembers
            return newMultiPolygon as! Self

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(
                geometryCollection.geometries.map({ $0.rewinded }),
                calculateBoundingBox: (geometryCollection.boundingBox != nil))
            newGeometryCollection.foreignMembers = geometryCollection.foreignMembers
            return newGeometryCollection as! Self

        case let feature as Feature:
            var newFeature = Feature(
                feature.geometry.rewinded,
                id: feature.id,
                properties: feature.properties,
                calculateBoundingBox: (feature.boundingBox != nil))
            newFeature.foreignMembers = feature.foreignMembers
            return newFeature as! Self

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(
                featureCollection.features.map({ $0.rewinded }),
                calculateBoundingBox: (featureCollection.boundingBox != nil))
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return newFeatureCollection as! Self

        default:
            return self
        }
    }

    /// Rewinds the receiver with the outer ring counterclockwise and inner rings clockwise.
    public mutating func rewind() {
        self = rewinded
    }

}
