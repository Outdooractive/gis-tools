#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// The winding order for polygons.
public enum PolygonWindingOrder: Sendable {
    case clockwise
    case counterClockwise
}

extension GeoJson {

    /// Returns the receiver with the specified winding order.
    /// `Point` and `MultiPoint` will be returned as-is.
    public func withWindingOrder(_ order: PolygonWindingOrder) -> Self {
        switch self {
        case let lineString as LineString:
            guard let ring = Ring(lineString.coordinates) else { return self }

            if (order == .counterClockwise && ring.isClockwise)
                || (order == .clockwise && ring.isCounterClockwise)
            {
                return self
            }

            return lineString.reversed as! Self

        case let multiLineString as MultiLineString:
            var newMultiLineString = MultiLineString(
                unchecked: multiLineString.lineStrings.map({ $0.withWindingOrder(order) }),
                calculateBoundingBox: (multiLineString.boundingBox != nil))
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return newMultiLineString as! Self

        case let polygon as Polygon:
            guard var outer = polygon.outerRing else { return self }

            if order == .counterClockwise {
                if outer.isClockwise { outer.reverse() }
                let inner: [Ring] = polygon.innerRings?.map({ $0.isClockwise ? $0 : $0.reversed }) ?? []
                var newPolygon = Polygon(
                    unchecked: [outer] + inner,
                    calculateBoundingBox: (polygon.boundingBox != nil))
                newPolygon.foreignMembers = polygon.foreignMembers
                return newPolygon as! Self
            }
            else {
                if outer.isCounterClockwise { outer.reverse() }
                let inner: [Ring] = polygon.innerRings?.map({ $0.isCounterClockwise ? $0 : $0.reversed }) ?? []
                var newPolygon = Polygon(
                    unchecked: [outer] + inner,
                    calculateBoundingBox: (polygon.boundingBox != nil))
                newPolygon.foreignMembers = polygon.foreignMembers
                return newPolygon as! Self
            }

        case let multiPolygon as MultiPolygon:
            var newMultiPolygon = MultiPolygon(
                unchecked: multiPolygon.polygons.map({ $0.withWindingOrder(order) }),
                calculateBoundingBox: (multiPolygon.boundingBox != nil))
            newMultiPolygon.foreignMembers = multiPolygon.foreignMembers
            return newMultiPolygon as! Self

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(
                geometryCollection.geometries.map({ $0.withWindingOrder(order) }),
                calculateBoundingBox: (geometryCollection.boundingBox != nil))
            newGeometryCollection.foreignMembers = geometryCollection.foreignMembers
            return newGeometryCollection as! Self

        case let feature as Feature:
            var newFeature = Feature(
                feature.geometry.withWindingOrder(order),
                id: feature.id,
                properties: feature.properties,
                calculateBoundingBox: (feature.boundingBox != nil))
            newFeature.foreignMembers = feature.foreignMembers
            return newFeature as! Self

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(
                featureCollection.features.map({ $0.withWindingOrder(order) }),
                calculateBoundingBox: (featureCollection.boundingBox != nil))
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return newFeatureCollection as! Self

        default:
            return self
        }
    }

    /// Forces the receiver to be in the specified winding order.
    /// `Point` and `MultiPoint` will be returned as-is.
    public mutating func forceWindingOrder(_ order: PolygonWindingOrder) {
        self = withWindingOrder(order)
    }

    /// Returns the receiver with the outer ring counterclockwise and inner rings clockwise.
    /// `Point` and `MultiPoint` will be returned as-is.
    public var rewinded: Self {
        withWindingOrder(.counterClockwise)
    }

    /// Rewinds the receiver with the outer ring counterclockwise and inner rings clockwise.
    public mutating func rewind() {
        self = rewinded
    }

}
