#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension GeoJson {

    /// Flattens any *GeoJSON* to a *FeatureCollection*
    public var flattened: FeatureCollection? {
        switch self {
        case let point as Point:
            var featureCollection = FeatureCollection([point])
            featureCollection.boundingBox = point.boundingBox
            featureCollection.foreignMembers = point.foreignMembers
            return featureCollection

        case let multiPoint as MultiPoint:
            var featureCollection = FeatureCollection(multiPoint.points)
            featureCollection.boundingBox = multiPoint.boundingBox
            featureCollection.foreignMembers = multiPoint.foreignMembers
            return featureCollection

        case let lineString as LineString:
            var featureCollection = FeatureCollection([lineString])
            featureCollection.boundingBox = lineString.boundingBox
            featureCollection.foreignMembers = lineString.foreignMembers
            return featureCollection

        case let multiLineString as MultiLineString:
            var featureCollection = FeatureCollection(multiLineString.lineStrings)
            featureCollection.boundingBox = multiLineString.boundingBox
            featureCollection.foreignMembers = multiLineString.foreignMembers
            return featureCollection

        case let polygon as Polygon:
            var featureCollection = FeatureCollection([polygon])
            featureCollection.boundingBox = polygon.boundingBox
            featureCollection.foreignMembers = polygon.foreignMembers
            return featureCollection

        case let multiPolygon as MultiPolygon:
            var featureCollection = FeatureCollection(multiPolygon.polygons)
            featureCollection.boundingBox = multiPolygon.boundingBox
            featureCollection.foreignMembers = multiPolygon.foreignMembers
            return featureCollection

        case let geometryCollection as GeometryCollection:
            let features: [Feature] = geometryCollection.geometries.flatMap({ (geometry) -> [Feature] in
                if let multiLineString = geometry as? MultiLineString {
                    return multiLineString.lineStrings.map({ Feature($0) })
                }
                else if let multiPolygon = geometry as? MultiPolygon {
                    return multiPolygon.polygons.map({ Feature($0) })
                }
                else if let multiPoint = geometry as? MultiPoint {
                    return multiPoint.points.map({ Feature($0) })
                }
                else {
                    return [Feature(geometry)]
                }
            })
            var featureCollection = FeatureCollection(features)
            featureCollection.boundingBox = geometryCollection.boundingBox
            featureCollection.foreignMembers = geometryCollection.foreignMembers
            return featureCollection

        case let feature as Feature:
            var featureCollection: FeatureCollection
            if let multiLineString = feature.geometry as? MultiLineString {
                featureCollection = FeatureCollection(multiLineString.lineStrings.map({ Feature($0, id: feature.id, properties: feature.properties) }))
            }
            else if let multiPolygon = feature.geometry as? MultiPolygon {
                featureCollection = FeatureCollection(multiPolygon.polygons.map({ Feature($0, id: feature.id, properties: feature.properties) }))
            }
            else if let multiPoint = feature.geometry as? MultiPoint {
                featureCollection = FeatureCollection(multiPoint.points.map({ Feature($0, id: feature.id, properties: feature.properties) }))
            }
            else {
                featureCollection = FeatureCollection(feature)
            }
            featureCollection.boundingBox = feature.boundingBox
            featureCollection.foreignMembers = feature.foreignMembers
            return featureCollection

        case let featureCollection as FeatureCollection:
            let features: [Feature] = featureCollection.features.flatMap({ (feature) -> [Feature] in
                if let multiLineString = feature.geometry as? MultiLineString {
                    return multiLineString.lineStrings.map({ Feature($0, id: feature.id, properties: feature.properties) })
                }
                else if let multiPolygon = feature.geometry as? MultiPolygon {
                    return multiPolygon.polygons.map({ Feature($0, id: feature.id, properties: feature.properties) })
                }
                else if let multiPoint = feature.geometry as? MultiPoint {
                    return multiPoint.points.map({ Feature($0, id: feature.id, properties: feature.properties) })
                }
                else {
                    return [feature]
                }
            })
            var newFeatureCollection = FeatureCollection(features)
            newFeatureCollection.boundingBox = featureCollection.boundingBox
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return newFeatureCollection

        default:
            return nil
        }
    }

}
