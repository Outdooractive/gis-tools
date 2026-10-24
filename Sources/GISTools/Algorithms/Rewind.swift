#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// The winding order for polygons.
public enum PolygonWindingOrder: Sendable {

    /// Vertices are ordered in a clockwise direction.
    case clockwise
    /// Vertices are ordered in a counter-clockwise direction.
    case counterClockwise

}

extension GeoJson {

    /// Returns the receiver with the specified winding order.
    /// `Point` and `MultiPoint` will be returned as-is.
    ///
    /// - Parameter order: The winding order to apply.
    /// - Returns: A new geometry with the given winding order.
    public func withWindingOrder(_ order: PolygonWindingOrder) -> Self {
        switch self {
        case let lineString as LineString:
            guard let ring = Ring(lineString.coordinates) else { return self }

            if (order == .counterClockwise && ring.isCounterClockwise)
                || (order == .clockwise && ring.isClockwise)
            {
                return self
            }

            return GeometryDispatch.checkedCast(lineString.reversed, to: Self.self)

        case let multiLineString as MultiLineString:
            var newMultiLineString = MultiLineString(
                unchecked: multiLineString.lineStrings.map({ $0.withWindingOrder(order) }),
                calculateBoundingBox: multiLineString.boundingBox != nil)
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return GeometryDispatch.checkedCast(newMultiLineString, to: Self.self)

        case let polygon as Polygon:
            guard var outer = polygon.outerRing else { return self }

            if order == .counterClockwise {
                if outer.isClockwise {
                    outer.reverse()
                }
                let inner: [Ring] = polygon.innerRings?.map({ $0.isClockwise ? $0 : $0.reversed }) ?? []
                var newPolygon = Polygon(
                    unchecked: [outer] + inner,
                    calculateBoundingBox: polygon.boundingBox != nil)
                newPolygon.foreignMembers = polygon.foreignMembers
                return GeometryDispatch.checkedCast(newPolygon, to: Self.self)
            }
            else {
                if outer.isCounterClockwise {
                    outer.reverse()
                }
                let inner: [Ring] = polygon.innerRings?.map({ $0.isCounterClockwise ? $0 : $0.reversed }) ?? []
                var newPolygon = Polygon(
                    unchecked: [outer] + inner,
                    calculateBoundingBox: polygon.boundingBox != nil)
                newPolygon.foreignMembers = polygon.foreignMembers
                return GeometryDispatch.checkedCast(newPolygon, to: Self.self)
            }

        case let multiPolygon as MultiPolygon:
            var newMultiPolygon = MultiPolygon(
                unchecked: multiPolygon.polygons.map({ $0.withWindingOrder(order) }),
                calculateBoundingBox: multiPolygon.boundingBox != nil)
            newMultiPolygon.foreignMembers = multiPolygon.foreignMembers
            return GeometryDispatch.checkedCast(newMultiPolygon, to: Self.self)

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(
                geometryCollection.geometries.map({ $0.withWindingOrder(order) }),
                calculateBoundingBox: geometryCollection.boundingBox != nil)
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
                geometry.withWindingOrder(order),
                id: feature.id,
                properties: feature.properties,
                calculateBoundingBox: feature.boundingBox != nil)
            newFeature.foreignMembers = feature.foreignMembers
            return GeometryDispatch.checkedCast(newFeature, to: Self.self)

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(
                featureCollection.features.map({ $0.withWindingOrder(order) }),
                calculateBoundingBox: featureCollection.boundingBox != nil)
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return GeometryDispatch.checkedCast(newFeatureCollection, to: Self.self)

        default:
            return self
        }
    }

    /// Forces the receiver to be in the specified winding order.
    /// `Point` and `MultiPoint` will be returned as-is.
    ///
    /// - Parameter order: The winding order to enforce.
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
