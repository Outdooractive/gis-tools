#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-truncate

extension Coordinate3D {

    /// Truncates the precision of the coordinate.
    ///
    /// - Parameter precision: The coordinate decimal precision (default `6`)
    /// - Parameter removeAltitude: Whether to remove the coordinate's altitude value (default `false`)
    /// - Parameter removeM: Whether to remove the coordinate's `m` value (default `false`)
    /// - Returns: The truncated coordinate.
    public func truncated(
        precision: Int = 6,
        removeAltitude: Bool = false,
        removeM: Bool = false
    ) -> Coordinate3D {
        Coordinate3D(
            x: longitude.rounded(precision: precision),
            y: latitude.rounded(precision: precision),
            z: (removeAltitude ? nil : altitude?.rounded(precision: precision)),
            m: (removeM ? nil : m),
            projection: projection)
    }

    /// Truncates the precision of the coordinate.
    ///
    /// - Parameter precision: The coordinate decimal precision (default `6`)
    /// - Parameter removeAltitude: Whether to remove the coordinate's altitude value (default `false`)
    /// - Parameter removeM: Whether to remove the coordinate's `m` value (default `false`)
    public mutating func truncate(
        precision: Int = 6,
        removeAltitude: Bool = false,
        removeM: Bool = false
    ) {
        self = truncated(
            precision: precision,
            removeAltitude: removeAltitude,
            removeM: removeM)
    }

}

extension GeoJson {

    /// Truncates the precision of the geometry.
    ///
    /// - Parameter precision: The coordinate decimal precision (default `6`)
    /// - Parameter removeAltitude: Whether to remove the coordinate's altitude value (default `false`)
    /// - Parameter removeM: Whether to remove the coordinate's `m` value (default `false`)
    /// - Returns: The truncated geometry.
    public func truncated(
        precision: Int = 6,
        removeAltitude: Bool = false,
        removeM: Bool = false
    ) -> Self {
        switch self {
        case let point as Point:
            var newPoint = Point(point.coordinate.truncated(precision: precision, removeAltitude: removeAltitude, removeM: removeM))
            if point.boundingBox != nil { newPoint.updateBoundingBox(onlyIfNecessary: false) }
            newPoint.foreignMembers = point.foreignMembers
            return newPoint as! Self

        case let multiPoint as MultiPoint:
            guard var newMultiPoint = MultiPoint(multiPoint.coordinates.map({
                $0.truncated(precision: precision, removeAltitude: removeAltitude, removeM: removeM)
            })) else { return self }
            if multiPoint.boundingBox != nil { newMultiPoint.updateBoundingBox(onlyIfNecessary: false) }
            newMultiPoint.foreignMembers = multiPoint.foreignMembers
            return newMultiPoint as! Self

        case let lineString as LineString:
            guard var newLineString = LineString(lineString.coordinates.map({
                $0.truncated(precision: precision, removeAltitude: removeAltitude, removeM: removeM)
            }))  else { return self }
            if lineString.boundingBox != nil { newLineString.updateBoundingBox(onlyIfNecessary: false) }
            newLineString.foreignMembers = lineString.foreignMembers
            return newLineString as! Self

        case let multiLineString as MultiLineString:
            guard var newMultiLineString = MultiLineString(multiLineString.coordinates.map({
                $0.map({
                    $0.truncated(precision: precision, removeAltitude: removeAltitude, removeM: removeM)
                })
            }))  else { return self }
            if multiLineString.boundingBox != nil { newMultiLineString.updateBoundingBox(onlyIfNecessary: false) }
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return newMultiLineString as! Self

        case let polygon as Polygon:
            guard var newPolygon = Polygon(polygon.coordinates.map({
                $0.map({
                    $0.truncated(precision: precision, removeAltitude: removeAltitude, removeM: removeM)
                })
            })) else { return self }
            if polygon.boundingBox != nil { newPolygon.updateBoundingBox(onlyIfNecessary: false) }
            newPolygon.foreignMembers = polygon.foreignMembers
            return newPolygon as! Self

        case let multiPolygon as MultiPolygon:
            guard var newMultiPolygon = MultiPolygon(multiPolygon.coordinates.map({
                $0.map({
                    $0.map({
                        $0.truncated(precision: precision, removeAltitude: removeAltitude, removeM: removeM)
                    })
                })
            })) else { return self }
            if multiPolygon.boundingBox != nil { newMultiPolygon.updateBoundingBox(onlyIfNecessary: false) }
            newMultiPolygon.foreignMembers = multiPolygon.foreignMembers
            return newMultiPolygon as! Self

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(geometryCollection.geometries.map({
                $0.truncated(precision: precision, removeAltitude: removeAltitude, removeM: removeM)
            }))
            if geometryCollection.boundingBox != nil { newGeometryCollection.updateBoundingBox(onlyIfNecessary: false) }
            newGeometryCollection.foreignMembers = geometryCollection.foreignMembers
            return newGeometryCollection as! Self

        case let feature as Feature:
            guard let geometry = feature.geometry else {
                var newFeature = Feature(
                    id: feature.id,
                    properties: feature.properties,
                    foreignMembers: feature.foreignMembers)
                if feature.boundingBox != nil { newFeature.updateBoundingBox(onlyIfNecessary: false) }
                return newFeature as! Self
            }

            var newFeature = Feature(
                geometry.truncated(precision: precision, removeAltitude: removeAltitude, removeM: removeM),
                id: feature.id,
                properties: feature.properties)
            if feature.boundingBox != nil { newFeature.updateBoundingBox(onlyIfNecessary: false) }
            newFeature.foreignMembers = feature.foreignMembers
            return newFeature as! Self

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(featureCollection.features.map({
                $0.truncated(precision: precision, removeAltitude: removeAltitude, removeM: removeM)
            }))
            if featureCollection.boundingBox != nil { newFeatureCollection.updateBoundingBox(onlyIfNecessary: false) }
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return newFeatureCollection as! Self

        default:
            return self
        }
    }

    /// Truncates the precision of the geometry.
    ///
    /// - Parameter precision: The coordinate decimal precision (default `6`)
    /// - Parameter removeAltitude: Whether to remove the coordinate's altitude value (default `false`)
    /// - Parameter removeM: Whether to remove the coordinate's `m` value (default `false`)
    public mutating func truncate(
        precision: Int = 6,
        removeAltitude: Bool = false,
        removeM: Bool = false
    ) {
        self = truncated(
            precision: precision,
            removeAltitude: removeAltitude,
            removeM: removeM)
    }

}
